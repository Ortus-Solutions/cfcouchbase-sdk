<!-----------------------------------------------------------------------
********************************************************************************
Copyright 2005-2007 ColdBox Framework by Luis Majano and Ortus Solutions, Corp
www.coldboxframework.com | www.luismajano.com | www.ortussolutions.com
********************************************************************************

Author      :	Luis Majano
Date        :	01/10/2008
License		: 	Apache 2 License
Description :
	A plugin to do wiki text interactions.

----------------------------------------------------------------------->
<cfcomponent name="WikiText" 
			 extends="coldbox.system.plugin" 
			 output="false" 
			 hint="A plugin to do wiki text interactions. CF8, Railo 3.0 only"
			 cache="true"
			 cacheTimeout="0">

<!------------------------------------------- CONSTRUCTOR ------------------------------------------->
	
	<cffunction name="init" access="public" returntype="WikiText" output="false" hint="Constructor">
		<!--- ************************************************************* --->
		<cfargument name="controller" type="any" required="true">
		<!--- ************************************************************* --->
		<cfscript>			
			super.init(arguments.controller);
			
			/* internal properties */
			setpluginName("WikiText");
			setpluginVersion("1.0");
			setpluginDescription("A plugin that can convert html to wiki text.");
			//3.0 properties
			//setpluginAuthor("Luis Majano");
			//setpluginAuthorURL("http://www.coldbox.org");
			
			/* WikiParser Lib Path */
			instance.parserLibPath = getDirectoryFromPath(getMetadata(this).path) & "lib";
			/* Java Loader */
			instance.javaLoader = getPlugin("JavaLoader");
			/* JavaLoad Parser Lib */
			instance.javaLoader.setup(pathToArray(instance.parserLibPath));
			
			/* Setup Patterns empty */
			setLinkBaseURL('${title}');
			setImageBaseURL('${image}');
			/* Setup Allowed Attributes */
			setAllowedAttributes('style,url');
			/* Ignore Tag List */
			setIgnoreTagList('img');
			
			/* Internal Constants For Translation */
			instance.WIKIPEDIA = "info.bliki.html.wikipedia.ToWikipedia";
			instance.GOOGLECODE = "info.bliki.html.googlecode.ToGoogleCode";
			instance.TRAC = "info.bliki.html.googlecode.ToTrac";
			instance.MOINMOIN = "info.bliki.html.googlecode.ToMoinMoin";
			instance.JSPWIKI = "info.bliki.html.jspwiki.ToJSPWiki";	
			/* Setup Translators */
			instance.translators = "WIKIPEDIA,GOOGLECODE,JSPWIKI,MOINMOIN,TRAC";
			
			
			/* now configure the plugin */
			configure();
			
			return this;
		</cfscript>
	</cffunction>

<!------------------------------------------- PUBLIC ------------------------------------------->
	
	<!--- toWiki --->
	<cffunction name="toWiki" output="false" access="public" returntype="string" hint="Convert an HTML string to wiki syntax">
		<cfargument name="wikiTranslator" 	type="string" required="true" hint="The wiki syntax to use. It must be using a valid translator. See getTranslators()"/>
		<cfargument name="htmlString" 		type="string" required="true" hint="The html string to convert"/>
		<cfscript>
			var translatorRegex = replace(getTranslators(),",","|","all");
			var converter = 0;
			var translator = 0;
			var javaLoader = instance.javaLoader;
			
			/* Validate incoming translator syntax */
			if( NOT reFindNoCase("^(#translatorRegex#)$",arguments.wikiTranslator) ){
				throw(message="Invalid Wiki Translator",
					  detail="The translator you sent in #arguments.wikiTranslator# is not valid.  Valid translators are #getTranslators()#",
					  type="WikiText.HTML2WikiConverter.InvalidTranslatorException");
			}
			
			/* create converter */
			converter = javaLoader.create("info.bliki.html.HTML2WikiConverter").init(arguments.htmlString);
			/* Create Syntax Translator */
			translator = javaLoader.create(instance[arguments.wikiTranslator]).init();
			
			return converter.toWiki(translator);
		</cfscript>		
	</cffunction>
	
	<!--- getTranslators --->
	<cffunction name="getTranslators" output="false" access="public" returntype="string" hint="Get the list of translators available">
		<cfreturn instance.translators>
	</cffunction>
	
	<!--- Ignore Tag List --->
	<cffunction name="getIgnoreTagList" access="public" output="false" returntype="string" hint="Get IgnoreTagList">
		<cfreturn instance.IgnoreTagList/>
	</cffunction>
	<cffunction name="setIgnoreTagList" access="public" output="false" returntype="void" hint="Set IgnoreTagList as a list of ignored translation xml/html elements. Ex: feed, messagebox, etc">
		<cfargument name="IgnoreTagList" type="string" required="true"/>
		<cfset instance.IgnoreTagList = arguments.IgnoreTagList/>
	</cffunction>
	
	<!--- Allowed Attributes --->
	<cffunction name="getAllowedAttributes" access="public" output="false" returntype="string" hint="Get AllowedAttributes">
		<cfreturn instance.AllowedAttributes/>
	</cffunction>
	<cffunction name="setAllowedAttributes" access="public" output="false" returntype="void" hint="Set AllowedAttributes when doing wiki parsing as a list. Ex: style, att, etc.">
		<cfargument name="AllowedAttributes" type="string" required="true"/>
		<cfset instance.AllowedAttributes = arguments.AllowedAttributes/>
	</cffunction>	


	<!--- Link BaseURL --->
	<cffunction name="getLinkBaseURL" access="public" output="false" returntype="string" hint="Get LinkBaseURL">
		<cfreturn instance.LinkBaseURL/>
	</cffunction>
	<cffunction name="setLinkBaseURL" access="public" output="false" returntype="void" hint="Set LinkBaseURL. example: http://wiki.coldbox.org/${title}">
		<cfargument name="LinkBaseURL" type="string" required="true"/>
		<cfset instance.LinkBaseURL = arguments.LinkBaseURL/>
	</cffunction>

	<!--- Image Pattern --->
	<cffunction name="getImageBaseURL" access="public" output="false" returntype="string" hint="Get ImageBaseURL">
		<cfreturn instance.ImageBaseURL/>
	</cffunction>
	<cffunction name="setImageBaseURL" access="public" output="false" returntype="void" hint="Set ImageBaseURL example: http://wiki.coldbox.org/images/${image}">
		<cfargument name="ImageBaseURL" type="string" required="true"/>
		<cfset instance.ImageBaseURL = arguments.ImageBaseURL/>
	</cffunction>
	
	<cffunction name="toHTML" access="public" returntype="struct" hint="Convert wiki text and return a structure with two keys: [wikiModel=The java wiki model object,html=the converted html string]" output="false" >
		<cfargument name="wikitext"  type="string" required="true" hint="The wiki text to convert to HTML">
		<cfscript>
			var rtn = {wikiModel=0,html=""};
			/* Create Wiki Model */
			rtn.wikiModel = getJavaLoader().create("com.codexwiki.bliki.model.WikiModel").init(getConfiguration(),getImageBaseURL(),getLinkBaseURL(),getLinkBaseURL()); 
			/* Render Data */
			rtn.html = trim(rtn.wikiModel.render(arguments.wikitext));
			return rtn;
		</cfscript>
	</cffunction>
	

<!------------------------------------------- PRIVATE ------------------------------------------->

	<!--- Configure Instance --->
	<cffunction name="configure" access="private" returntype="void" hint="Configure the plugin instance" output="false" >
		<cfscript>
			var config = getJavaLoader().create("info.bliki.wiki.model.Configuration").init();
			var TagNode = getJavaLoader().create("info.bliki.wiki.tags.HTMLTag");
			var xmlTag = 0;
			var attrib = 0;
		</cfscript>
		<!--- Add Allowed Attributes --->
		<cfloop list="#getAllowedAttributes()#" index="attrib">
			<cfscript>
				TagNode.addAllowedAttribute(attrib);
			</cfscript>
		</cfloop>
		<!--- Ignore XML Tag List --->
		<cfloop list="#getIgnoreTagList()#" index="xmlTag">
			<cfscript>
				config.addTokenTag(xmlTag, getJavaLoader().create("org.htmlcleaner.TagNode").init(xmlTag));
			</cfscript>
		</cfloop>
		<cfscript>
			/* CF Source Highlighting */
			config.addCodeFormatter("coldfusion", getJavaLoader().create("com.codexwiki.bliki.codeFilter.ColdFusionCodeFilter").init());
			/* Save Configuration Object */
			setConfiguration(config);
		</cfscript>
	</cffunction>

	<!--- Get Java Loader --->
	<cffunction name="getJavaLoader" access="private" returntype="any" hint="Get the java loader" output="false" >
		<cfreturn instance.javaLoader />
	</cffunction>
	
	<!--- Config Object --->
	<cffunction name="getConfiguration" access="private" output="false" returntype="any" hint="Get Configuration">
		<cfreturn instance.Configuration/>
	</cffunction>
	<cffunction name="setConfiguration" access="private" output="false" returntype="void" hint="Set Configuration">
		<cfargument name="Configuration" type="any" required="true"/>
		<cfset instance.Configuration = arguments.Configuration/>
	</cffunction>
	
	<!--- pathToArray --->
	<cffunction name="pathToArray" output="false" access="private" returntype="Array" hint="Convert a path into array format">
		<cfargument name="dirpath" type="string" required="true" hint="The dirpath to convert"/>	
		<cfargument name="filter" type="string" required="false" default="*.jar" hint="The filters to use"/>
		<cfset var qFiles = 0>
		<cfset var fileArray = ArrayNew(1)>
		<cfset var libName = 0>
		
		<cfdirectory action="list" directory="#arguments.dirpath#" name="qFiles" recurse="true" filter="#arguments.filter#">
		<cfloop query="qFiles">
			<cfset ArrayAppend(fileArray, directory & "/" & name)>
		</cfloop>
		
		<cfreturn fileArray>
	</cffunction>

</cfcomponent>