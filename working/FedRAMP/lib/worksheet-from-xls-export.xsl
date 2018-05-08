<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    exclude-result-prefixes="xs"
    xmlns="http://csrc.nist.gov/ns/oscal/1.0"
    version="3.0">

<xsl:output indent="yes"/>
    
<xsl:strip-space _elements="*"/>
 
    
    <xsl:variable name="class-regex" as="xs:string">(AC|AT|AU|CA|CM|CP|IA|IR|MA|MP|PE|PL|PS|RA|SA|SC|SI)</xsl:variable>
    <xsl:variable name="controlorenhancement-regex" as="xs:string" expand-text="true">^{$class-regex}</xsl:variable>
    <xsl:variable name="control-regex"              as="xs:string" expand-text="true">^{$class-regex}\-\d+$</xsl:variable>
    <xsl:variable name="enhancement-regex"          as="xs:string" expand-text="true">^{$class-regex}\-\d+\s+\(\d+\)$</xsl:variable>
    
    <xsl:template match="/*" expand-text="yes">
        <xsl:comment expand-text="true"> XML produced by running { document('')/document-uri(.) } on { document-uri(/) } </xsl:comment> 
        <xsl:text>&#xA;</xsl:text>
        <worksheet>
            <title>FedRAMP in OSCAL PROTOTYPE</title>
            <xsl:for-each-group select="row" group-by="Family">
                <!-- exploiting the order; remember . is the leader of the group -->
                <group>
                    <prop class="family">{ current-grouping-key() }</prop>
                    <prop class="group-id">{substring-before(Sort_ID,'-')}</prop>
                    <!-- next grouping rows for each control and its enhancements -->
                    <xsl:for-each-group select="current-group()"
                         group-by="replace(Sort_ID,' .*','')">
                        <component>
                            <xsl:apply-templates select="."/>
                         <!--the first row represents the control, subsequent ones are subcontrols-->
                            
                            <xsl:for-each select="current-group() except .">
                                <component>
                                    <xsl:apply-templates select="."/>
                                </component>
                            </xsl:for-each>
                                
                        </component>
                    </xsl:for-each-group>
                </group>
                
            </xsl:for-each-group>
        </worksheet>
    </xsl:template>
    
    <xsl:template match="row">
        <xsl:apply-templates select="Control_name, * except Control_name"/>
    </xsl:template>
    
    <xsl:template match="row/*" priority="-0.4">
        <p class="{lower-case(name())}"><xsl:apply-templates/></p>
    </xsl:template>
    
    <!--<xsl:template match="row/*[not(matches(.,'\S'))]" priority="-0.3"/>-->
    
    <xsl:template match="Control_desc | Count | Sort_ID | Baseline | Parameters[not(matches(.,'\S'))] | Additional[not(matches(.,'\S'))]"/>
    
    <xsl:template match="Has_params">
        <!-- deleting the element unless it is not redundant -->
        <xsl:if test="matches(.,'\S') and not(matches(../Parameters,'\S'))">
            <prop class="has_params"/></xsl:if>
    </xsl:template>
    
    <xsl:template match="Control_name">
        <title>
            <xsl:value-of select="tokenize(., ' \| ')[last()]"/>
        </title>
    </xsl:template>
    
    <xsl:template match="Family">
        <prop class="family">
            <xsl:apply-templates/>
        </prop>
    </xsl:template>
    
    <xsl:template match="ID">
        <prop class="name">
            <xsl:apply-templates/>
        </prop>
    </xsl:template>
    
    
    
    
</xsl:stylesheet>