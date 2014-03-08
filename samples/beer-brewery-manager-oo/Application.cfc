/**
********************************************************************************
Copyright 2005-2014 ColdBox Framework by Luis Majano and Ortus Solutions, Corp
www.coldboxframework.com | www.luismajano.com | www.ortussolutions.com
********************************************************************************
*/
component{
	// Application properties
	this.name = "beer-brewery-manager";
	this.sessionManagement = true;
	this.sessionTimeout = createTimeSpan(0,0,30,0);
	this.setClientCookies = true;
	
	this.mappings[ "/root" ] = getDirectoryFromPath( getCurrentTemplatePath() );
	this.mappings[ "/cfcouchbase" ] = expandPath( "../../cfcouchbase" );
	
	// application start
	public boolean function onApplicationStart(){
		application.couchbase = new cfcouchbase.CouchbaseClient( { bucketName="beer-sample" } );
		application.breweryService = new root.model.BreweryService();
		
		// Specify the views the applications needs here.  They will be created/updated
		// when the client is initialized if they don't already exist.
		
		application.couchbase.asyncSaveView(
			'manager',
			'listBreweries',
			'function (doc, meta) {
			  if ( doc.type == ''brewery'' ) {
			    emit(doc.name, null);
			  }
			}',
			'_count'
		);
				
		application.couchbase.saveView(
			'manager',
			'listBeersByBrewery',
			'function (doc, meta) {
			  if ( doc.type == ''beer'' ) {
			    emit(doc.brewery_id, null);
			  }
			}',
			'_count'
		);
				
		return true;
	}
	
	// application stop
	public boolean function onApplicationEnd(){		
		application.couchbase.shutdown( 10 );
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