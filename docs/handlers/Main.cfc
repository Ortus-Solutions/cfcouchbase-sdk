/**
* I manage the docs
*/
component{
	
	property name="wikiText" inject="coldbox:myplugin:WikiText";
	
	function index( event, rc, prc ){
		
		event.paramValue( "version", "1.0.0" );
		event.paramValue( "sdkversion", "1.3.1" );
		
		prc.markuppath = getSetting( "ApplicationPath" ) & "views/markup";
		prc.apidocs = "http://apidocs.ortussolutions.com/CFCouchbase_APIDocs_1.0.0/index.html";

		// Setup link base URL
		wikiText.setLinkBaseURL( '' );
		
		// parse content
		var wikiModel 	= wikiText.toHTML( wikitext=renderView( "markup/#rc.version#" ) );
		
		prc.wikiContent = wikiModel.html;		
	}	
	
}
