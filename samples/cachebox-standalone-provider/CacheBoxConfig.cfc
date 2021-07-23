component{
	
	/**
	* Configure CacheBox for ColdBox Application Operation
	*/
	function configure(){
		
		// The CacheBox configuration structure DSL
		cacheBox = {
			// LogBox config already in coldbox app, not needed
			// logBoxConfig = "coldbox.system.web.config.LogBox", 
			
			// The defaultCache has an implicit name "default" which is a reserved cache name
			// It also has a default provider of cachebox which cannot be changed.
			// All timeouts are in minutes
			defaultCache = {
				objectDefaultTimeout = 120, //two hours default
				objectDefaultLastAccessTimeout = 30, //30 minutes idle time
				useLastAccessTimeouts = true,
				reapFrequency = 2,
				freeMemoryPercentageThreshold = 0,
				evictionPolicy = "LRU",
				evictCount = 1,
				maxObjects = 300,
				objectStore = "ConcurrentStore", //guaranteed objects
				coldboxEnabled = true
			},
			
			// Register all the custom named caches you like here
			caches = {
				// Named cache for all coldbox event and view template caching
				couchbase = {
					"provider" 		: "/couchbase-cachebox-provider.models.CouchbaseProvider",
					"properties"	: {
						objectDefaultTimeout    : 120,
						ignoreCouchbaseTimeouts : true,
						bucket                  : "default",
						servers					: "127.0.0.1:8091",
						username				: "cfcouchbase",
						password				: "password"
					}
				}		
			}		
		};
	}	

}