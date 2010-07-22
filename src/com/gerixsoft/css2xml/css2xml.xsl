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
		<xsl:variable name="config" select="document('css2xml.xml')/node()"/>
		<xsl:variable name="mode0">
			<xsl:variable name="regexps"
				select="'/\*(.*?)\*/', '(''|&quot;)(.*?)\2', '(#[0-9a-fA-F]+)', '((-?\d+)(\.\d+)?(px|em|pt|%))', '([\w_\-]+)', '([\.,;:#\*!@/\{\}\(\)])'"/>
			<xsl:analyze-string select="$text" regex="{string-join($regexps,'|')}" flags="si">
				<xsl:matching-substring>
					<xsl:choose>
						<!-- multi line comment -->
						<xsl:when test="regex-group(1)">
							<xsl:comment>
								<xsl:value-of select="regex-group(1)"/>
							</xsl:comment>
						</xsl:when>
						<!-- string -->
						<xsl:when test="regex-group(2)">
							<string>
								<xsl:value-of select="regex-group(3)"/>
							</string>
						</xsl:when>
						<!-- color -->
						<xsl:when test="regex-group(4)">
							<color>
								<xsl:value-of select="regex-group(4)"/>
							</color>
						</xsl:when>
						<!-- size -->
						<xsl:when test="regex-group(5)">
							<size>
								<xsl:value-of select="regex-group(5)"/>
							</size>
						</xsl:when>
						<!-- alpha numeric -->
						<xsl:when test="regex-group(9)">
							<xsl:analyze-string select="regex-group(9)"
								regex="^({string-join($config/keyword, '|')})$|^({string-join($config/value, '|')})$|^({string-join($config/font, '|')})$|^((-?\d+)(\.\d+)?)$"
								flags="si">
								<xsl:matching-substring>
									<xsl:choose>
										<!-- keyword -->
										<xsl:when test="regex-group(1)">
											<keyword>
												<xsl:value-of select="regex-group(1)"/>
											</keyword>
										</xsl:when>
										<!-- value -->
										<xsl:when test="regex-group(2)">
											<value>
												<xsl:value-of select="regex-group(2)"/>
											</value>
										</xsl:when>
										<!-- font -->
										<xsl:when test="regex-group(3)">
											<font>
												<xsl:value-of select="regex-group(3)"/>
											</font>
										</xsl:when>
										<!-- size -->
										<xsl:when test="regex-group(4)">
											<size>
												<xsl:value-of select="regex-group(4)"/>
											</size>
										</xsl:when>
										<xsl:otherwise>
											<xsl:message terminate="yes" select="'internal error'"/>
										</xsl:otherwise>
									</xsl:choose>
								</xsl:matching-substring>
								<xsl:non-matching-substring>
									<name>
										<xsl:value-of select="."/>
									</name>
								</xsl:non-matching-substring>
							</xsl:analyze-string>
						</xsl:when>
						<!-- symbol -->
						<xsl:when test="regex-group(10)">
							<symbol>
								<xsl:value-of select="regex-group(10)"/>
							</symbol>
						</xsl:when>
						<xsl:otherwise>
							<xsl:message terminate="yes" select="'internal error'"/>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:matching-substring>
				<xsl:non-matching-substring>
					<xsl:if test="normalize-space()!=''">
						<xsl:message select="concat('unknown token: ', .)"/>
						<xsl:value-of select="."/>
					</xsl:if>
				</xsl:non-matching-substring>
			</xsl:analyze-string>
		</xsl:variable>
		<xsl:variable name="mode1">
			<xsl:for-each-group select="$mode0/node()" group-starting-with="symbol[.='{']">
				<xsl:choose>
					<xsl:when test="current-group()/self::symbol[.='{']">
						<xsl:for-each-group select="current-group()" group-ending-with="symbol[.='}']">
							<xsl:choose>
								<xsl:when test="current-group()/self::symbol[.='}']">
									<properties>
										<xsl:copy-of select="current-group()[not(self::symbol[.=('{','}')])]"/>
									</properties>
								</xsl:when>
								<xsl:otherwise>
									<selectors>
										<xsl:copy-of select="current-group()"/>
									</selectors>
								</xsl:otherwise>
							</xsl:choose>
						</xsl:for-each-group>
					</xsl:when>
					<xsl:otherwise>
						<selectors>
							<xsl:copy-of select="current-group()"/>
						</selectors>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:for-each-group>
		</xsl:variable>
		<xsl:variable name="mode2">
			<xsl:apply-templates mode="css2xml2" select="$mode1"/>
		</xsl:variable>
		<xsl:variable name="mode3">
			<xsl:apply-templates mode="css2xml3" select="$mode2"/>
		</xsl:variable>
		<xsl:variable name="mode4">
			<xsl:apply-templates mode="css2xml4" select="$mode3"/>
		</xsl:variable>
		<xsl:copy-of select="$mode4"/> <!-- change $mode0 to $mode[0-9] for easy debug -->
	</xsl:template>

	<xsl:template priority="-9" mode="css2xml2" match="@*|node()">
		<xsl:copy>
			<xsl:apply-templates mode="css2xml2" select="@*|node()"/>
		</xsl:copy>
	</xsl:template>

	<xsl:template mode="css2xml2" match="/">
		<xsl:for-each-group select="node()" group-ending-with="properties">
			<rule>
				<xsl:apply-templates mode="css2xml2" select="current-group()"/>
			</rule>
		</xsl:for-each-group>
	</xsl:template>

	<xsl:template mode="css2xml2" match="selectors">
		<xsl:for-each-group select="node()" group-adjacent="name()='symbol' and .=','">
			<xsl:if test="not(current-grouping-key())">
				<selector>
					<xsl:apply-templates mode="css2xml2" select="current-group()"/>
				</selector>
			</xsl:if>
		</xsl:for-each-group>
	</xsl:template>

	<xsl:template mode="css2xml2" match="selector/keyword | selector/value">
		<name>
			<xsl:value-of select="."/>
		</name>
	</xsl:template>

	<xsl:template mode="css2xml2" match="properties">
		<xsl:for-each-group select="node()" group-adjacent="name()='symbol' and .=';'">
			<xsl:if test="not(current-grouping-key())">
				<property>
					<xsl:apply-templates mode="css2xml2" select="current-group()" />
				</property>
			</xsl:if>
		</xsl:for-each-group>
	</xsl:template>
		
	<xsl:template priority="-9" mode="css2xml3" match="@*|node()">
		<xsl:copy>
			<xsl:apply-templates mode="css2xml3" select="@*|node()"/>
		</xsl:copy>
	</xsl:template>

	<xsl:template mode="css2xml3" match="property[node()]" priority="-1">
		<xsl:message select="concat('unknown property: ', string-join(node(), ' '))" />
		<xsl:next-match />
	</xsl:template>

	<xsl:template mode="css2xml3" match="property[not(node())]" />

	<xsl:template mode="css2xml3" match="property[node()[1]/(self::keyword|self::name) and node()[2]/self::symbol[.=':']]">
		<xsl:copy>
			<xsl:attribute name="name" select="node()[1]" />
			<xsl:apply-templates mode="css2xml3" select="node() except(node()[1]|node()[2])" />
		</xsl:copy>
	</xsl:template>

	<xsl:template priority="-9" mode="css2xml4" match="@*|node()">
		<xsl:copy>
			<xsl:apply-templates mode="css2xml4" select="@*|node()"/>
		</xsl:copy>
	</xsl:template>

	<xsl:template mode="css2xml4" match="property[@name]">
		<xsl:copy>
			<xsl:apply-templates mode="css2xml4" select="@*|value|size|font|color|keyword,node() except (value|size|font|color|keyword)"/>
		</xsl:copy>
	</xsl:template>
	
	<xsl:template mode="css2xml4" match="property[@name]/*[self::value|self::size|self::font|self::color]">
		<xsl:attribute name="{name()}" select="." />
	</xsl:template>

	<xsl:template mode="css2xml4" match="property[@name]/keyword">
		<xsl:attribute name="value" select="." />
	</xsl:template>
</xsl:stylesheet>