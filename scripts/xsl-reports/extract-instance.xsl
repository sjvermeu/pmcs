<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.1" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:oval="http://oval.mitre.org/XMLSchema/oval-common-5"
  xmlns:oval-res="http://oval.mitre.org/XMLSchema/oval-results-5"
  xmlns:oval-sc="http://oval.mitre.org/XMLSchema/oval-system-characteristics-5"
  xmlns:oval-def="http://oval.mitre.org/XMLSchema/oval-definitions-5"
  xmlns:apache-def="http://oval.mitre.org/XMLSchema/oval-definitions-5#apache"
  xmlns:ind-def="http://oval.mitre.org/XMLSchema/oval-definitions-5#independent"
  xmlns:windows-def="http://oval.mitre.org/XMLSchema/oval-definitions-5#windows"
  xmlns:unix-def="http://oval.mitre.org/XMLSchema/oval-definitions-5#unix"
  xmlns:linux-def="http://oval.mitre.org/XMLSchema/oval-definitions-5#linux"
  xmlns:str="http://exslt.org/strings"
  exclude-result-prefixes="oval oval-def oval-res oval-sc ind-def windows-def unix-def linux-def apache-def">
  <xsl:output method="text" /> 
  <xsl:strip-space elements="*" />

<xsl:param name="instanceid" />

<xsl:template match="oval-res:oval_results">
<xsl:for-each select="oval-res:results/oval-res:system/oval-sc:oval_system_characteristics/oval-sc:system_data/*[@id=$instanceid]">
<xsl:apply-templates />
</xsl:for-each>
</xsl:template>

<xsl:template match="*">
<xsl:value-of select="local-name()" />="<xsl:value-of select="." />"<xsl:text>
</xsl:text>
</xsl:template>

</xsl:stylesheet>
