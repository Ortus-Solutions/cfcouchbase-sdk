/**
********************************************************************************
* Copyright Since 2005 Ortus Solutions, Corp
* www.coldbox.org | www.luismajano.com | www.ortussolutions.com | www.gocontentbox.org
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in
* all copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
* FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALING
* IN THE SOFTWARE.
********************************************************************************
* @author Luis Majano, Brad Wood
* This is the main Couchbase client object
*/
component serializable="false" accessors="true"{

	/**
	* The version of this library
	*/
	property name="version";
	/** 
	* The version of the Couchbase SDK
	*/
	property name="SDKVersion";
	/**
	* The unique ID of this SDK
	*/
	property name="libID";
	/**
	* The UUID Helper
	*/
	property name="uuidHelper";
	/** 
	* The java CouchbaseClient object
	*/
	property name="couchbaseClient";
	/**
	*The couchbase configuration object
	*/
	property name="couchbaseConfig";
	/**
	* The SDK utility class
	*/
	property name="util";
	
	/**
	* Constructor
	* This creates a connection to a Couchbase server using the passed in config argument, which can be a struct literal of options, a path to a config object
	* or an instance of a cfcouchbase.config.CouchbaseConfig object.  For all the possible config settings, look at the CouchbaseConfig object.
	* @config.hint The configuration structure, config object or path to a config object.
	*/
	CouchbaseClient function init( any config={} ){

		/****************** Setup SDK dependencies & properties ******************/

		// The version of the client and sdk
		variables.version 		= "1.0.0.@build.number@";
		variables.SDKVersion 	= "1.2";
		// The unique version of this client
		variables.libID	= createObject('java','java.lang.System').identityHashCode( this );
		// lib path
		variables.libPath = getDirectoryFromPath( getMetadata( this ).path ) & "lib";
		// setup class loader ID
		variables.javaLoaderID = "cfcouchbase-#variables.version#-classloader";
		// our UUID creation helper
		variables.UUIDHelper = createobject("java", "java.util.UUID");
		// Java Time Units
		variables.timeUnitClass = createObject("java", "java.util.concurrent.TimeUnit");
		// SDK Utility class
		variables.util = new util.Utility();
		// validate configuration
		variables.couchbaseConfig = validateConfig( arguments.config );

		// Load up javaLoader with Couchbase SDK
		if( variables.couchbaseConfig.getUseClassloader() )
			loadSDK();

		// LOAD ENUMS
		this.persistTo 		= getJava( "net.spy.memcached.PersistTo" );
		this.replicateTo 	= getJava( "net.spy.memcached.ReplicateTo" );
		
		// Build the connection factory and client
		variables.couchbaseClient = buildCouchbaseClient( variables.couchbaseConfig );

		return this;
	}

	/************************* COUCHBASE SDK METHODS ***********************************/

	/**
	* Set a value with durability options. It is asyncronouse by default so it returns immediatley without waiting for the actual set to complete.  Call future.set()
	* if you need to confirm the document has been set.  Even then, the document is only guarunteed to be in memory on a single node.  To force the document to be replicated 
	* to additional nodes, pass the replicateTo argument.  A value of ReplicateTo.TWO ensures the document is copied to at least two replica nodes, etc.  (This assumes you have replicas enabled)   
	* To force the document to be perisited to disk, passing in PersistTo.ONE ensures it is stored on disk in a single node.  PersistTo.TWO ensures 2 nodes, etc. 
	* A PersistTo.TWO durability setting implies a replication to at least one node.
	* This function returns a Java OperationFuture object (net.spy.memcached.internal.OperationFuture<T>) or void (null) if a timeout exception occurs.
	* @key.hint The unique id of the document to store
	* @value.hint The value to store
	* @timeout.hint The expiration of the document in minutes, by default it is 0, so it lives forever
	* @persistTo.hint The number of nodes that need to store the document to disk before this call returns.  Default is 0.
	* @replicateTo.hint The number of nodes to replicate the document to before this call returns.  Default is 0.
	*/ 
	any function set( 
		required string key, 
		required any value, 
		numeric timeout=0, 
		numeric persistTo, 
		numeric replicateTo
	){

		// serialization determinations go here

		// store it
		try{

			// default persist and replicate
			if( !structKeyExists( arguments, "persistTo" ) ){ arguments.persistTo = this.persistTo.MASTER; }
			if( !structKeyExists( arguments, "replicateTo" ) ){ arguments.replicateTo = this.replicateTo.ZERO; }

			// with replicate and persist
			var future = variables.couchbaseClient.set( arguments.key, 
														javaCast( "int", arguments.timeout*60 ), 
														arguments.value, 
														arguments.persistTo, 
														arguments.replicateTo );

			return future;
		}
		catch( any e ) {
			if( variables.util.isTimeoutException( e ) && variables.couchbaseConfig.getIgnoreTimeouts() ) {
				// returns void
				return;
			}
			// For any other type of exception, rethrow.
			rethrow;
		}
	}
	
	/**
	* This method is the same as Set(), except the future that is returned will return true if the key being set doesn't already exist.  
	* The future will return false if the item being set does already exist.  It will not throw an error if the key already exists, you must check the future. 
	* This function returns a Java OperationFuture object (net.spy.memcached.internal.OperationFuture<Boolean>) or void (null) if a timeout exception occurs.
	* @key.hint
	* @value.hint
	* @timeout.hint The expiration of the document in minutes, by default it is 0, so it lives forever
	* @persistTo.hint The number of nodes that need to store the document to disk before this call returns.  Default is 0.
	* @replicateTo.hint The number of nodes to replicate the document to before this call returns.  Default is 0.
	*/ 
	any function add( 
		required string key, 
		required any value, 
		numeric timeout=0, 
		numeric persistTo, 
		numeric replicateTo
	){

		// serialization determinations go here

		// store it
		try{

			// default persist and replicate
			if( !structKeyExists( arguments, "persistTo" ) ){ arguments.persistTo = this.persistTo.MASTER; }
			if( !structKeyExists( arguments, "replicateTo" ) ){ arguments.replicateTo = this.replicateTo.ZERO; }

			// with replicate and persist
			var future = variables.couchbaseClient.add( arguments.key, 
														javaCast( "int", arguments.timeout*60 ), 
														arguments.value, 
														arguments.persistTo, 
														arguments.replicateTo );

			return future;
		}
		catch( any e ) {
			if( variables.util.isTimeoutException( e ) && variables.couchbaseConfig.getIgnoreTimeouts() ) {
				// returns void
				return;
			}
			// For any other type of exception, rethrow.
			rethrow;
		}
	}
	
	
	
	
	
	/**
	* Set multiple documents in the cache with a single operation.  Pass in a struct of documents to set where the keys of the struct are the document IDs.
	* The values in the struct are the values being set.  All documents share the same timout, persistTo, and replicateTo settings.
	* This function returns a struct of keys with each of the future objects from the set operations.  There will be no future object if a timeout occurs.
	* @data.hint A struct (key/value pair) of documents to set into Couchbase.
	* @timeout.hint The expiration of the documents in minutes.
	* @persistTo.hint The number of nodes that need to store the document to disk before this call returns.  Default is 0.
	* @replicateTo.hint The number of nodes to replicate the document to before this call returns.  Default is 0.
	*/ 
	any function setMulti( 
		required struct data,
		numeric timeout=0, 
		numeric persistTo, 
		numeric replicateTo
	){
		
		var results = {};
		var key = '';
		
		// Loop over incoming key/value pairs
		for( local.key in arguments.data ) {
			
			// Set each one
			var future = set(
				local.key,
				arguments.data[local.key],
				arguments.timeout,
				arguments.persistTo, 
				arguments.replicateTo
			);
			
			// Insert the future object into our result object
			results[local.key] = future;
		}
	
		// Return the struct of futures.
		return results;
	}
	
	
	/**
	* Get an object from couchbase, returns null if not found.
	* @key The ID of the document to retrieve.
	*/
	any function get( required string key ){
		try {
			var results = variables.couchbaseClient.get( arguments.key );

			if( !isNull( results ) ){
				// deserializations go here.

				return results;
			}
		}
		catch( any e ){
			if( variables.util.isTimeoutException( e ) && variables.couchbaseConfig.getIgnoreTimeouts() ) {
				// returns void
				return;
			}
			// For any other type of exception, rethrow.
			rethrow;
		}
	}

	/**
	* Shutdown the native client connection
	* TODO: add timeouts
	*/
	CouchbaseClient function shutdown(){
		//variables.couchbaseClient.shutdown();
		return this;
	}

	/**
	* Flush all caches from all servers with a delay of application. Returns a future object
	* @delay.hint The period of time to delay, in seconds
	*/
	any function flush( numeric delay=0 ){
		return variables.couchbaseClient.flush( javaCast( "int", arguments.delay ) );
	}

	/************************* JAVA INTEGRATION ***********************************/

	/**
    * Get the java loader instance
    */
    any function getJavaLoader() {
    	if( ! structKeyExists( server, variables.javaLoaderID ) ){ loadSDK(); }
		return server[ variables.javaLoaderID ];
	}

	/**
    * Get an instance of a java class
    * @className.hint The class to get
    */
    any function getJava( required className ) {
    	return ( variables.couchbaseConfig.getUseClassloader() ? getJavaLoader().create( arguments.className ) : createObject( "java", arguments.className ) );
	}
	
	/************************* PRIVATE ***********************************/

	/**
	* Buid a couchbase connection client according to config and returns the raw java connection client object
	*/
	private any function buildCouchbaseClient( required cfcouchbase.config.CouchbaseConfig config ){
		// get config options
		var configData = arguments.config.getMemento();
		// cleanup server URIs and build java URI classes
		var serverURIs = variables.util.buildServerURIs( configData.servers );

		// Create a connection factory builder
		factoryBuilder = getJava( "com.couchbase.client.CouchbaseConnectionFactoryBuilder" ).init();
		
		// Set options
        factoryBuilder.setOpTimeout( javaCast( "long", configData.opTimeout ) )
			.setOpQueueMaxBlockTime( javaCast( "long", configData.opQueueMaxBlockTime ) )
        	.setTimeoutExceptionThreshold( javaCast( "int", configData.timeoutExceptionThreshold ) )
        	.setReadBufferSize( javaCast( "int", configData.readBufferSize ) )
        	.setShouldOptimize( javaCast( "boolean", configData.shouldOptimize ) )
        	.setMaxReconnectDelay( javaCast( "long", configData.maxReconnectDelay ) )
        	.setObsPollInterval( javaCast( "long", configData.obsPollInterval ) )
        	.setObsPollMax( javaCast( "int", configData.obsPollMax ) )
        	.setViewTimeout( javaCast( "int", configData.viewTimeout ) );
        
        // Build our connection factory with the defaults we set above
		var cf = factoryBuilder.buildCouchbaseConnection( serverURIs, configData.bucketName, configData.password );
		
		// build out the connection
		return getJava( "com.couchbase.client.CouchbaseClient" ).init( cf );
	}

	/**
	* Standardize and validate configuration object
	* @config.hint The config options as a struct, path or instance.
	*/
	private cfcouchbase.config.CouchbaseConfig function validateConfig( required any config ){
		var oConfig = "";

		// check if its a struct of config options
		if( isStruct( arguments.config ) ){
			// init config object with memento
			return new config.CouchbaseConfig( argumentCollection=arguments.config );
		}

		// do we have a path?
		if( isSimpleValue( arguments.config ) ){
			// build out cfc and use it
			oConfig = new "#arguments.config#"();
		}

		// do we have a CFC instance just return it
		return oConfig;

	}

	/**
	* Get the lib information as an array
	*/
	private array function getLibJars(){
		return directoryList( variables.libPath, false, "path" );
	}

	/**
	* Load JavaLoader with the SDK
	*/
	private function loadSDK(){
		try{

			// verify if not in server scope
			if( ! structKeyExists( server, variables.javaLoaderID ) ){
				lock name="#variables.javaLoaderID#" throwOnTimeout="true" timeout="15" type="exclusive"{
					if( ! structKeyExists( server, variables.javaLoaderID ) ){
						// Create and load
						server[ variables.javaLoaderID ] = new util.javaloader.JavaLoader( loadPaths=getLibJars() );
					}
				} 
			} // end if static server check

		}
		catch( Any e ){
			e.printStackTrace();
			throw( message='Error Loading Couchbase Client Jars: #e.message# #e.detail#', detail=e.stacktrace );
		}
	}

}
