/**
* Manage the wikitext library
*/
component accessors="true" singleton{

	// DI
	property name="javaloader" inject="loader@cbjavaloader";

	// Properties
	property name="parserLibPath";
	property name="linkBaseURL";
	property name="imageBaseURL";
	property name="allowedAttributes";
	property name="ignoreTagList";
	property name="translators";
	property name="configuration";

	/**
	* Constructor
	*/
	function init(){
		/* WikiParser Lib Path */
		variables.parserLibPath = getDirectoryFromPath(getMetadata(this).path) & "lib";
		/* Setup Patterns empty */
		setLinkBaseURL('${title}');
		setImageBaseURL('${image}');
		/* Setup Allowed Attributes */
		setAllowedAttributes('style,url');
		/* Ignore Tag List */
		setIgnoreTagList('img');

		/* Internal Constants For Translation */
		variables.WIKIPEDIA = "info.bliki.html.wikipedia.ToWikipedia";
		variables.GOOGLECODE = "info.bliki.html.googlecode.ToGoogleCode";
		variables.TRAC = "info.bliki.html.googlecode.ToTrac";
		variables.MOINMOIN = "info.bliki.html.googlecode.ToMoinMoin";
		variables.JSPWIKI = "info.bliki.html.jspwiki.ToJSPWiki";
		/* Setup Translators */
		variables.translators = "WIKIPEDIA,GOOGLECODE,JSPWIKI,MOINMOIN,TRAC";

		return this;
	}

	/**
	* Convert an HTML string to wiki syntax
	* @wikiTranslator The wiki syntax to use. It must be using a valid translator. See getTranslators()
	* @htmlString The html string to convert
	*/
	function toWiki( required wikiTranslator, required htmlString ){
		var translatorRegex = replace(getTranslators(),",","|","all");
		var converter = 0;
		var translator = 0;
		var javaLoader = variables.javaloader;

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
	}


	/**
	* Convert wiki text and return a structure with two keys: [wikiModel=The java wiki model object,html=the converted html string]
	* @wikitext The wiki text to convert to HTML
	*/
	function toHTML( required wikitext ){
		var rtn = {wikiModel=0,html=""};
		/* Create Wiki Model */
		rtn.wikiModel = getJavaLoader().create("com.codexwiki.bliki.model.WikiModel").init(getConfiguration(),getImageBaseURL(),getLinkBaseURL(),getLinkBaseURL());
		/* Render Data */
		rtn.html = trim(rtn.wikiModel.render(arguments.wikitext));
		return rtn;
	}

	/**
	* Configure the Wiki Converter Driver, usually called after construction when a system is ready to startup the engine
	*/
	function configure(){
		var config = getJavaLoader().create("info.bliki.wiki.model.Configuration").init();
		var TagNode = getJavaLoader().create("info.bliki.wiki.tags.HTMLTag");
		var xmlTag = 0;
		var attrib = 0;

		var aAttributes = listToArray( getAllowedAttributes() );
		for( var thisAttribute in aAttributes ){
			TagNode.addAllowedAttribute( thisAttribute );
		}

		var aIgnoreList = listToArray( getIgnoreTagList() );
		for( var thisTag in aIgnoreList ){
			config.addTokenTag(xmlTag, getJavaLoader().create("org.htmlcleaner.TagNode").init( thisTag ));
		}


		/* CF Source Highlighting */
		config.addCodeFormatter("coldfusion", getJavaLoader().create("com.codexwiki.bliki.codeFilter.ColdFusionCodeFilter").init());
		/* Save Configuration Object */
		setConfiguration( config );
	}

}