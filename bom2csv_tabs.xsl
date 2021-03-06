<!--
    @package
    EESCHEMA BOM plugin.
    Creates BOM CSV files from the project net file.
    Based on Ronald Sousa bom_with_title_block_2_csv

    Revised by Jerry Dunmire to support Tab, Comma,
    Semicolon, or space as the field separator.
    Adjust the sep entity below. Default is tab.

    Note:
        The project infomation (i.e title, company and
        revision) is taken from and the root sheet.

    Usage:
        on Windows:
            xsltproc -o "%O.csv" "C:\Program Files (x86)\KiCad\bin\plugins\bom2csv.xsl" "%I"
        on Linux:
            xsltproc -o "%O.csv" /usr/local/lib/kicad/plugins/bom2csv.xsl "%I"

    Ouput Example:
        Source,
        Kicad Rev,  working directory and file source
        Generated Date, date this file was generated

        Title, the project's tile
        Company, the project's company
        Rev, the project's revision
        Date Source, project's issue date
        Comment, This is comment 1
        Comment, This is comment 2
        Comment, This is comment 3
        Comment, This is comment 4

        Reference, Value, Fields[n], Library, Library Ref
        U1, PIC32MX, Fields[n], KicadLib, PIC
-->

<!DOCTYPE xsl:stylesheet [
  <!ENTITY nl  "&#xd;&#xa;">    <!--new line CR, LF, or LF, your choice -->
  <!ENTITY sep  "&#x9;">    <!-- tab(9), comma(44), semicolon(59) or space(32) -->
]>

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
    <xsl:output method="text"/>

    <!-- for table head and empty table fields-->
    <xsl:key name="headentr" match="field" use="@name"/>

    <!-- main part -->
    <xsl:template match="/export">
        <xsl:text>Source&sep;</xsl:text><xsl:value-of  select="design/source"/><xsl:text>&nl;</xsl:text>
        <xsl:text>Kicad Rev&sep;</xsl:text><xsl:value-of  select="design/tool"/><xsl:text>&nl;</xsl:text>
        <xsl:text>Generated Date&sep;</xsl:text><xsl:value-of  select="design/date"/><xsl:text>&nl;</xsl:text>

        <xsl:text>&nl;</xsl:text>

        <!-- Ouput Root sheet project information -->
        <xsl:apply-templates select="/export/design/sheet[1]"/>

        <xsl:text>&nl;</xsl:text>

        <!-- Output table header -->
        <xsl:text>Reference&sep;Value&sep;</xsl:text>
        <xsl:for-each select="components/comp/fields/field[generate-id(.) = generate-id(key('headentr',@name)[1])]">
            <xsl:value-of select="@name"/>
            <xsl:text>&sep;</xsl:text>
        </xsl:for-each>
        <xsl:text>Library&sep;Library Ref</xsl:text>
        <xsl:text>&nl;</xsl:text>

        <!-- all table entries -->
        <xsl:apply-templates select="components/comp"/>
    </xsl:template>

    <!-- generate the Root sheet project information -->
    <xsl:template match="/export/design/sheet[1]">

        <xsl:choose>
            <xsl:when test="title_block/title !=''">
                <xsl:text>Title&sep;</xsl:text><xsl:value-of  select="title_block/title"/><xsl:text>&nl;</xsl:text>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>Title&sep;Not Set</xsl:text><xsl:text>&nl;</xsl:text>
            </xsl:otherwise>
        </xsl:choose>


        <xsl:choose>
            <xsl:when test="title_block/company !=''">
                <xsl:text>Company&sep;</xsl:text><xsl:value-of  select="title_block/company"/><xsl:text>&nl;</xsl:text>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>Company&sep;Not Set</xsl:text><xsl:text>&nl;</xsl:text>
            </xsl:otherwise>
        </xsl:choose>

        <xsl:choose>
            <xsl:when test="title_block/rev !=''">
                <xsl:text>Revision&sep;</xsl:text><xsl:value-of  select="title_block/rev"/><xsl:text>&nl;</xsl:text>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>Revision&sep;Not Set</xsl:text><xsl:text>&nl;</xsl:text>
            </xsl:otherwise>
        </xsl:choose>

        <xsl:choose>
            <xsl:when test="title_block/date !=''">
                <xsl:text>Date Issue&sep;</xsl:text><xsl:value-of  select="title_block/date"/><xsl:text>&nl;</xsl:text>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>Date Issue&sep;Not Set</xsl:text><xsl:text>&nl;</xsl:text>
            </xsl:otherwise>
        </xsl:choose>

        <xsl:apply-templates select="title_block/comment"/>

    </xsl:template>

    <xsl:template match="title_block/comment">
        <xsl:choose>
            <xsl:when test="@value !=''">
            <xsl:text>Comment&sep;</xsl:text><xsl:value-of  select="@value"/><xsl:text>&nl;</xsl:text>
            </xsl:when>
        </xsl:choose>
    </xsl:template>



    <!-- the table entries -->
    <xsl:template match="components/comp">
        <xsl:value-of select="@ref"/><xsl:text>&sep;</xsl:text>
        <xsl:value-of select="value"/><xsl:text>&sep;</xsl:text>
        <xsl:apply-templates select="fields"/>
        <xsl:apply-templates select="libsource"/>
        <xsl:text>&nl;</xsl:text>
    </xsl:template>

    <!-- the library selection -->
    <xsl:template match="libsource">
        <xsl:value-of select="@lib"/><xsl:text>&sep;</xsl:text>
        <xsl:value-of select="@part"/>
    </xsl:template>

    <!-- table entries with dynamic table head -->
    <xsl:template match="fields">

        <!-- remember current fields section -->
        <xsl:variable name="fieldvar" select="field"/>

        <!-- for all existing head entries -->
        <xsl:for-each select="/export/components/comp/fields/field[generate-id(.) = generate-id(key('headentr',@name)[1])]">
            <xsl:variable name="allnames" select="@name"/>

            <!-- for all field entries in the remembered fields section -->
            <xsl:for-each select="$fieldvar">

                <!-- only if this field entry exists in this fields section -->
                <xsl:if test="@name=$allnames">
                    <!-- content of the field -->
                    <xsl:value-of select="."/>
                </xsl:if>
                <!--
                    If it does not exist, use an empty cell in output for this row.
                    Every non-blank entry is assigned to its proper column.
                -->
            </xsl:for-each>
            <xsl:text>&sep;</xsl:text>
        </xsl:for-each>
    </xsl:template>

 </xsl:stylesheet>
