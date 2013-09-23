#!/bin/sh

if [ $# -ne 3 ];
then
  echo "Usage: $0 <xsldir> <resultdir> <reportdir>";
  echo "";
  exit 1;
fi

XSLDIR="$1";
RESULTDIR="$2";
REPORTDIR="$3";

TMPDIR=$(mktemp -d);
touch ${TMPDIR}/.istmp;

# Look at current working directory for OVAL or XCCDF result files
parseDir() {
  CHECKDIR="${1}";
  SUBDIR=$(echo ${CHECKDIR} | sed -e "s:${RESULTDIR}::g");
  mkdir -p ${REPORTDIR}/${SUBDIR};
  touch ${REPORTDIR}/${SUBDIR}/server-definitions.csv;
  touch ${REPORTDIR}/${SUBDIR}/server-tests.csv;
  touch ${REPORTDIR}/${SUBDIR}/server-test-instances.csv;

  for FILE in $(grep '<oval_results ' ${CHECKDIR}/* 2>/dev/null | cut -f 1 -d ':' | sort | uniq);
  do
    FILENAME=$(basename ${FILE});
    handleOVALFile ${CHECKDIR} ${SUBDIR} ${FILENAME};
  done
  for FILE in $(grep '<TestResult ' ${CHECKDIR}/* 2>/dev/null | cut -f 1 -d ':' | sort | uniq);
  do
    FILENAME=$(basename ${FILE});
    handleXCCDFFile ${CHECKDIR} ${SUBDIR} ${FILENAME};
  done
}

reportInDir() {
  CHECKDIR="${1}";
  SUBDIR=$(echo ${CHECKDIR} | sed -e "s:${REPORTDIR}::g");
  if [ -f ${CHECKDIR}/server-definitions.csv ];
  then
    buildServerReport ${CHECKDIR} ${SUBDIR};
  fi
};

# Build report for one host, list definitions, tests and state
buildServerReport() {
  CHECKDIR="${1}";
  SUBDIR="${2}";
  echo "<html>" > ${CHECKDIR}/index.html;
  echo "<head><title>Host report ${SUBDIR}</title><link rel=\"stylesheet\" href=\"../../style.css\" type=\"text/css\" /></head>" >> ${CHECKDIR}/index.html;
  echo "<body>" >> ${CHECKDIR}/index.html;
  echo "<h2>Definitions for ${SUBDIR}</h2>" >> ${CHECKDIR}/index.html;
  echo "<table>" >> ${CHECKDIR}/index.html;
  echo "<tr><th>Definition</th><th>Result</th><th>Affiliated test</th><th>Test result</th><th>Test data</th></tr>" >> ${CHECKDIR}/index.html;
  for DEF in $(cat ${CHECKDIR}/server-definitions.csv | awk -F',' '{print $1}');
  do
    DEFRESULT=$(grep "^${DEF}," ${CHECKDIR}/server-definitions.csv | awk -F',' '{print $2}');
    DEFINFO=$(grep "^${DEF}," ${REPORTDIR}/definitions.csv | cut -f 3- -d ',');
    ESCDEF=$(echo ${DEF} | sed -e 's|:|_|g');
    TESTCNT=$(wc -l  ${REPORTDIR}/definitions/${ESCDEF}_dependencies.csv | awk '{print $1}');
    echo "<tr><td rowspan=\"$((${TESTCNT}+1))\">" >> ${CHECKDIR}/index.html;
    echo "<b><a href=\"../../definitions/${ESCDEF}.txt\">${DEF}</a></b><br />${DEFINFO}" >> ${CHECKDIR}/index.html;
    echo "</td><td rowspan=\"$((${TESTCNT}+1))\">${DEFRESULT}</td><td /><td /><td /></tr>" >> ${CHECKDIR}/index.html;
    for TEST in $(cat ${REPORTDIR}/definitions/${ESCDEF}_dependencies.csv | awk -F',' '{print $1}');
    do
      TESTRESULT=$(grep "^${TEST}," ${CHECKDIR}/server-tests.csv | awk -F',' '{print $2}');
      TESTINFO=$(grep "^${TEST}," ${REPORTDIR}/tests.csv | cut -f 2- -d ',');
      ESCTEST=$(echo ${TEST} | sed -e 's|:|_|g');
      INSTANCES="";
      for INSTANCE_RESULT in $(grep "^${TEST}," ${CHECKDIR}/server-test-instances.csv | awk -F',' '{print $2"-"$3}' | sed -e 's| |_|g');
      do
        INSTANCE=${INSTANCE_RESULT%%-*};
	IRESULT=${INSTANCE_RESULT##*-};
	INSTANCES="${INSTANCES}<a href=\"instance-${INSTANCE}.txt\">${INSTANCE} [${IRESULT}]</a><br />";
      done
      echo "<tr>" >> ${CHECKDIR}/index.html;
      echo "<td><a href=\"../../tests/${ESCTEST}.txt\">${TEST}</a><br />${TESTINFO}</td>" >> ${CHECKDIR}/index.html;
      echo "<td>${TESTRESULT}</td><td>${INSTANCES}</td>" >> ${CHECKDIR}/index.html;
      echo "</tr>" >> ${CHECKDIR}/index.html;
    done
  done
  echo "</table>" >> ${CHECKDIR}/index.html;
  echo "</body>" >> ${CHECKDIR}/index.html;
  echo "</html>" >> ${CHECKDIR}/index.html;
}

handleOVALFile() {
  CHECKDIR="${1}";
  SUBDIR="${2}";
  FILE="${3}";

  echo "- Handling OVAL file ${FILE} in ${CHECKDIR}";

  #
  # Extracting definitions
  xsltproc ${XSLDIR}/extract-definitions.xsl ${CHECKDIR}/${FILE} > ${TMPDIR}/definitions.csv
  mergeCSV ${TMPDIR}/definitions.csv ${REPORTDIR}/definitions.csv;

  #
  # Store definition text representations
  echo "  - Extracting definition information";
  for DEF in $(awk -F',' '{print $1}' ${TMPDIR}/definitions.csv);
  do
    ESCDEF=$(echo ${DEF} | sed -e 's|:|_|g');
    if [ ! -f ${REPORTDIR}/definitions/${ESCDEF}.txt ];
    then
      xsltproc --stringparam defid ${DEF} ${XSLDIR}/extract-definitions-full.xsl ${CHECKDIR}/${FILE} | xmllint --format - > ${REPORTDIR}/definitions/${ESCDEF}.txt;
      # Track tests related to the definition
      for TESTREF in $(grep "test_ref=" ${REPORTDIR}/definitions/${ESCDEF}.txt | sed -e 's:.*test_ref="\([^"]*\)".*:\1:g');
      do
        echo "${TESTREF}" >> ${REPORTDIR}/definitions/${ESCDEF}_dependencies.csv;
      done
    fi
  done
  rm ${TMPDIR}/definitions.csv;

  #
  # Extracting tests
  echo "  - Extracting test information";
  xsltproc ${XSLDIR}/extract-tests.xsl ${CHECKDIR}/${FILE} > ${TMPDIR}/tests.csv
  mergeCSV ${TMPDIR}/tests.csv ${REPORTDIR}/tests.csv;
  
  #
  # Store test definition representations
  for TEST in $(awk -F',' '{print $1}' ${TMPDIR}/tests.csv);
  do
    ESCTEST=$(echo ${TEST} | sed -e 's|:|_|g');
    if [ ! -f ${REPORTDIR}/tests/${ESCTEST}.txt ];
    then
      xsltproc --stringparam testid ${TEST} ${XSLDIR}/extract-tests-full.xsl ${CHECKDIR}/${FILE} | xmllint --format - > ${REPORTDIR}/tests/${ESCTEST}.txt;
    fi
  done
  rm ${TMPDIR}/tests.csv;

  #
  # Register definition results
  echo "  - Extracting definition results";
  xsltproc ${XSLDIR}/extract-server-def-results.xsl ${CHECKDIR}/${FILE} > ${TMPDIR}/definitions.csv;
  mergeCSV ${TMPDIR}/definitions.csv ${REPORTDIR}/${SUBDIR}/server-definitions.csv;
  rm ${TMPDIR}/definitions.csv;

  #
  # Register test results
  echo "  - Extracting test results (including instance info - this can take a while)";
  xsltproc ${XSLDIR}/extract-server-test-results.xsl ${CHECKDIR}/${FILE} > ${TMPDIR}/tests.csv;
  mergeCSV ${TMPDIR}/tests.csv ${REPORTDIR}/${SUBDIR}/server-tests.csv;

  #
  # Track instance definitions
  for TEST in $(awk -F',' '{print $1}' ${TMPDIR}/tests.csv);
  do
    ESCTEST=$(echo ${TEST} | sed -e 's|:|_|g');
    xsltproc --stringparam testid ${TEST} ${XSLDIR}/extract-test-instances.xsl ${CHECKDIR}/${FILE} > ${TMPDIR}/instances.csv;
    mergeCSV ${TMPDIR}/instances.csv ${REPORTDIR}/${SUBDIR}/server-test-instances.csv;
    for INSTANCE in $(awk -F',' '{print $2}' ${TMPDIR}/instances.csv);
    do
      xsltproc --stringparam instanceid ${INSTANCE} ${XSLDIR}/extract-instance.xsl ${CHECKDIR}/${FILE} > ${REPORTDIR}/${SUBDIR}/instance-${INSTANCE}.txt
    done
  done
  rm ${TMPDIR}/tests.csv;
  rm ${TMPDIR}/instances.csv;

}

handleXCCDFFile() {
  CHECKDIR="${1}";
  SUBDIR="${2}";
  FILE="${3}";

  echo "- Handling XCCDF file ${FILE} in ${CHECKDIR}";
  echo "TODO";
}

# Merge two files, 2nd file is target
mergeCSV() {
  FIRST="${1}";
  SECOND="${2}";

  cat ${FIRST} ${SECOND} | sort | uniq > ${SECOND}.2;
  mv ${SECOND}.2 ${SECOND}
}

mkdir -p ${REPORTDIR}/definitions ${REPORTDIR}/tests;
test -f ${REPORTDIR}/definitions.csv || touch ${REPORTDIR}/definitions.csv;
test -f ${REPORTDIR}/tests.csv || touch ${REPORTDIR}/tests.csv;
cp ${XSLDIR}/style.css ${REPORTDIR}/style.css;

DIRS=$(find ${RESULTDIR} -type d);
for DIR in ${DIRS};
do
  echo "Handling ${DIR}";
  parseDir ${DIR};
done

DIRS=$(find ${REPORTDIR} -type d);
for DIR in ${DIRS};
do
  echo "Creating reports in ${DIR}";
  reportInDir ${DIR};
done

test -d ${TMPDIR} && test -f ${TMPDIR}/.istmp && rm -rf ${TMPDIR};
