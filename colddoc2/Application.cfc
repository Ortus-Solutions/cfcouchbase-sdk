<!-----------------------------------------------------------------------
********************************************************************************
Copyright 2005-2007 ColdBox Framework by Luis Majano and Ortus Solutions, Corp
www.coldboxframework.com | www.luismajano.com | www.ortussolutions.com
********************************************************************************

Author     :	Luis Majano
Date        :	10/16/2007
Description :
	This is the Application.cfc for usage withing the ColdBox Framework.
	Make sure that it extends the coldbox object:
	coldbox.system.coldbox
	
	So if you have refactored your framework, make sure it extends coldbox.
----------------------------------------------------------------------->
<cfcomponent output="false">

	<!--- APPLICATION CFC PROPERTIES --->
	<cfset this.name = "cboxsite_" & hash(getCurrentTemplatePath())> 
	<cfset this.sessionManagement = true>
	<cfset this.sessionTimeout = createTimeSpan(0,0,30,0)>
	<cfset this.setClientCookies = true>
	
	<!--- 
	<cfset this.mappings["/coldbox"] = "/Users/lmajano/Sites/MyDevelopment/Frameworks/coldbox" > 
	--->
	<cfset this.mappings["/coldbox"] = "/Users/lmajano/Exports/coldbox/coldbox">
	
	<!--- Export Mappings --->
	<cfset this.mappings["/logbox"] = "/Users/lmajano/exports/logbox-distro/logbox" >
	<cfset this.mappings["/cachebox"] = "/Users/lmajano/exports/cachebox-distro/cachebox" >
	<cfset this.mappings["/mockbox"] = "/Users/lmajano/exports/mockbox-distro/mockbox" >
	<cfset this.mappings["/testbox"] = "/Users/lmajano/exports/testbox-distro/testbox" >
	<cfset this.mappings["/wirebox"] = "/Users/lmajano/exports/wirebox-distro/wirebox" >
	<cfset this.mappings["/contentbox"] = "/Users/lmajano/Sites/contentbox/wwww">
	
	<cfset this.mappings["/mxunit"] = "/Users/lmajano/Sites/MyDevelopment/Frameworks/mxunit" >
	
	<cfset this.mappings["/shared"] = expandPath("shared") >	
</cfcomponent>