<?xml version="1.0" encoding="utf-8"?>

<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

	<xsl:template match="css">
		<xsl:copy>
			<xsl:copy-of select="@*"/>
			<xsl:call-template name="css2xml">
				<xsl:with-param name="text" select="."/>
			</xsl:call-template>
		</xsl:copy>
	</xsl:template>

	<xsl:template name="css2xml">
		<xsl:param name="text"/>
		<xsl:value-of select="$text"/>
	</xsl:template>
	
</xsl:stylesheet>