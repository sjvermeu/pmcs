#!/bin/sh

if [ $# -ne 1 ];
then
  echo "Usage: $0 <basedir>";
  exit 1;
fi

if [ ! -d $1 ];
then
  echo "Usage: $0 <basedir>";
  echo "";
  echo "Directory $1 does not exist.";
  exit 2;
fi

DIR="$1"
REGFILE=$(mktemp --suffix=snippets2oval);

setRegister() {
  cat ${REGFILE} | grep -v "${1}$" > ${REGFILE}.t;
  echo "$1" >> ${REGFILE}.t;
  mv ${REGFILE}.t ${REGFILE};
}

traverse() {
  local TYPE=$1;
  local SUBID=$2;

  # Traverse objects
  OBJECTS=$(grep object_ref= ${DIR}/${TYPE}/${SUBID}_*.xmlsnippet | sed -e 's:.* object_ref="\([^"]*\)".*:\1:g');
  for OBJECT in ${OBJECTS};
  do
    setRegister "object=${OBJECT}";
    OBJECTID=$(echo ${OBJECT} | cut -f 4 -d ':');
    traverse objects ${OBJECTID};
  done

  # Traverse states
  STATES=$(grep state_ref= ${DIR}/${TYPE}/${SUBID}_*.xmlsnippet | sed -e 's:.* state_ref="\([^"]*\)".*:\1:g');
  for STATE in ${STATES};
  do
    setRegister "state=${STATE}";
    STATEID=$(echo ${STATE} | cut -f 4 -d ':');
    traverse states ${STATEID};
  done

  # Traverse variables
  VARIABLES=$(grep var_ref= ${DIR}/${TYPE}/${SUBID}_*.xmlsnippet | sed -e 's:.* var_ref="\([^"]*\)".*:\1:g');
  for VARIABLE in ${VARIABLES};
  do
    setRegister "var=${VARIABLE}";
    VARIABLEID=$(echo ${VARIABLE} | cut -f 4 -d ':');
    traverse variables ${VARIABLEID};
  done
}

for DEFFILE in ${DIR}/definitions/*.xmlsnippet;
do
  OVALFILE=$(basename ${DEFFILE%%snippet});
  echo "# Creating ${DIR}/oval/${OVALFILE}";
  cat ${DIR}/data/oval_pre > ${DIR}/oval/${OVALFILE};
  echo "  <generator>" >> ${DIR}/oval/${OVALFILE};
  echo "    <oval:product_name>pmcs-snippets2xml</oval:product_name>" >> ${DIR}/oval/${OVALFILE};
  echo "    <oval:product_version>1.0</oval:product_version>" >> ${DIR}/oval/${OVALFILE};
  echo "    <oval:schema_version>5.10</oval:schema_version>" >> ${DIR}/oval/${OVALFILE};
  echo "    <oval:timestamp>$(date +%Y-%m-%dT%H:%M:%S)</oval:timestamp>" >> ${DIR}/oval/${OVALFILE};
  echo "  </generator>" >> ${DIR}/oval/${OVALFILE};
  echo "<definitions>" >> ${DIR}/oval/${OVALFILE};
  cat ${DEFFILE} >> ${DIR}/oval/${OVALFILE};
  echo "</definitions>" >> ${DIR}/oval/${OVALFILE};
  #
  # Now look for all tests and "register" them in the REGFILE
  #
  TESTS=$(grep test_ref ${DEFFILE} | sed -e 's:.*test_ref="\([^"]*\)".*:\1:g');
  for TEST in ${TESTS};
  do
    setRegister "test=${TEST}";
  done
  #
  # Now recurse over the references
  #
  for TEST in ${TESTS};
  do
    TESTID=$(echo ${TEST} | cut -f 4 -d ':');
    traverse tests ${TESTID};
  done
  #
  # Done, now build the remainder of the XML file
  #
  echo "<tests>" >> ${DIR}/oval/${OVALFILE};
  for TEST in $(cat ${REGFILE} | grep ^test= | cut -f 2 -d '=');
  do
    TESTID=$(echo ${TEST} | cut -f 4 -d ':');
    cat ${DIR}/tests/${TESTID}_*.xmlsnippet >> ${DIR}/oval/${OVALFILE};
  done
  echo "</tests>" >> ${DIR}/oval/${OVALFILE};

  echo "<objects>" >> ${DIR}/oval/${OVALFILE};
  for OBJ in $(cat ${REGFILE} | grep ^object= | cut -f 2 -d '=');
  do
    OBJID=$(echo ${OBJ} | cut -f 4 -d ':');
    cat ${DIR}/objects/${OBJID}_*.xmlsnippet >> ${DIR}/oval/${OVALFILE};
  done
  echo "</objects>" >> ${DIR}/oval/${OVALFILE};

  grep -q "state=" ${REGFILE};
  if [ $? -eq 0 ];
  then
    echo "<states>" >> ${DIR}/oval/${OVALFILE};
    for STATE in $(cat ${REGFILE} | grep ^state= | cut -f 2 -d '=');
    do
      STATEID=$(echo ${STATE} | cut -f 4 -d ':');
      cat ${DIR}/states/${STATEID}_*.xmlsnippet >> ${DIR}/oval/${OVALFILE};
    done
    echo "</states>" >> ${DIR}/oval/${OVALFILE};
  fi

  grep -q "var=" ${REGFILE};
  if [ $? -eq 0 ];
  then
    echo "<variables>" >> ${DIR}/oval/${OVALFILE};
    for VARIABLE in $(cat ${REGFILE} | grep ^var= | cut -f 2 -d '=');
    do
      VARIABLEID=$(echo ${VARIABLE} | cut -f 4 -d ':');
      cat ${DIR}/variables/${VARIABLEID}_*.xmlsnippet >> ${DIR}/oval/${OVALFILE};
    done
    echo "</variables>" >> ${DIR}/oval/${OVALFILE};
  fi

  cat ${DIR}/data/oval_post >> ${DIR}/oval/${OVALFILE};
done

rm ${REGFILE};
