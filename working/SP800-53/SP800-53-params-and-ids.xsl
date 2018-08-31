<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:math="http://www.w3.org/2005/xpath-functions/math"
  exclude-result-prefixes="xs math"
  xmlns="http://csrc.nist.gov/ns/oscal/1.0"
  xpath-default-namespace="http://csrc.nist.gov/ns/oscal/1.0"
  version="3.0">
  
<!-- For further tweaking SP800-53 OSCAL -->

<!--  silencing noisy Saxon ... -->
  <xsl:template match="/*">
    <xsl:next-match/>
  </xsl:template>
  
  <xsl:mode on-no-match="shallow-copy"/>
  
  <!-- We produce param elements and insert them into controls, for any .//assign
       elements found herein.
  
  
  Note 'assign' is a temporary (placeholder) element from an earlier step; it
  marks where 'assignment' syntax has been used in the source. In the result,
  it produces a param|insert pair. -->
  
<!-- Promoting label ids (id values derived from labels in earlier steps) to IDs. No further IDs should
     be required and they should even validate. -->
  <xsl:template match="@label-id">
    <xsl:attribute name="id" select="."/>
  </xsl:template>
  
  <!-- Just in case -->
  <xsl:template match="@id[exists(../@label-id)]"/>
  
  <xsl:template match="control | subcontrol">
    <xsl:copy>
      <xsl:apply-templates select="@*"/>
      <xsl:apply-templates select="title"/>
      <xsl:apply-templates select=".//(assign|selection) except subcontrol//(assign|selection)" mode="make-param"/>
      <xsl:apply-templates select="* except title"/>
    </xsl:copy>
  </xsl:template>
  
  <xsl:template match="assign" mode="make-param">
    <param>
      <xsl:attribute name="id">
        <xsl:apply-templates select="." mode="make-id"/>
      </xsl:attribute>
      <xsl:for-each select="ancestor::selection">
        <xsl:attribute name="depends-on">
          <xsl:apply-templates select="." mode="make-id"/>
        </xsl:attribute>
      </xsl:for-each>
      <!--<label>
        <xsl:text>INSERT into </xsl:text>
        <xsl:apply-templates select="ancestor-or-self::*[@id][1]" mode="munge-id"/>
        <xsl:value-of select="ancestor::part[prop/@class='name'][1]/prop[@class='name'] ! (' (' || . || ')')"/>
      </label>-->
      <label>
        <xsl:apply-templates/>
      </label>
    </param>
  </xsl:template>
  
  <xsl:template match="selection" mode="make-param">
    <xsl:variable name="oneOrMore" select="starts-with(.,'(one or more)')"/>
    <param>
      <xsl:attribute name="id">
        <xsl:apply-templates select="." mode="make-id"/>
      </xsl:attribute>
      <!--<label>
        <xsl:text expand-text="true">SELECTION{ if ( $oneOrMore) then ' (one or more)' else '' }</xsl:text>
      </label>-->
      <!--<xsl:for-each select="ancestor::part[prop/@class='name'][1]/prop[@class='name']">
        <desc>
          <xsl:text>Insertion into </xsl:text> 
          <xsl:apply-templates/>
          <xsl:value-of select="ancestor::part[prop/@class='name'][1]/prop[@class='name'] ! (' (' || . || ')')"/>
        </desc>
      </xsl:for-each>-->
      <select>
        <xsl:if test="$oneOrMore">
          <xsl:attribute name="how-many">one or more</xsl:attribute>
        </xsl:if>
        <xsl:apply-templates mode="#default"/>
      </select>
    </param>
  </xsl:template>
  
  <xsl:template match="selection/text()[.='(one or more)']" mode="#default"/>
  
  <xsl:template match="assign | selection">
    <insert>
      <xsl:attribute name="param-id">
        <xsl:apply-templates select="." mode="make-id"/>
      </xsl:attribute>
    </insert>
  </xsl:template>
  
  <xsl:template match="assign | selection" mode="make-id">
    <xsl:value-of select="(ancestor::control | ancestor::subcontrol)[last()]/@id"/>
    <xsl:text>_prm_</xsl:text>
    <xsl:number count="assign | selection" from="control | subcontrol" level="any" format="1"/>
  </xsl:template>

  <xsl:key name="control-by-label" match="control | subcontrol" use="prop[@class='label']"/>
  
  <xsl:template match="link">
    <xsl:copy>
      <xsl:attribute name="rel">related</xsl:attribute>
      <xsl:for-each select="key('control-by-label',.)">
        <xsl:attribute name="href">
          <xsl:text>#</xsl:text>
          <xsl:value-of select="@label-id"/>
        </xsl:attribute>
      </xsl:for-each>
      
      <xsl:apply-templates/>
    </xsl:copy>
  </xsl:template>
  
  
  
  <!--<xsl:template match="part[@class='objective']">
    <xsl:copy>
      <xsl:attribute name="id">
        <xsl:apply-templates select="." mode="munge-id"/>
      </xsl:attribute>
      <xsl:apply-templates select="@*"/>
      <xsl:apply-templates/>
    </xsl:copy>
  </xsl:template>-->
  
  <!-- prepare for @id munging modifications for rev4/ rev5, SP800-53A ... -->
  <!--<xsl:value-of select="replace(@id,'\p{P}\p{P}*','.') => replace('\.(\.|$)','$1')"/>-->
  <!--<xsl:template as="xs:string" mode="munge-id" match="control | part">
    <xsl:value-of select="replace(@id,'\p{P}\p{P}*','.') => replace('\.(\.|$)','$1')"/>
    <!-\-<xsl:value-of select="@id"/>-\->
  </xsl:template>
  
  <xsl:template as="xs:string" mode="munge-id" match="subcontrol">
    <xsl:value-of select="replace(@id,'\.(\.|$)','$1')"/>
  </xsl:template>-->
  
  
  
  <!--<xsl:template as="xs:string" mode="munge-id" match="part[@class='objective']">
    <xsl:value-of>
      <xsl:apply-templates select="(ancestor::control | ancestor::subcontrol)[last()]" mode="munge-id"/>
      <xsl:text>_obj_</xsl:text>
      <!-\-<xsl:number format="a.1.1.a.1.1." level="multiple" count="part[@class='objective']"
        from="part[@class='objective'][empty(parent::part)]"/> works for AC-1 -\->
      <!-\- Numbering scheme for AC-2     -\->
      <!-\-<xsl:number format="a.1.a.1" level="multiple" count="part/part[@class='objective']"
        from="part[@class='objective'][empty(parent::part)]"/>-\->
      <!-\- Instead of imposing a scheme, presently we rewrite the number given. -\->
      <!-\- CHECK FOR CORRECTNESS -\->
      <xsl:value-of select="replace(prop[@class='label'],'[A-Z]+\-\d+\D','') =>
        replace('\p{P}+','.') => replace('\.$','')"/>
    </xsl:value-of>
    <!-\- Note outputs only happen to be valid in the result -\->
  </xsl:template>-->
  
  <!--<xsl:template as="xs:string" mode="munge-id" match="part">
    <!-\- id leads with element class or name code, plus @id value stripped of punctuation -\->
    <!-\-<xsl:value-of select="( 's_'[exists(current()/ancestor::subcontrol)] || (current()/@class/string(),name(..))[1] => translate('ectani-','') => substring(1,3)) || '_' || replace(@id,'\p{P}($|\p{P}+)','.')"/>-\->
    <!-\- Note outputs only happen to be valid in the result -\->
  </xsl:template>-->
  
</xsl:stylesheet>