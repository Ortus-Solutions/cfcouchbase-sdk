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

	// Location of the library SDK
	property name="libPath";
	// The unique ID of the class loader
	property name="javaLoaderID";
	// The version of this library
	property name="version";
	// The version of the Couchbase SDK
	property name="SDKVersion";
	// The unique ID of this SDK
	property name="libID";
	// The UUID Helper
	property name="uuidHelper";
	// The java CouchbaseClient object
	property name="couchbaseClient";
	// The SDK utility class
	property name="util";
	// Bit that determines if we are class loading or not
	property name="useClassloader";
	// Bit that determines if the sdk ignores couchbase timeouts
	property name="ignoreTimeouts";
	// The couchbase configuration object
	property name="couchbaseConfig";

	/**
	* Constructor
	* Get a CouchbaseClient based on the initial server list provided. This constructor should be used if the bucket name is the same as the username 
	* (which is normally the case). If your bucket does not have a password (likely the "default" bucket), use an empty string instead. This method is only a 
	* convenience method so you don't have to create a CouchbaseConnectionFactory for yourself.
	* @config.hint The configuration structure or a configuration object or path to a configuration object for a connection. Valid struct elements are: servers, bucketName, password
	* @bucketname.hint The bucket name in the cluster you wish to use
	* @password.hint The password for the bucket
	* @connectionFactory.hint The ConnectionFactory to use to create connections
	* @useClassLoader.hint By default we class load all required java libraries, if you set this to false, that means the lib folder of this SDK will be added to the servlet container's lib path manually.
	* @ignoreTimeouts.hint Bit that determines if we should ignore Couchbase connection timeouts or throw exceptions, default is to ignore.
	*/
	CouchbaseClient function init( 
		any config={},
		boolean useClassloader=true,
		boolean ignoreTimeouts=true
	){

		/****************** Setup SDK dependencies & properties ******************/

		// The version of the client and sdk
		variables.version 		= "1.0.0.@build.number@";
		variables.SDKVersion 	= "1.2";
		// The unique version of this client
		variables.libID	= createObject('java','java.lang.System').identityHashCode( this );
		// lib path
		variables.libPath = getDirectoryFromPath( getMetadata( this ).path ) & "lib";
		// setup class loader ID
		variables.javaLoaderID = "cfcouchbase-#variables.version#-loader-#variables.libID#";
		// our UUID creation helper
		variables.UUIDHelper = createobject("java", "java.util.UUID");
		// Java URI class
		variables.URIClass	= createObject("java", "java.net.URI");
		// Java Time Units
		variables.timeUnitClass = createObject("java", "java.util.concurrent.TimeUnit");
		// SDK Utility class
		variables.util = new util.Utility();
		// Loading via JavaLoder?
		variables.useClassLoader = arguments.useClassloader;
		// Timeout bits
		variables.ignoreTimeouts = arguments.ignoreTimeouts;
		
		/****************** Load up the SDK ******************/

		// Load up javaLoader with Couchbase SDK
		if( variables.useClassloader )
			loadSDK();

		// LOAD ENUMS
		this.persistTo 		= getJava( "net.spy.memcached.PersistTo" );
		this.replicateTo 	= getJava( "net.spy.memcached.ReplicateTo" );

		// validate configuration
		variables.couchbaseConfig = validateConfig( arguments.config );

		// Build the connection factory and client
		variables.couchbaseClient = buildCouchbaseClient( variables.couchbaseConfig );

		return this;
	}

	/**
	* Set a value with durability options. This is a shorthand method so that you only need to provide a PersistTo value if you don't care if the value is already replicated. 
	* A PersistTo.TWO durability setting implies a replication to at least one node.
	* This function returns a Java OperationFuture object (net.spy.memcached.internal.OperationFuture<T>) or void (null) if a timeout exception occurs.
	* @key.hint
	* @value.hint
	* @exp.hint The expiration of the document in minutes, by default it is 0, so it lives forever
	* @persistTo.hint
	* @replciateTo.hint
	*/ 
	any function set( 
		required string key, 
		required any value, 
		numeric exp=0, 
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
														javaCast( "int", arguments.exp*60 ), 
														arguments.value, 
														arguments.persistTo, 
														arguments.replicateTo );

			return future;
		}
		catch( any e ) {
			if( variables.util.isTimeoutException( e ) && variables.ignoreTimeouts ) {
				// returns void
				return;
			}
			// For any other type of exception, rethrow.
			rethrow;
		}
	}

	/**
	* Get an object from couchbase, returns null if not found.
	* @key
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
			if( variables.util.isTimeoutException( e ) && variables.ignoreTimeouts ) {
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
    * Get the java loader instances
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
    	return ( variables.useClassLoader ? getJavaLoader().create( arguments.className ) : createObject( "java", arguments.className ) );
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
        	.setViewTimeout( javaCast( "int", configData.viewTimeout ) )
        
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
			writeDump( oConfig.getMemento() );abort;
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

	/**
    * Format the incoming simple couchbase server URL location strings into our format, this allows for 
    * declaring simple URLs like 127.0.0.1:8091
    */
    private array function formatServers( required servers ) {
    	var i = 0;
    	
		if( !isArray( arguments.servers ) ){
			servers = listToArray( arguments.servers );
		}
				
		// Massage server URLs to be "PROTOCOL://host:port/pools/"
		while( ++i <= arrayLen( arguments.servers ) ){
			
			// Add protocol if neccessary
			if( !findNoCase( "http", arguments.servers[ i ] ) ){
				arguments.servers[ i ] = "http://" & arguments.servers[ i ];
			}
			
			// Strip trailing slash via regex, its fast
			arguments.servers[ i ] = reReplace( arguments.servers[ i ], "/$", "");
			
			// Add directory
			if( right( arguments.servers[ i ], 6 ) != '/pools' ){
				arguments.servers[ i ] &= '/pools';
			}
			
		} // end server loop
		
		return arguments.servers;
	}

}
