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
		
		};
		
		// SES Routes
		routes = [
			// Module Entry Point
			{pattern="/", handler="home",action="index"},
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
	
	/**
	* Fired when the module is registered and activated.
	*/
	function onLoad(){
		binder.map( "CouchbaseClient" )
			.toPath( "#moduleMapping#.model.CouchbaseClient" )
			.asSingleton();
	}
	
	/**
	* Fired when the module is unregistered and unloaded
	*/
	function onUnload(){
		
	}
	
}