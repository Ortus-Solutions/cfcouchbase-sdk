/**
* Copyright Since 2005 Ortus Solutions, Corp
* www.ortussolutions.com
* ---
*/
component{
	this.name = "CFCouchbase Testing Suite";
	this.sessionManagement = true;

	// Turn on/off white space management
	this.whiteSpaceManagement = "smart";

	// mappings
	this.mappings[ "/tests" ] = getDirectoryFromPath( getCurrentTemplatePath() );

	rootPath = REReplaceNoCase( this.mappings[ "/tests" ], "tests(\\|\/)$", "" );
	this.mappings[ "/root" ]        = rootPath;
	this.mappings[ "/cfcouchbase" ] = rootPath & "cfcouchbase";

	// request start
	public boolean function onRequestStart( String targetPage ){
		return true;
	}
}