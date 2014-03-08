component extends="coldbox.system.Coldbox" {
	this.name = hash(getCurrentTemplatePath()); 
	this.sessionManagement = true;
	this.sessionTimeout = createTimeSpan(0,0,30,0);
	this.setClientCookies = true;
		
	this.mappings[ "/root" ] = getDirectoryFromPath( getCurrentTemplatePath() );
	this.mappings[ "/cfcouchbase" ] = expandPath( "../../cfcouchbase" );
	
	// COLDBOX STATIC PROPERTY, DO NOT CHANGE UNLESS THIS IS NOT THE ROOT OF YOUR COLDBOX APP
	COLDBOX_APP_ROOT_PATH = getDirectoryFromPath(getCurrentTemplatePath());
	// The web server mapping to this application. Used for remote purposes or static purposes
	COLDBOX_APP_MAPPING   = "";
	// COLDBOX PROPERTIES
	COLDBOX_CONFIG_FILE   = "";	
	// COLDBOX APPLICATION KEY OVERRIDE
	COLDBOX_APP_KEY       = "";

	boolean function onRequestStart( required string targetPage ) {
		
		// Process A ColdBox Request Only
		if( findNoCase('index.cfm', listLast(arguments.targetPage, '/')) ) {
			// Reload Checks
			reloadChecks();
			// Process Request
			processColdBoxRequest();
		}			
		
		return true;
	}
	
}