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
								regex="^({string-join($config/keywords/keyword, '|')})$|^({string-join($config/values/value, '|')})$|^({string-join($config/fonts/font, '|')})$|^((-?\d+)(\.\d+)?)$"
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
					</xsl:if>
					<xsl:value-of select="."/>
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
									<attributes>
										<xsl:copy-of select="current-group()[not(self::symbol[.=('{','}')])]" />
									</attributes>
								</xsl:when>
								<xsl:otherwise>
									<selectors>
										<xsl:copy-of select="current-group()" />
									</selectors>
								</xsl:otherwise>
							</xsl:choose>
						</xsl:for-each-group>
					</xsl:when>
					<xsl:otherwise>
						<selectors>
							<xsl:copy-of select="current-group()" />
						</selectors>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:for-each-group>
		</xsl:variable>
		<xsl:copy-of select="$mode1"/> <!-- change $mode0 to $mode[0-9] for easy debug -->
	</xsl:template>

</xsl:stylesheet>