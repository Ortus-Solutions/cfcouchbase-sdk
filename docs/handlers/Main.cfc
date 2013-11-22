/**
* I manage the docs
*/
component{
	
	property name="wikiText" inject="coldbox:myplugin:WikiText";
	
	function index( event, rc, prc ){
		
		event.paramValue( "version", "1.0.0" );
		
		prc.markuppath = getSetting( "ApplicationPath" ) & "views/markup";

		// Setup link base URL
		wikiText.setLinkBaseURL( '' );
		
		// parse content
		var wikiModel = wikiText.toHTML( wikitext=fileRead( "#prc.markupPath#/#rc.version#.cfm" ) );
		prc.wikiContent = wikiModel.html;		
	}	
	
}
