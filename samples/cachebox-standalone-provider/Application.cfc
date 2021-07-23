/**
********************************************************************************
Copyright 2005-2014 ColdBox Framework by Luis Majano and Ortus Solutions, Corp
www.coldboxframework.com | www.luismajano.com | www.ortussolutions.com
********************************************************************************
*/
component{
	// Application properties
	this.name = "beer-brewery-manager-" & hash(getCurrentTemplatePath());
	this.sessionManagement = true;
	this.sessionTimeout = createTimeSpan(0,0,30,0);
	this.setClientCookies = true;
	this.bufferOutput=true;

	rootPath = getDirectoryFromPath( getCurrentTemplatePath() );
	this.mappings[ "/root" ] = rootPath;
	this.mappings[ "/cfcouchbase" ] = expandPath( "../../cfcouchbase" );
	this.mappings[ "/cachebox" ] = rootPath & '/cachebox/';
	this.mappings[ "/couchbase-cachebox-provider" ] = rootPath & '/modules/couchbase-cachebox-provider/';

	// application start
	public boolean function onApplicationStart(){
		application.cachebox = new cachebox.system.cache.CacheFactory( 'root.CacheBoxConfig' );
		return true;
	}

	// application stop
	public boolean function onApplicationEnd(){
		if( isDefined( 'application.cachebox' ) ) {
			application.cachebox.shutdown();
		}
		return true;
	}



	// request start
	public boolean function onRequestStart(String targetPage){
		if( structKeyExists(url,'reinit') ) {
			applicationStop();
			onApplicationStart();
		}
		return true;

	}

}
