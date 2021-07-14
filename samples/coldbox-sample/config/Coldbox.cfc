component{

	// Configure ColdBox Application
	function configure(){

		// coldbox directives
		coldbox = {
			//Application Setup
			appName 				= "Couchbase Module App",

			//Development Settings
			reinitPassword			= "",

			//Extension Points
			UDFLibraryFile 				= "includes/helpers/ApplicationHelper.cfm",
			modulesExternalLocation		= [],
			pluginsExternalLocation 	= "",
			viewsExternalLocation		= "",
			layoutsExternalLocation 	= "",
			handlersExternalLocation  	= "",
			requestContextDecorator 	= "",

			//Error/Exception Handling
			exceptionHandler		= "",
			onInvalidEvent			= "",
			//customErrorTemplate		= "/coldbox/system/includes/BugReport.cfm",

			//Application Aspects
			handlerCaching 			= false,
			eventCaching			= false
		};

		// custom settings
		settings = {

		};

		// environment settings, create a detectEnvironment() method to detect it yourself.
		// create a function with the name of the environment so it can be executed if that environment is detected
		// the value of the environment is a list of regex patterns to match the cgi.http_host.
		environments = {
			development = "^cf.,^lucee.,local,^127"
		};

		// Couchbase Configuration
		couchbase = {
			servers		= "http://127.0.0.1:8091",
			bucketname	= "beer-sample",
			viewTimeout	= "1000",
      // this is only needed for Couchbase Server 5.0+
      username="beer-sample",
      password="password"
		};

	}

}
