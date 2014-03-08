/**
Couchbase SDK Loader
*/
component {
	
	// Module Properties
	this.title 				= "couchbase-sdk";
	this.author 			= "Ortus Solutions, Corp";
	this.webURL 			= "http://www.ortussolutions.com";
	this.description 		= "Couchbase SDK";
	this.version			= "1.0.0";
	// If true, looks for views in the parent first, if not found, then in the module. Else vice-versa
	this.viewParentLookup 	= true;
	// If true, looks for layouts in the parent first, if not found, then in module. Else vice-versa
	this.layoutParentLookup = true;
	// Module Entry Point
	this.entryPoint			= "couchbase-sdk";
	
	function configure(){
		
		// module settings - stored in modules.name.settings
		settings = {
			couchbase = { servers="http://127.0.0.1:8091", bucketname="default", viewTimeout="1000"  }
		};
		
		// SES Routes
		routes = [
			// Module Entry Point
			{pattern="/", handler="main",action="index"},
			// Convention Route
			{pattern="/:handler/:action?"}		
		];		
		
		// Custom Declared Points
		interceptorSettings = {
			customInterceptionPoints = ""
		};
		
		// Custom Declared Interceptors
		interceptors = [
		];
		
	}

	function development(){
		// fired if in development
		settings.couchbase = { servers="http://127.0.0.1:8091", bucketname="beer-sample" };
	}
	
	/**
	* Fired when the module is registered and activated.
	*/
	function onLoad(){
		// Map our Couchbase Client using per-environment settings.
		binder.map( "Client@couchbase" )
			.to( "cfcouchbase.CouchbaseClient" )
			.initArg( name="config", value=settings.couchbase )
			.asSingleton();
	}
	
	/**
	* Fired when the module is unregistered and unloaded
	*/
	function onUnload(){
		// safely destroy connection
		wirebox.getInstance( "Client@couchbase" ).shutdown();
	}
	
}