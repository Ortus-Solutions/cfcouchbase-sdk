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
			customErrorTemplate		= "/coldbox/system/exceptions/Whoops.cfm",

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
			username="cfcouchbase",
			password="password"
		};

		moduleSettings = {

			// Provider Configuration Settings
			couchbaseCacheBoxProvider = {
				// Register all the custom named caches you like here using CacheBox Syntax
				// https://cachebox.ortusbooks.com/content/cachebox_configuration/caches.html
				caches : { 
					"couchBase" : {
						provider 	: "couchbaseCacheBoxProvider.models.CouchbaseProvider",
						properties 	: {
							// The default timeout for cache entries
							objectDefaultTimeout    : 120,
							// Ignores timeouts on Couchbase operations due to async natures
							ignoreCouchbaseTimeouts : true,
							// The bucketname in Couchbase to store cache entries under, the default value is 'default'
							bucket                  : "default",
							// The list of servers in the Couchbase cluster
							servers					: "127.0.0.1:8091",
							// The username for the Couchbase bucket, if any
							username				: "cfcouchbase",
							// The password for the Couchbase bucket, if any
							password				: "password"
						}
					}
				}
			}
		};

	}

}
