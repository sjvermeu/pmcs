#!/bin/sh

##
## Output start of xccdf to stdout
##

ID="xccdf_localhost_benchmark_$(date +%Y%m%d-%H%M%S)"

cat << EOF | sed -e "s:@@ID@@:${ID}:g"
<?xml version="1.0" encoding="UTF-8"?>
<Benchmark xmlns="http://checklists.nist.gov/xccdf/1.2"
  xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" 
  id="@@ID@@"
  xsi:schemaLocation="http://checklists.nist.gov/xccdf/1.2 xccdf-1.2.xsd"
  resolved="0">
  <status>draft</status>
  <title>oval2xccdf benchmark @@ID@@</title>
  <description></description>
  <version>1</version>
  <model system="urn:xccdf:scoring:default" />
  <model system="urn:xccdf:scoring:flat" />
  <model system="urn:xccdf:scoring:flat-unweighted" />
  <Group id="xccdf_localhost_group_1">
    <title>OVAL tests</title>
    <description></description>
EOF

##
## Create rules for each definition in each file
##

for FILE in $*;
do
  IDS=$(xmllint --xpath "//*[local-name()='definition']/@id" ${FILE} | sed -e 's:id="::g' -e 's:"::g');
  for OVALID in ${IDS};
  do
    RULEID=$(echo ${OVALID} | cut -f 4 -d ':');
    RULETITLE=$(xmllint --xpath "//*[local-name()='definition'][@id='${OVALID}']//*[local-name()='title']/text()" ${FILE});
    cat << EOF | sed -e "s|@@OVALID@@|${OVALID}|g" -e "s:@@FILE@@:${FILE}:g" -e "s:@@RULEID@@:${RULEID}:g" -e "s|@@RULETITLE@@|${RULETITLE}|g"
    <Rule id="xccdf_localhost_rule_@@RULEID@@" selected="true">
      <title>@@RULETITLE@@</title>
      <check system="http://oval.mitre.org/XMLSchema/oval-definitions-5">
        <check-content-ref name="@@OVALID@@" href="@@FILE@@" />
      </check>
    </Rule>
EOF
  done
done

cat << EOF
  </Group>
</Benchmark>
EOF
