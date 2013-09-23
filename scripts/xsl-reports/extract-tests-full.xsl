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
  <xsl:output method="xml" indent="no" />

<xsl:param name="testid" />

<xsl:template match="oval-res:oval_results">
<xsl:for-each select="oval-def:oval_definitions/oval-def:tests/*[@id=$testid]">
<definition>
<xsl:apply-templates select="@*" />
<xsl:apply-templates />
</definition>
</xsl:for-each>
</xsl:template>

<xsl:template match="@* | node()">
<xsl:copy>
  <xsl:apply-templates select="@* | node()" />
</xsl:copy>
</xsl:template>

</xsl:stylesheet>
