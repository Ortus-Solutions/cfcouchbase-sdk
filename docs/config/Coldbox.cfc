component{

	// Configure ColdBox Application
	function configure(){
	
		// coldbox directives
		coldbox = {
			//Application Setup
			appName 				= "CFCouchbase SDK Docs",
	
			//Development Settings
			handlersIndexAutoReload = false,
	
			//Implicit Events
			defaultEvent			= "",
			requestStartHandler		= "",
			requestEndHandler		= "",
			applicationStartHandler = "",
			applicationEndHandler	= "",
			sessionStartHandler 	= "",
			sessionEndHandler		= "",
			missingTemplateHandler	= "",
	
			//Error/Exception Handling
			exceptionHandler		= "",
			onInvalidEvent			= "",
			customErrorTemplate		= "",
	
			//Application Aspects
			handlerCaching 			= true
		};
		
		// custom settings
		settings = {
		};

		// environment settings, create a detectEnvironment() method to detect it yourself.
		// create a function with the name of the environment so it can be executed if that environment is detected
		// the value of the environment is a list of regex patterns to match the cgi.http_host.
		environments = {
			development = "^cf.,^railo.,local"
		};
		
	}
	
	function development(){
		coldbox.handlersIndexAutoReload = true;
		coldbox.handlerCaching = false;
		coldbox.debugPassword = "";
		coldbox.reinitPassword = "";
	}
	
}