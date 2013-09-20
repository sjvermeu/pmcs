#!/bin/sh

# Variable declarations
PORT=""
FQDN=""
DOMAIN=""
CLASS=""
REPO=""
PLATFORM=""
KEYWORDS=""
RESULTREPO=""
SCAPSCANOVAL=""
SCAPSCANXCCDF=""

CDIR=$(pwd);

TMPDIR=$(mktemp -d --suffix='pmcsa');

# Functions
die() {
  RC=$1; shift;
  echo "!! $*";
  exit ${RC};
}

setConfigurationVariables() {
  echo "Fetching configuration from central configuration repository.";

  REPO_URLS="
    ${REPO}/config/domains/${DOMAIN}.conf
    ${REPO}/config/classes/${CLASS}.conf
    ${REPO}/config/domains/${DOMAIN}/classes/${CLASS}.conf
    ${REPO}/config/hosts/${FQDN}.conf
  "

  for REPO_URL in ${REPO_URLS};
  do
    wget -q -O ${TMPDIR}/config ${REPO_URL};
    if [ $? -eq 0 ];
    then
      grep -q ^platform= ${TMPDIR}/config && PLATFORM=$(grep ^platform= ${TMPDIR}/config | cut -f 2 -d '=');
      grep -q ^resultrepo= ${TMPDIR}/config && RESULTREPO=$(grep ^resultrepo= ${TMPDIR}/config | cut -f 2 -d '=');
      grep -q ^scapscanneroval= ${TMPDIR}/config && SCAPSCANOVAL=$(grep ^scapscanneroval= ${TMPDIR}/config | cut -f 2 -d '=');
      grep -q ^scapscannerxccdf= ${TMPDIR}/config && SCAPSCANXCCDF=$(grep ^scapscannerxccdf= ${TMPDIR}/config | cut -f 2 -d '=');
      grep -q ^keywords= ${TMPDIR}/config && KEYWORDS="${KEYWORDS},$(grep ^keywords= ${TMPDIR}/config | cut -f 2 -d '=')";
      rm ${TMPDIR}/config;
    fi
  done

  echo "PLATFORM      = ${PLATFORM}";
  echo "RESULTREPO    = ${RESULTREPO}";
  echo "KEYWORDS      = ${KEYWORDS}";
  echo "SCAPSCANOVAL  = ${SCAPSCANOVAL}";
  echo "SCAPSCANXCCDF = ${SCANSCANXCCDF}";
  echo "";
}

getStreamList() {
  echo "Getting list of SCAP data streams to evaluate";

  REPO_URLS="
    ${REPO}/stream/hosts/${FQDN}/list.conf
    ${REPO}/stream/domains/${DOMAIN}/classes/${CLASS}/platforms/${PLATFORM}/list.conf
    ${REPO}/stream/domains/${DOMAIN}/classes/${CLASS}/list.conf
    ${REPO}/stream/classes/${CLASS}/platforms/${PLATFORM}/list.conf
    ${REPO}/stream/classes/${CLASS}/list.conf
    ${REPO}/stream/domains/${DOMAIN}/list.conf
  "

  for REPO_URL in ${REPO_URLS};
  do
    wget -q -O ${TMPDIR}/sublist ${REPO_URL};
    if [ $? -eq 0 ];
    then
      cat ${TMPDIR}/sublist >> ${TMPDIR}/list;
    fi
  done

  for KEYWORD in $(echo ${KEYWORDS} | sed -e 's:,: :g');
  do
    wget -q -O ${TMPDIR}/sublist ${REPO}/stream/keywords/${KEYWORD}/list.conf;
    if [ $? -eq 0 ];
    then
      cat ${TMPDIR}/sublist >> ${TMPDIR}/list;
    fi
  done

  touch ${TMPDIR}/list;
  sort ${TMPDIR}/list | uniq > ${TMPDIR}/orderedlist;
  mv ${TMPDIR}/orderedlist ${TMPDIR}/list;
   
  echo "";
}

sendResults() {
  FILE=$1;
  REPOTYPE=$(echo ${RESULTREPO} | cut -f 1 -d ':' -s);
  POSTRES=$(echo ${RESULTREPO} | sed -e "s:@@TARGETNAME@@:${FQDN}:g" -e "s:@@FILENAME@@:${FILE}:g");

  echo "Sending ${FILE} to ${POSTRES}.";

  if [ "${REPOTYPE}" = "file" ];
  then
    cp ${FILE} ${POSTRES##file://};
  elif [ "${REPOTYPE}" = "http" ] || [ "{REPOTYPE}" = "https" ];
  then
    wget --post-file=${FILE} "${POSTRES}";
  fi
};

daemonize() {
  echo "Daemonizing pmcsa on port ${PORT}";
  echo "";

  while true;
  do
    echo "OK" | nc -l -v -p ${PORT} -q 1 >> ${TMPDIR}/connection.log;
  done
};

evaluateStreams() {
  for STREAM in $(cat ${TMPDIR}/list);
  do
    STREAMTYPE=$(echo ${STREAM} | cut -f 1 -d '#' -s);
    STREAMPATH=$(echo ${STREAM} | cut -f 2 -d '#' -s);
    STREAMID=$(echo ${STREAM} | cut -f 3 -d '#' -s);
    echo "-- Evaluating STREAM ${STREAMPATH} (type ${STREAMTYPE}, id ${STREAMID})";
    echo "";
    STREAMNAME=$(basename ${STREAMPATH});
    wget -q -O ${TMPDIR}/${STREAMNAME} ${REPO}/stream/${STREAMPATH};
    if [ $? -eq 0 ];
    then
      if [ "${STREAMTYPE}" = "xccdf" ];
      then
        CMD=$(echo "${SCAPSCANXCCDF}" | sed -e "s:@@STREAMNAME@@:${STREAMNAME}:g" -e "s:@@RESULTNAME@@:${STREAMNAME%%.xml}-results.xml:g" -e "s:@@STREAMID@@:${STREAMID}:g");
	echo "Running ${CMD}";
	cd ${TMPDIR};
	${CMD};
	sendResults ${STREAMNAME%%.xml}-results.xml;
      elif [ "${STREAMTYPE}" = "oval" ];
      then
        CMD=$(echo "${SCAPSCANOVAL}" | sed -e "s:@@STREAMNAME@@:${STREAMNAME}:g" -e "s:@@RESULTNAME@@:${STREAMNAME%%.xml}-results.xml:g" -e "s:@@STREAMID@@:${STREAMID}:g");
	echo "Running ${CMD}";
	cd ${TMPDIR};
	${CMD};
	sendResults ${STREAMNAME%%.xml}-results.xml;
      else
        echo "!! Type ${STREAMTYPE} is not known.";
      fi;
    else
      echo "!! Stream ${REPO}/stream/${STREAM} could not be found";
    fi
    echo "";
  done
}

##
## Main 
##
if [ "$1" = "-d" ];
then
  [ $2 -gt 1 ] || die 2 "Parameter $2 is not a valid port number";
  PORT="${2}";
  REPO="${3}";
else
  REPO="${1}";
fi


# We are a shell script, so 'unix' seems obvious (for now)
CLASS="unix"
DOMAIN="$(dnsdomainname)"
[ -z "${DOMAIN}" ] && DOMAIN="localdomain"
FQDN="$(hostname).${DOMAIN}"

echo "Poor Man Central SCAP Agent v0.1";
echo "";

echo "Detected local variables from system.";
echo "REPO   = ${REPO}";
echo "FQDN   = ${FQDN}";
echo "DOMAIN = ${DOMAIN}";
echo "CLASS  = ${CLASS}";
echo "PORT   = ${PORT}";
echo "";

setConfigurationVariables;

if [ -n "${PORT}" ];
then
  daemonize;
else
  getStreamList;
  evaluateStreams;
fi

cd ${CDIR};
rm -rf ${TMPDIR};
