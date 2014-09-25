/**
* <strong>Copyright Since 2005 Ortus Solutions, Corp</strong><br>
* <a href="http://www.ortussolutions.com">www.ortussolutions.com</a>
* <p>CFCouchbase Module Configuration</p>
* @author Luis Majano, Brad Wood
*/
component{

	// Module Properties
	this.title 				= "CFCouchbase SDK";
	this.author 			= "Ortus Solutions, Corp";
	this.webURL 			= "http://www.ortussolutions.com";
	this.description 		= "ColdFusion SDK to interact with Couchbase NoSQL Server";
	this.version			= "1.1.0.00074";
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
		// Map Config
		binder.map( "CouchbaseConfig" )
			.to( "cfcouchbase.config.CouchbaseConfig" );
	}

	/**
	* Fired when the module is activated.
	*/
	function onLoad(){
		var configStruct = controller.getConfigSettings();
		// parse parent settings
		parseParentSettings();
		// Map our Couchbase Client using per-environment settings.
		binder.map( "CouchbaseClient@cfcouchbase" )
			.to( "cfcouchbase.CouchbaseClient" )
			.initArg( name="config", value=configStruct.couchbase )
			.asSingleton();
	}

	/**
	* Fired when the module is unloaded
	*/
	function onUnload(){
		// safely destroy connection
		wirebox.getInstance( "CouchbaseClient@cfcouchbase" ).shutdown();
	}

	/**
	* Prepare settings and returns true if using i18n else false.
	*/
	private function parseParentSettings(){
		var oConfig 		= controller.getSetting( "ColdBoxConfig" );
		var configStruct 	= controller.getConfigSettings();
		var couchbase 		= oConfig.getPropertyMixin( "couchbase", "variables", structnew() );

		//defaults
		configStruct.couchbase = {
			servers 	= "http://127.0.0.1:8091",
			bucketname 	= "default",
			viewTimeout	= "1000"
		};

		//Check for IOC Framework
		structAppend( configStruct.couchbase, couchbase, true );
	}

}