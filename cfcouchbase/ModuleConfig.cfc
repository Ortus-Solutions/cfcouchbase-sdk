/**
* <strong>Copyright Since 2005 Ortus Solutions, Corp</strong><br>
* <a href="http://www.ortussolutions.com">www.ortussolutions.com</a>
* <p>CFCouchbase Module Configuration</p>
* @author Luis Majano, Brad Wood, Aaron Benton
*/
component{

	// Module Properties
	this.title 				= "CFCouchbase SDK";
	this.author 			= "Ortus Solutions, Corp";
	this.webURL 			= "http://www.ortussolutions.com";
	this.description 		= "ColdFusion SDK to interact with Couchbase NoSQL Server";
	this.version			= "@build.version@+@build.number@";
	// If true, looks for views in the parent first, if not found, then in the module. Else vice-versa
	this.viewParentLookup 	= true;
	// If true, looks for layouts in the parent first, if not found, then in module. Else vice-versa
	this.layoutParentLookup = true;
	// Module Entry Point
	this.entryPoint			= "cfcouchbase";
	// Model Namespace to use
	this.modelNamespace		= "cfcouchbase";
	// CF Mapping to register
	this.cfmapping			= "cfcouchbase";
	// Module Dependencies to be loaded in order
	this.dependencies 		= [];

	/**
	* Fired on Module Registration
	*/
	function configure(){
		
		settings = {
			servers 	= "http://127.0.0.1:8091",
			bucketname 	= "default",
			viewTimeout	= "1000"
		};
		
		// Map Config
		binder.map( "CouchbaseConfig@cfcouchbase" )
			.to( "#moduleMapping#.config.CouchbaseConfig" );
	}

	/**
	* Fired when the module is activated.
	*/
	function onLoad(){
		// Backwards compat for ColdBox settings
		if( !isNull( controller ) ) {
			settings = parseParentSettings();	
		}
		// Map our Couchbase Client using per-environment settings.
		binder.map( "CouchbaseClient@cfcouchbase" )
			.to( "#moduleMapping#.CouchbaseClient" )
			.initArg( name="config", value=settings )
			.asSingleton();
	}

	/**
	* Fired when the module is unloaded
	*/
	function onUnload(){
		// safely destroy connection
		if( wirebox.getScope( 'singleton' ).getSingletons().containsKey( "couchbaseclient@cfcouchbase" ) ) {
			wirebox.getInstance( "CouchbaseClient@cfcouchbase" ).shutdown();
		}
	}

	/**
	* Prepare settings and returns true if using i18n else false.
	*/
	private function parseParentSettings(){
		var oConfig 		= controller.getSetting( "ColdBoxConfig" );
		var configStruct 	= controller.getConfigSettings();
		var couchbase 		= oConfig.getPropertyMixin( "couchbase", "variables", structnew() );

		// defaults
		configStruct.couchbase = {
			servers 	= "http://127.0.0.1:8091",
			bucketname 	= "default",
			viewTimeout	= "1000"
		};

		// configure settings
		structAppend( configStruct.couchbase, couchbase, true );
		return configStruct.couchbase;
	}

}