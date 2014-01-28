/**
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
	* The data marshaller to use for serializations and deserializations
	*/
	property name="dataMarshaller" type="cfcouchbase.data.IDataMarshaller";
	
	/**
	* Constructor
	* This creates a connection to a Couchbase server using the passed in config argument, which can be a struct literal of options, a path to a config object
	* or an instance of a cfcouchbase.config.CouchbaseConfig object.  For all the possible config settings, look at the CouchbaseConfig object.
	* 
	* @config.hint The configuration structure, config object or path to a config object.
	* 
	* @return A reference to "this" CFC
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
		variables.timeUnit = createObject("java", "java.util.concurrent.TimeUnit");
		// SDK Utility class
		variables.util = new util.Utility();
		// Query Helper Utility
		variables.queryHelper = new util.QueryHelper( this );
		// validate configuration
		variables.couchbaseConfig = validateConfig( arguments.config );

		// Load up javaLoader with Couchbase SDK
		if( variables.couchbaseConfig.getUseClassloader() )
			loadSDK();

		// LOAD ENUMS
		this.persistTo 		= newJava( "net.spy.memcached.PersistTo" );
		this.replicateTo 	= newJava( "net.spy.memcached.ReplicateTo" );
		
		// Build the connection factory and client
		variables.couchbaseClient = buildCouchbaseClient( variables.couchbaseConfig );
		// Build the data marshaler
		variables.dataMarshaller = buildDataMarshaller( variables.couchbaseConfig ).setCouchbaseClient( this );
		
		return this;
	}

	/************************* COUCHBASE SDK METHODS ***********************************/

	/**
	* Set a value with durability options. It is asyncronouse by default so it returns immediatley without waiting for the actual set to complete.  Call future.set()
	* if you need to confirm the document has been set.  Even then, the document is only guarunteed to be in memory on a single node.  To force the document to be replicated 
	* to additional nodes, pass the replicateTo argument.  A value of ReplicateTo.TWO ensures the document is copied to at least two replica nodes, etc.  (This assumes you have replicas enabled)   
	* To force the document to be perisited to disk, passing in PersistTo.ONE ensures it is stored on disk in a single node.  PersistTo.TWO ensures 2 nodes, etc. 
	* A PersistTo.TWO durability setting implies a replication to at least one node.
	* 
	* <pre>
	* person = { name: "Brad", age: 33, hair: "red" };
	* future = client.set( 'brad', person );
	* </pre>
	* 
	* @ID.hint The unique id of the document to store
	* @value.hint The value to store
	* @timeout.hint The expiration of the document in minutes, by default it is 0, so it lives forever
	* @persistTo.hint The number of nodes that need to store the document to disk before this call returns.  Valid options are [ ZERO, MASTER, ONE, TWO, THREE, FOUR ]
	* @replicateTo.hint The number of nodes to replicate the document to before this call returns.  Valid options are [ ZERO, ONE, TWO, THREE ]
	* 
	* @return A Java OperationFuture object (net.spy.memcached.internal.OperationFuture<T>) or void (null) if a timeout exception occurs.
	*/ 
	any function set( 
		required string ID, 
		required any value, 
		numeric timeout, 
		string persistTo, 
		string replicateTo
	){
		arguments.ID = variables.util.normalizeID( arguments.ID );
		// serialization determinations go here

		// default persist and replicate
		defaultPersistReplicate( arguments );
		// default timeouts
		arguments.timeout 	= ( !structKeyExists( arguments, "timeout" ) ? variables.couchbaseConfig.getDefaultTimeout() : arguments.timeout );
		// with replicate and persist
		return variables.couchbaseClient.set( arguments.ID, 
													javaCast( "int", arguments.timeout*60 ), 
													serializeData( arguments.value ), 
													arguments.persistTo, 
													arguments.replicateTo );

	}
	
	/**
	* Update the value of an existing document with a CAS value.  CAS is retrieved via getWithCAS().  Since the CAS value changes every time a document is modified
	* you will be able to tell if another process has modified the document between the time you retrieved it and updated it.  This method will only complete
	* successfully if the original document value is unchanged.  This method is not asyncronous and therefore does not return a future since your application code
	* will need to check the return and handle it appropriatley.
	* 
	* <pre>
	* person = { name: "Brad", age: 33, hair: "red" };
	* result = client.setWithCAS( 'brad', person, CAS );
	* </pre>
	* 
	* @ID.hint The unique id of the document to store
	* @value.hint The value to store
	* @CAS.hint CAS value retrieved via getWithCAS()
	* @timeout.hint The expiration of the document in minutes, by default it is 0, so it lives forever
	* @persistTo.hint The number of nodes that need to store the document to disk before this call returns.  Valid options are [ ZERO, MASTER, ONE, TWO, THREE, FOUR ]
	* @replicateTo.hint The number of nodes to replicate the document to before this call returns.  Valid options are [ ZERO, ONE, TWO, THREE ]
	* 
	* @return A struct with a status and detail key.  Status will be true if the document was succesfully updated.  If status is false, that means nothing happened on the server and you need to re-issue a command to store your document.  When status is false, check the detail.  A value of "CAS_CHANGED" indicates that anothe rprocess has updated the document and your version is out-of-date.  You will need to retrieve the document again with getWithCAS() and attempt your setWithCAS again.  If status is false and details is "NOT_FOUND", that means a document with that ID was not found.  You can then issue an add() or a regular set() commend to store the document. 
	*/ 
	any function setWithCAS( 
		required string ID, 
		required any value, 
		required string CAS,
		numeric timeout, 
		string persistTo, 
		string replicateTo
	){


		// default persist and replicate
		defaultPersistReplicate( arguments );
		// default timeouts
		arguments.timeout = ( !structKeyExists( arguments, "timeout" ) ? variables.couchbaseConfig.getDefaultTimeout() : arguments.timeout );
		
		// with replicate and persist
		var result = {};
		// Hope for the best
		result.status = true;
		result.detail = "SUCCESS";
		var CASResponse = variables.couchbaseClient.cas( arguments.ID,
													javaCast( "long", arguments.CAS ),			 											
													javaCast( "int", arguments.timeout*60 ), 
													serializeData( arguments.value ), 
													arguments.persistTo, 
													arguments.replicateTo );
													
		// Account for the worst
		if( CASResponse.equals(CASResponse.EXISTS) ) {
			result.status = false;
			result.detail = "CAS_CHANGED";				
		} else if( CASResponse.equals(CASResponse.NOT_FOUND) ) {
			result.status = false;
			result.detail = "NOT_FOUND";
		}
		
		return result;
		
	}
	
	/**
	* This method is the same as set(), except the future that is returned will return true if the ID being set doesn't already exist.  
	* The future will return false if the item being set does already exist.  It will not throw an error if the ID already exists, you must check the future.
	* 
	* <pre>
	* person = { name: "Brad", age: 33, hair: "red" };
	* future = client.add( 'brad', person );
	* </pre>
	* 
	* @ID.hint
	* @value.hint
	* @timeout.hint The expiration of the document in minutes, by default it is 0, so it lives forever
	* @persistTo.hint The number of nodes that need to store the document to disk before this call returns.  Valid options are [ ZERO, MASTER, ONE, TWO, THREE, FOUR ]
	* @replicateTo.hint The number of nodes to replicate the document to before this call returns.  Valid options are [ ZERO, ONE, TWO, THREE ]
	* 
	* @return A Java OperationFuture object (net.spy.memcached.internal.OperationFuture<Boolean>) or void (null) if a timeout exception occurs.
	*/ 
	any function add( 
		required string ID, 
		required any value, 
		numeric timeout, 
		string persistTo, 
		string replicateTo
	){
		arguments.ID = variables.util.normalizeID( arguments.ID );
		
		// serialization determinations go here

		// default persist and replicate
		defaultPersistReplicate( arguments );
		// default timeouts
		arguments.timeout = ( !structKeyExists( arguments, "timeout" ) ? variables.couchbaseConfig.getDefaultTimeout() : arguments.timeout );
		
		// with replicate and persist
		return variables.couchbaseClient.add( arguments.ID, 
													javaCast( "int", arguments.timeout*60 ), 
													arguments.value, 
													arguments.persistTo, 
													arguments.replicateTo );

	}
	
	/**
	* Set multiple documents in the cache with a single operation.  Pass in a struct of documents to set where the IDs of the struct are the document IDs.
	* The values in the struct are the values being set.  All documents share the same timout, persistTo, and replicateTo settings.
	* 
	* <pre>
	* data = {
	* &nbsp;&nbsp;brad = { name: "Brad", age: 33, hair: "red" },
	* &nbsp;&nbsp;luis = { name: "Luis", age: 35, hair: "black" },
	* &nbsp;&nbsp;bill = { name: "Bill", age: 21, hair: "blond" }
	* };
	* future = client.setMulti( data );
	* </pre>
	* 
	* @data.hint A struct (key/value pair) of documents to set into Couchbase.
	* @timeout.hint The expiration of the documents in minutes.
	* @persistTo.hint The number of nodes that need to store the document to disk before this call returns.  Valid options are [ ZERO, MASTER, ONE, TWO, THREE, FOUR ]
	* @replicateTo.hint The number of nodes to replicate the document to before this call returns.  Valid options are [ ZERO, ONE, TWO, THREE ]
	* 
	* @return A struct of IDs with each of the future objects from the set operations.  There will be no future object if a timeout occurs.
	*/ 
	any function setMulti( 
		required struct data,
		numeric timeout, 
		string persistTo, 
		string replicateTo
	){
		
		var results = {};
		
		// default persist and replicate
		defaultPersistReplicate( arguments );
		// default timeouts
		arguments.timeout = ( !structKeyExists( arguments, "timeout" ) ? variables.couchbaseConfig.getDefaultTimeout() : arguments.timeout );

		// Loop over incoming key/value pairs
		for( var local.ID in arguments.data ) {
			
			// Set each one
			var future = set(
				id=local.ID,
				value= serializeData( arguments.data[ local.ID ] ),
				timeout=arguments.timeout,
				persistTo=arguments.persistTo, 
				replicateTo=arguments.replicateTo
			);
			
			// Insert the future object into our result object
			results[ local.ID ] = future;
		}
	
		// Return the struct of futures.
		return results;
	}
	
	
	
	/**
	* This method will set a value only if that ID already exists in Couchbase.  If the document ID doesn't exist, it will do nothing.
	* 
	* <pre>
	* person = { name: "Brad", age: 33, hair: "red" };
	* future = client.replace( 'brad', person );
	* future.get();
	* </pre>
	* 
	* @ID The ID of the document to replace.
	* @value.hint The value of the document to replace
	* @timeout.hint The expiration of the document in minutes, by default it is 0, so it lives forever
	* @persistTo.hint The number of nodes that need to store the document to disk before this call returns.  Valid options are [ ZERO, MASTER, ONE, TWO, THREE, FOUR ]
	* @replicateTo.hint The number of nodes to replicate the document to before this call returns.  Valid options are [ ZERO, ONE, TWO, THREE ]
	* 
	* @return A Java OperationFuture object (net.spy.memcached.internal.OperationFuture<Boolean>) or void (null) if a timeout exception occurs. future.get() will return true if the replace was successfull, and will return false if the ID didn't already exist to replace.
	*/ 
	any function replace( 
		required string ID, 
		required any value, 
		numeric timeout,
		string persistTo, 
		string replicateTo
	){
		arguments.ID = variables.util.normalizeID( arguments.ID );
		
		// default persist and replicate
		defaultPersistReplicate( arguments );
		// default timeouts
		arguments.timeout = ( !structKeyExists( arguments, "timeout" ) ? variables.couchbaseConfig.getDefaultTimeout() : arguments.timeout );
		// store it
		return variables.couchbaseClient.replace( arguments.ID, 
														javaCast( "int", arguments.timeout*60 ), 
														arguments.value,
														arguments.persistTo,
														arguments.replicateTo );

	}
	
	/**
	* Get an object from couchbase by the ID.  This method will deserialize object automatically and optionally inflate the data into a CFC.
	* 
	* <pre>
	* person = client.get( 'brad' );
	* </pre>
	* 
	* @ID.hint The ID of the document to retrieve.
	* @deserialize.hint Deserialize the JSON automatically for you and return the representation
	* @inflateTo.hint The object that will be used to inflate the data with according to our conventions
	* 
	* @return The object if found, null otherwise.
	*/
	any function get( required string ID, boolean deserialize=true, any inflateTo="" ){
		arguments.ID = variables.util.normalizeID( arguments.ID );
		
		var results = variables.couchbaseClient.get( arguments.ID );

		if( !isNull( results ) ){
			// deserializations go here.
			return deserializeData( results, arguments.inflateTo, arguments.deserialize );
		}
	}

	/**
	* Get an object from couchbase asynchronously.
	* 
	* <pre>
	* future = client.asyncGet( 'brad' );
	* future.get();
	* </pre>
	* 
	* @ID.hint The ID of the document to retrieve.
	* 
	* @return A Java Future object. (net.spy.memcached.internal.GetFuture)
	*/
	any function asyncGet( required string ID ){
		arguments.ID = variables.util.normalizeID( arguments.ID );
		// no inflation or deserialization as it is async.
		return variables.couchbaseClient.asyncGet( arguments.ID );
	}
	
	/**
	* Get multiple objects from couchbase.
	* 
	* <pre>
	* results = client.getMulti( ['brad', 'luis', 'bill'] );
	* </pre>
	* 
	* @ID.hint An array of document IDs to retrieve.
	* @deserialize.hint Deserialize the JSON automatically for you and return the representation
	* @inflateTo.hint The object that will be used to inflate the data with according to our conventions
	* 
	* @return A struct of values.  Any document IDs not found will not exist in the struct.
	*/
	any function getMulti( required array ID, boolean deserialize=true, any inflateTo="" ){
		arguments.ID = variables.util.normalizeID( arguments.ID );
		
		var result = {};
		// Java method expects a java.util.Collection
		var map = variables.couchbaseClient.getBulk( arguments.ID );
		for( var key in map ) {
			var value = map[ key ];
			// deserializations go here.
			result[ key ] = deserializeData( value, arguments.inflateTo, arguments.deserialize );	
		}
		return result;
	}

	/**
	* Get multiple objects from couchbase asynchronously.  
	* 
	* <pre>
	* buldFuture = client.asyncGetMulti( ['brad', 'luis', 'bill'] );
	* </pre>
	* 
	* @ID.hint An array of document IDs to retrieve.
	* 
	* @return A bulk Java Future. (net.spy.memcached.internal.BulkFuture)  Any document IDs not found will not exist in the future object.
	*/
	any function asyncGetMulti( required array ID ){
		arguments.ID = variables.util.normalizeID( arguments.ID );
		// Java method expects a java.util.Collection
		return variables.couchbaseClient.asyncGetBulk( arguments.ID );
	}
	
	/**
	* Get an object from couchbase with its CAS value, returns null if not found.  This method is meant to be used in conjunction with setWithCAS to be able to 
	* update a document while making sure another process hasn't modified it in the meantime.  The CAS value changes every time the document is updated. 
	* 
	* <pre>
	* result = client.getWithCAS( 'brad' );
	* writeOutput(result.cas);
	* writeOutput(result.value);
	* </pre>
	* 
	* @ID.hint The ID of the document to retrieve.
	* @deserialize.hint Deserialize the JSON automatically for you and return the representation
	* @inflateTo.hint The object that will be used to inflate the data with according to our conventions
	* 
	* @return A struct with "CAS" and "value" keys.  If the ID doesn't exist, this method will return null.
	*/
	any function getWithCAS( required string ID, boolean deserialize=true, any inflateTo="" ){
		arguments.ID = variables.util.normalizeID( arguments.ID );
		
		var resultsWithCAS = variables.couchbaseClient.gets( arguments.ID );

		if( !isNull( resultsWithCAS ) ){
			// build struct out.
			var result = {
				cas 	= resultsWithCAS.getCAS(),
				value 	= deserializeData( resultsWithCAS.getValue(), arguments.inflateTo, arguments.deserialize )
			};

			return result;
		}
	}

	/**
	* Gets (with CAS support) the given key asynchronously.  This method is meant to be used in conjunction with setWithCAS to be able to 
	* update a document while making sure another process hasn't modified it in the meantime.  The CAS value changes every time the document is updated.
	* 
	* <pre>
	* future = client.asyncGetWithCAS( 'brad' );
	* </pre>
	* 
	* @ID.hint The ID of the document to retrieve.
	* 
	* @return A Java Future. (net.spy.memcached.internal.OperationFuture) The future has methods that will return the "CAS" and "value" keys.
	*/
	any function asyncGetWithCAS( required string ID ){
		arguments.ID = variables.util.normalizeID( arguments.ID );
		
		return variables.couchbaseClient.asyncGets( arguments.ID );			
	}
	
	/**
	* Obtain a value for a given ID and update the expiry time for the document at the same time.  This is useful for a sort of "last access timeout" 
	* functionality where you don't want a document to timeout while it is still being accessed.
	* 
	* <pre>
	* result = client.getAndTouch( 'brad' );
	* writeOutput(result.cas);
	* writeOutput(result.value);
	* </pre>
	* 
	* @ID.hint The ID of the document to retrieve.
	* @timeout.hint The expiration of the document in minutes
	* @deserialize.hint Deserialize the JSON automatically for you and return the representation
	* @inflateTo.hint The object that will be used to inflate the data with according to our conventions
	* 
	* @return A struct with "CAS" and "value" keys.  If the ID doesn't exist, this method will return null.
	*/
	any function getAndTouch(
					required string ID,
					required numeric timeout,
					boolean deserialize=true,
					any inflateTo=""
				 ){		 	 
		arguments.ID = variables.util.normalizeID( arguments.ID );
		
		var resultsWithCAS = variables.couchbaseClient.getAndTouch(
														arguments.ID,
														javaCast( "int", arguments.timeout*60 )
													   );

		if( !isNull( resultsWithCAS ) ){
			// build struct out.
			var result = {
				cas 	= resultsWithCAS.getCAS(),
				value 	= deserializeData( resultsWithCAS.getValue(), arguments.inflateTo, arguments.deserialize )
			};

			return result;
		}
	}

	/**
	* Obtain a value for a given ID and update the expiry time for the document at the same time.  This is useful for a sort of "last access timeout" 
	* functionality where you don't want a document to timeout while it is still being accessed.
	* 
	* <pre>
	* future = client.asyncGetAndTouch( 'brad' );
	* </pre>
	* 
	* @ID.hint The ID of the document to retrieve.
	* @timeout.hint The expiration of the document in minutes
	* 
	* @return A Future object (net.spy.memcached.internal.OperationFuture) that retrieves a CASValue class that you can use to get the value and cas of the object.
	*/
	any function asyncGetAndTouch(
					required string ID,
					required numeric timeout
	){		 	 
		
		arguments.ID = variables.util.normalizeID( arguments.ID );
		return variables.couchbaseClient.asyncGetAndTouch( arguments.ID, javaCast( "int", arguments.timeout*60 ) );
	}

	/**
	* Shutdown the native client connection
	* 
	* <pre>
	* client.shutdown( 10 );
	* </pre>
	* 
	* @timeout.hint The timeout in seconds, we default to 10 seconds
	* 
	* @return A refernce to "this" CFC
	*/
	CouchbaseClient function shutdown( numeric timeout=10 ){
		variables.couchbaseClient.shutdown( javaCast( "int", arguments.timeout ), variables.timeUnit.SECONDS );
		return this;
	}

	/**
	* Flush all caches from all servers with a delay of application.
	* 
	* <pre>
	* client.flush( 5 );
	* </pre>
	* 
	* @delay.hint The period of time to delay, in seconds
	* 
	* @return A Java future object. (net.spy.memcached.internal.OperationFuture)
	*/
	any function flush( numeric delay=0 ){
		return variables.couchbaseClient.flush( javaCast( "int", arguments.delay ) );
	}

	/**
	* Get all of the stats from all of the servers in the cluster.
	* Information on stats available here: http://www.couchbase.com/docs/couchbase-manual-1.8/cbstats-all-bucket-info.html
	* 
	* <pre>
	* clusterStats = client.getStats();
	* </pre>
	* 
	* @return A struct containing a key for each server in the cluster.  The value for each server is a Java Map of stats.  
	*/
	any function getStats(){
		var stats = variables.couchbaseClient.getStats();
		var entrySetIterator = stats.entrySet().iterator();		
		var results = {};
		var entrySet = '';
				
		// Convert from a Map keyed by java.net.InetSocketAddress objects, 
		// to a CFML struct keyed by the string representation of each server
		// For some reason Map.get() is returning null, so using an entrySet iterator instead.
		while( entrySetIterator.hasNext() ){
			entrySet = entrySetIterator.next();
			results[ entrySet.getKey().toString() ] = entrySet.getValue();
		}
		
		return results;

	}

	/**
	* Get an aggregate of a single stat aggregated across all servers in the cluster.  This method saves you the trouble of calling getStats() and manually 
	* looping over each server to add up the totals.  val() is called on each value, so stats which are not numeric will simply return 0.
	* This only works for numeric stats that are additive across the cluster such as "get_misses" or "curr_items".  A stat such as "time" would
	* not make sense even though it is numeric, since adding epoch dates serves no purpose.  
	* <p>
	* Information on stats available here: http://www.couchbase.com/docs/couchbase-manual-1.8/cbstats-all-bucket-info.html
	* 
	* <pre>
	* stats = client.getAggregateStat( 'curr_items' );
	* </pre>
	* 
	* @stat.hint The key of an individual stat to return
	* 
	* @return An integer representing the aggregation of the stat specified acrossed the cluster.
	*/
	any function getAggregateStat( required string stat ){
		var stats = getStats();	
		var statValue = 0;
		
		// Loop over all the servers...
		for( var thisServer in stats ){
			var serverStats = stats[ thisServer ];
			
			// ... and add up the values if they exist for that server
			if( structKeyExists( serverStats, arguments.stat ) ){
				statValue += val( serverStats[ arguments.stat ] );	
			}
		}
		return statValue;
	}

	/**
	* Decrement the given counter, returning the new value.  This method is thread safe as it decrements and retrives the value in a single operation as opposed to 
	* getting it, and then setting it again with subsequent calls.  
	* 
	* <pre>
	* newValue = client.decr( 'passesLeft', 1 );
	* </pre>
	* 
	* @ID.hint The id of the document to decrement
	* @value.hint The amount to decrement
	* @defaultValue.hint The default value ( if the counter does not exist, this defaults to 0 );
	* @timeout.hint The expiration of the document in minutes, by default it is 0, so it lives forever
	* 
	* @return The new value, or -1 if we were unable to decrement or add
	*/ 
	any function decr( 
		required string ID, 
		required numeric value, 
		numeric defaultValue=0,
		numeric timeout
	){
		arguments.ID = variables.util.normalizeID( arguments.ID );

		// default timeouts
		arguments.timeout = ( !structKeyExists( arguments, "timeout" ) ? variables.couchbaseConfig.getDefaultTimeout() : arguments.timeout );
		// store it
		return variables.couchbaseClient.decr( arguments.ID, 
													 javaCast( "long", arguments.value ), 
													 javaCast( "long", arguments.defaultValue ),
													 javaCast( "int", arguments.timeout*60 ) );
	}

	/**
	* Decrement the given counter asynchronously.  This method is thread safe as it decrements and retrives the value in a single operation as opposed to 
	* getting it, and then setting it again with subsequent calls.  
	* 
	* <pre>
	* future = client.asyncDecr( 'passesLeft', 1 );
	* </pre>
	* 
	* @ID.hint The id of the document to decrement
	* @value.hint The amount to decrement
	* 
	* @return A future with the decremented value, or -1 if the decrement failed.
	*/ 
	any function asyncDecr( 
		required string ID, 
		required numeric value
	){
		arguments.ID = variables.util.normalizeID( arguments.ID );

		// store it
		return variables.couchbaseClient.asyncDecr( arguments.ID, javaCast( "long", arguments.value ) );
	}

	/**
	* Increment the given counter.  This method is thread safe as it increments and retrives the value in a single operation as opposed to 
	* getting it, and then setting it again with subsequent calls.  
	* 
	* <pre>
	* newValue = client.incr( 'numErrors', 1 );
	* </pre>
	* 
	* @ID.hint The id of the document to increment
	* @value.hint The amount to increment
	* @defaultValue.hint The default value ( if the counter does not exist, this defaults to 0 );
	* @timeout.hint The expiration of the document in minutes, by default it is 0, so it lives forever
	* 
	* @return The new value, or -1 if we were unable to increment 
	*/ 
	any function incr( 
		required string ID, 
		required numeric value, 
		numeric defaultValue=0,
		numeric timeout
	){
		arguments.ID = variables.util.normalizeID( arguments.ID );
		
		// default timeouts
		arguments.timeout = ( !structKeyExists( arguments, "timeout" ) ? variables.couchbaseConfig.getDefaultTimeout() : arguments.timeout );
		// store it
		return variables.couchbaseClient.incr( arguments.ID, 
													 javaCast( "long", arguments.value ), 
													 javaCast( "long", arguments.defaultValue ),
													 javaCast( "int", arguments.timeout*60 ) );

	}

	/**
	* Increment the given counter asynchronously.  This method is thread safe as it increments and retrives the value in a single operation as opposed to 
	* getting it, and then setting it again with subsequent calls.  	 
	* 
	* <pre>
	* future = client.asyncIncr( 'numErrors', 1 );
	* </pre>
	* 
	* @ID.hint The id of the document to increment
	* @value.hint The amount to imcrement
	* 
	* @return A future with the incremented value, or -1 if the increment failed.
	*/ 
	any function asyncIncr( 
		required string ID, 
		required numeric value
	){
		arguments.ID = variables.util.normalizeID( arguments.ID );

		// store it
		return variables.couchbaseClient.asyncIncr( arguments.ID, javaCast( "long", arguments.value ) );
	}

	/**
	* Touch the given ID to reset its expiration time.
	* 
	* <pre>
	* future = client.touch( 'sessionData', 30 );
	* </pre>
	* 
	* @ID.hint The id of the document to increment
	* @timeout.hint The expiration of the document in minutes
	* 
	* @return A future object (net.spy.memcached.internal.OperationFuture)
	*/ 
	any function touch( 
		required string ID, 
		required numeric timeout
	){
		arguments.ID = variables.util.normalizeID( arguments.ID );

		// store it
		return variables.couchbaseClient.touch( arguments.ID, javaCast( "int", arguments.timeout*60 ) );
	}

	/**
	* Delete a value with durability options. The durability options here operate similarly to those documented in the set method.
	* 
	* <pre>
	* future = client.delete( 'brad' );
	* </pre>
	* 
	* @ID The ID of the document to delete, or an array of ID's to delete
	* @persistTo.hint The number of nodes that need to store the document to disk before this call returns.  Valid options are [ ZERO, MASTER, ONE, TWO, THREE, FOUR ]
	* @replicateTo.hint The number of nodes to replicate the document to before this call returns.  Valid options are [ ZERO, ONE, TWO, THREE ]
	* 
	* @return A Java OperationFuture object (net.spy.memcached.internal.OperationFuture<Boolean>) or a struct of futures depending on whether a single ID or an array of IDs are passed, 
	*/ 
	any function delete( 
		required any ID, 
		string persistTo, 
		string replicateTo
	){
		arguments.ID = variables.util.normalizeID( arguments.ID );

		// default persist and replicate
		defaultPersistReplicate( arguments );

		// simple or array
		arguments.id = ( isSimpleValue( arguments.id ) ? listToArray( arguments.id ) : arguments.id );
		
		// iterate and prepare futures
		var futures = {};
		for( var thisKey in arguments.id ){
			// store it
			futures[ thisKey ] = variables.couchbaseClient.delete( thisKey, 
																   arguments.persistTo,
																   arguments.replicateTo );

		}

		// if > 1 futures, return struct, else return the only one future
		return ( structCount( futures ) > 1 ? futures : futures[ arguments.id[ 1 ] ] );
	}

	/**
	* Get stats for a specific document ID.
	* 
	* <pre>
	* docStats = client.getDocStats( 'brad' );
	* docStatArray = client.getDocStats( ['brad', 'luis', 'bill'] );
	* </pre>
	* 
	* @ID.hint The id of the document to get the stats for or a list or an array
	* 
	* @return A future or a struct of futures depending on whether a single ID or an array of IDs are passed,
	*/ 
	any function getDocStats( required any ID ){
		arguments.ID = variables.util.normalizeID( arguments.ID );

		// simple or array
		arguments.id = ( isSimpleValue( arguments.id ) ? listToArray( arguments.id ) : arguments.id );
		
		// iterate and prepare futures
		var futures = {};
		for( var thisKey in arguments.id ){
			// store it
			futures[ thisKey ] = variables.couchbaseClient.getKeyStats( thisKey );

		}

		// if > 1 futures, return struct, else return the only one future
		return ( structCount( futures ) > 1 ? futures : futures[ arguments.id[ 1 ] ] );
	}

	/**
	* Get the addresses of available servers.
	* 
	* <pre>
	* serverArray = client.getAvailableServers();
	* </pre>
	* 
	* @return An array containing an item for each server in the cluster.  Servers are represented as a string containing their address produced via java.net.InetSocketAddress.toString() 
	*/ 
	array function getAvailableServers(){
		var servers = variables.couchbaseClient.getAvailableServers();
		var index	= 1;
		for( var thisServer in servers ){
			servers[ index++ ] = thisServer.toString();
		}
		return servers;
	}

	/**
	* Get the addresses of unavailable servers
	* 
	* <pre>
	* serverArray = client.getUnAvailableServers();
	* </pre>
	* 
	* @return An array containing an item for each unavilable server in the cluster.  Servers are represented as a string containing their address produced via java.net.InetSocketAddress.toString() <br>If all servers are online, the array with be empty.	
	*/ 
	array function getUnAvailableServers(){
		var servers = variables.couchbaseClient.getUnAvailableServers();
		var index	= 1;
		for( var thisServer in servers ){
			servers[ index++ ] = thisServer.toString();
		}
		return servers;
	}

	/**
	* Append to an existing value in the cache. If 0 is passed in as the CAS identifier (default), it will override the value on the server without performing the CAS check.
	* This method is considered a 'binary' method since it operates on binary data such as string or integers, not JSON documents
	* 
	* <pre>
	* future = client.append( 'operationLog', 'This is a new log message#chr(13)##chr(10)#' );
	* </pre>
	* 
	* @ID.hint The unique id of the document whose value will be appended
	* @value.hint The value to append
	* @CAS.hint CAS identifier (ignored in the ascii protocol)
	* 
	* @return A Java OperationFuture object (net.spy.memcached.internal.OperationFuture<Boolean>) Note that the return will be false any time a mutation has not occurred. 
	*/ 
	any function append( 
		required string ID, 
		required any value, 
		numeric CAS
	){

		// normalize ID
		arguments.ID = variables.util.normalizeID( arguments.ID );

		// append with cas
		var future = "";
		if( structKeyExists( arguments, "CAS") ){
			return variables.couchbaseClient.append( javaCast( "long", arguments.CAS ),			 											
													   arguments.ID,
													   arguments.value );
		}
		// append with no CAS
		else{
			return variables.couchbaseClient.append( arguments.ID, arguments.value );	
		}
	}

	/**
	* Prepend to an existing value in the cache. If 0 is passed in as the CAS identifier (default), it will override the value on the server without performing the CAS check.
	* This method is considered a 'binary' method since they operate on binary data such as string or integers, not JSON documents
	* 
	* <pre>
	* future = client.prepend( 'hierachyList', parent );
	* </pre>
	* 
	* @ID.hint The unique id of the document whose value will be prepended
	* @value.hint The value to prepend
	* @CAS.hint CAS identifier (ignored in the ascii protocol)
	* 
	* @Return A Java OperationFuture object (net.spy.memcached.internal.OperationFuture<Boolean>) Note that the return will be false any time a mutation has not occurred.
	*/ 
	any function prepend( 
		required string ID, 
		required any value, 
		numeric CAS
	){

		// normalize ID
		arguments.ID = variables.util.normalizeID( arguments.ID );

		// prepend with cas
		var future = "";
		if( structKeyExists( arguments, "CAS") ){
			return variables.couchbaseClient.prepend( javaCast( "long", arguments.CAS ),			 											
													    arguments.ID,
													    arguments.value );
		}
		// prepend with no CAS
		else{
			return variables.couchbaseClient.prepend( arguments.ID, arguments.value );	
		}				
	}

	/************************* VIEW INTEGRATION ***********************************/

	/**
	* Creates a new Java query object (com.couchbase.client.protocol.views.Query) that can be used to execute raw view queries. 
	* You can pass an optional options struct with name-value pairs of simple query options.
	* <p>
	* http://www.couchbase.com/autodocs/couchbase-java-client-1.2.0/com/couchbase/client/protocol/views/Query.html
	* 
	* <pre>
	* oQuery = client.newQuery( { offset:10, limit:20, group:true, groupLevel:2 } );
	* </pre>
	* 
	* @options.hint A struct of query options, see http://www.couchbase.com/autodocs/couchbase-java-client-1.2.0/com/couchbase/client/protocol/views/Query.html for more information. This only does the simple 1 value options
	* 
	* @return A Java query object (com.couchbase.client.protocol.views.Query)
	*/
	any function newQuery( struct options={} ){
		var oQuery = newJava( "com.couchbase.client.protocol.views.Query" ).init();
		return variables.queryHelper.processOptions( arguments.options, oQuery );
	}

	/**
	* Queries a Couchbase view using the options supplied.  
	*<p>
	* Valid options are:
	*<p>
	* <ul>
	* <li><b>sortOrder</b> - Specifies the direction to sort the results based on the map function's "key" value.  Valid values are ASC and DESC.</li>
	* <li><b>limit</b> - Number of records to return</li>
	* <li><b>offset</b> - Number of records to skip when returning</li>
	* <li><b>reduce</b> - Flag to control whether the reduce portion of the view is run. If false, only the results of the map function are returned.</li>
	* <li><b>includeDocs</b> - Specifies whether or not to include the entire document in the results or just the key names. Default is false.</li>
	* <li><b>startkey</b> - Specify the start of a range of keys to return.  This value needs to be the same data type as the key in your view's map function.  If your view has a string for the key, pass in a string here.  If your key is an array of values, pass in an array of values.</li>
	* <li><b>endkey</b> - Specify the end of a range of keys to return.  This value needs to be the same data type as the key in your view's map function.  If your view has a string for the key, pass in a string here.  If your key is an array of values, pass in an array of values.</li>
	* <li><b>inclusiveEnd</b> - Use this when specifying an endKey parameter. Flag to control whether the endKey is inclusive or not.</li>
	* <li><b>startkeyDocID</b> - If you have specified a startKey AND there is more than one record in the view results that share that key, this will specify what ID to start at when returning records.  This input is ignored when not using startKey.</li>
	* <li><b>endKeyDocID</b> - If you have specified an endKey AND there is more than one record in the view results that share that key, this will specify what ID to end at when returning records.  This input is ignored when not using endKey.</li>
	* <li><b>group</b> - Flag to control whether the results of the reduce function are grouped.  If no groupLevel is specified, only one row will be returned.</li>
	* <li><b>groupLevel</b> - Number representing what level of the map key to group at (Keys can be complex).  If the key is simple, this parameter does nothing.</li>
	* <li><b>key</b> - The key of a single record to return.  For complex keys, pass the key as an array.</li>
	* <li><b>keys</b> - An array of keys to return.  For complex keys, pass each key as an array.</li>
	* <li><b>stale</b> - Specifies if stale data can be returned with the view.  Possible values are:
	* 	<ul>
	*  		<li><b>"OK"</b> (default) - stale data is ok
	*  		<li><b>"FALSE"</b> - force index of view
	*  		<li><b>"UPDATE_AFTER"</b> - potentially returns stale data, but starts an asynch re-index.</li>
	* 	</ul>
	*   </li>
	* <li><b>debug</b> - Java SDK will log debugging information about the query</li>
	* </ul> 
	* <p>
	* The options struct maps to the set of options found
	* in the native Couchbase query object (com.couchbase.client.protocol.views.Query) 
	* See http://www.couchbase.com/autodocs/couchbase-java-client-1.2.0/com/couchbase/client/protocol/views/Query.html
	* 
	* <pre>
	* results = client.query( designDocumentName='beer', viewName='brewery_beers', options={ limit: 20, stale: 'OK' } );
	* </pre>
	* 
	* @designDocumentName.hint The name of the design document
	* @viewName.hint The name of the view to get
	* @options.hint The query options to use for this query. This can be a structure of name-value pairs or an actual Couchbase query options object usually using the 'newQuery()' method.
	* @deserialize.hint If true, it will deserialize the documents if they are valid JSON, else they are ignored.
	* @inflateTo.hint A path to a CFC or closure that produces an object to try to inflate the document results on NON-Reduced views only!
	* @filter.hint A closure or UDF that must return boolean to use to filter out results from the returning array of records, the closure receives a struct that has id, document, key, and value: function( row ). A true will add the row to the final results.
	* @transform.hint A closure or UDF to use to transform records from the returning array of records, the closure receives a struct that has id, document, key, and value: function( row ). Since the struct is by reference, you do not need to return anything.
	* @returnType.hint The type of return for us to return to you. Available options: native, iterator, array. By default we use the cf type which uses transformations, automatic deserializations and inflations.
	* 
	* @return If returnType is "array", will return an array of structs where each struct represents a record of output from the view.	<br>Each struct contains the following items: id, document, key, value	<br>If returnType is native, a Java ViewResponse object will be returned (com.couchbase.client.protocol.views.ViewResponse)	<br>If returnType is iterator, a Java iterator object will be returned
	*/
	any function query( 
		required string designDocumentName, 
		required string viewName,
		any options={},
		boolean deserialize=true,
		any inflateTo="",
		any filter,
		any transform,
		string returnType="array"
	){
		// if options is struct, then build out the query, else use it as an object.
		var oQuery = ( isStruct( arguments.options ) ? newQuery( arguments.options ) : arguments.options );
		var oView  	= getView( arguments.designDocumentName, arguments.viewName );
		var results = rawQuery( oView, oQuery );

		// Native return type?
		if( arguments.returnType eq "native" ){ return results; }

		// Were there errors
    	if( arrayLen( results.getErrors() ) ){
    		// PLEASE NOTE, the response received may not include all documents if one or more nodes are offline 
	    	// and not yet failed over.  Couchbase basically sends back what docs it _can_ access and ignores the other nodes.
    		variables.util.handleRowErrors( message='There was an error executing the view: #arguments.viewName#',
    										rowErrors=results.getErrors(),
    										type='CouchbaseClient.ViewException' );
    	}

    	// Iterator results?
    	if( arguments.returnType eq "iterator" ){ return results.iterator(); }

    	// iterate and build it out with or without desrializations
		var iterator 	= results.iterator();
		var cfresults 	= [];
		while( iterator.hasNext() ){
			var thisRow 	 = iterator.next();
			var isReduced	 = ( results.getClass().getName() eq "com.couchbase.client.protocol.views.ViewResponseReduced"  ? true : false );
			var hasDocs		 = ( results.getClass().getName() eq "com.couchbase.client.protocol.views.ViewResponseWithDocs" ? true : false );
			/**
			* ID: The id of the document in Couchbase, but only available if the query is NOT reduced
			* Document: Only available if the query is NOT reduced
			* Key: This is always available, but null if the query has been reduced, If un-redunced it is the first value passed into emit()
			* Value: This is always available. If reduced, this is the value returned by the reduce(), if not reduced it is the second value passed into emit()
			**/
			var thisDocument = { id : "", document : "", key="", value="" };
			
			// Did we get a document or none?
			if( hasDocs ){
				thisDocument.document = deserializeData( thisRow.getDocument(), arguments.inflateTo, arguments.deserialize );
			}
			// check for reduced
			if( isReduced ){
				thisDocument.key = thisRow.getKey();
				thisDocument.value = thisRow.getValue();
			} else {
				thisDocument.id = thisRow.getID();
			}
			
			// Do we have a transformer?
			if( structKeyExists( arguments, "transform" ) AND isClosure( arguments.transform ) ){
				arguments.transform( thisDocument );
			}

			// Do we have a filter?
			if( !structKeyExists( arguments, "filter" ) OR 
				( isClosure( arguments.filter ) AND arguments.filter( thisDocument ) ) 
			){
				arrayAppend( cfresults, thisDocument );
			}
		}

		return cfresults;
	}

	/**
	* Queries a Couchbase view. 
	* See: http://www.couchbase.com/autodocs/couchbase-java-client-1.2.0/com/couchbase/client/protocol/views/ViewResponse.html
	*	 
	* <pre>
	* query = client.newQuery( { limit: 20, stale: 'OK' } );
	* view = client.getView( 'beer', 'brewery_beers' );
	* results = client.rawQuery( view, query );
	* </pre>
	* 
	* @viewName.hint A couchbase view object (com.couchbase.client.protocol.views.View)
	* @query.hint A couchbase query object (com.couchbase.client.protocol.views.Query)
	*
	* @return A raw Java View result object. The result can be accessed row-wise via an iterator class (com.couchbase.client.protocol.views.ViewResponse).
	*/
	any function rawQuery( required any view, required any query ){
		return variables.couchbaseClient.query( arguments.view, arguments.query );
	}

	/**
	* Gets access to a view contained in a design document from the cluster 
	* You would usually use this method if you need the raw Java object to do manual queries or updates on a view.
	*	 
	* <pre>
	* view = client.getView( 'beer', 'brewery_beers' );
	* </pre>
	* 
	* @designDocumentName.hint The name of the design document
	* @viewName.hint The name of the view to get
	*
	* @return A View Java object (com.couchbase.client.protocol.views.View).
	*/
	any function getView( required string designDocumentName, required string viewName ){
		return variables.couchbaseClient.getView( arguments.designDocumentName, arguments.viewName );	
	}

	/**
	* Gets access to a spatial view contained in a design document from the cluster. 
	* You would usually use this method if you need the raw Java object to do manual queries or updates on a view.
	*	 
	* <pre>
	* spatialView = client.getSpatialView( 'myDoc', 'mySpatialView' );
	* </pre>
	* 
	* @designDocumentName.hint The name of the design document
	* @viewName.hint The name of the view to get
	*
	* @return A View Java object (com.couchbase.client.protocol.views.SpatialView).
	*/
	any function getSpatialView( required string designDocumentName, required string viewName ){
		return variables.couchbaseClient.getSpatialView( arguments.designDocumentName, arguments.viewName );	
	}

	/**
	* Gets a design document.
	* This method will throw an error if the design document name doesn't exist.  Names are case-sensitive.
	*	 
	* <pre>
	* designDocument = client.getDesignDocument( 'beer' );
	* </pre>
	* 
	* @designDocumentName.hint The name of the design document
	*
	* @return A DesignDocument Java object (com.couchbase.client.protocol.views.DesignDocument).
	*/
	any function getDesignDocument( required string designDocumentName ){
		return variables.couchbaseClient.getDesignDoc( arguments.designDocumentName );	
	}

	/**
	* Deletes a design document from the server
	*	 
	* <pre>
	* client.deleteDesignDocument( 'beer' );
	* </pre>
	* 
	* @designDocumentName.hint The name of the design document
	*
	* @return True if successsful, false if unsuccessful
	*/
	any function deleteDesignDocument( required string designDocumentName ){
		return variables.couchbaseClient.deleteDesignDoc( arguments.designDocumentName );	
	}

	/**
	* Initializes a new design document Java object.  The design doc will have no views and will not be saved yet. 
	*	 
	* <pre>
	* designDocument = client.newDesignDocument( 'mynewDoc' );
	* </pre>
	* 
	* @designDocumentName.hint The name of the design document to initialize
	*
	* @return An instance of com.couchbase.client.protocol.views.DesignDocument.
	*/
	any function newDesignDocument( required string designDocumentName ){
		return newJava( "com.couchbase.client.protocol.views.DesignDocument" ).init( arguments.designDocumentName );	
	}

	/**
	* Checks to see if a design document exists.
	*	 
	* <pre>
	* result = client.designDocumentExists( 'beer' );
	* </pre>
	* 
	* @designDocumentName.hint The name of the design document to check for
	*
	* @Return True if the design document is found and false if it is not found.
	*/
	boolean function designDocumentExists( required string designDocumentName ){
		
		// Couchbase doesn't provide a way to check for DesignDocuments, so try to retrieve it and catch the error.
    	try {
    		var designDocument = getDesignDocument( arguments.designDocumentName );
    		return true;	
    	}
    	catch(Any e) {	
			return false;
		}
	}

	/**
	* Checks to see if a view exists.
	* You can check for a view by name, but if you supply a map or reduce function, they will be checked as well.
	*	 
	* <pre>
	* result = client.viewExists( 'beer', 'brewery_beers' );
	* </pre>
	* 
	* @designDocumentName.hint The name of the design document to check for
	* @viewName.hint The name of the view to check for
	* @mapFunction.hint The map function to check for.  Must be an exact match.
	* @reduceFunction.hint The reduce function to check for.  Must be an exact match.
	*
	* @Return 0 if the design document doesn't exist as well as if the design document exists, but there is no view by that name.<br> If the view does exist, it will return the index of the view in the designDocument's view array.
	*/
	any function viewExists( required string designDocumentName, required string viewName, string mapFunction, string reduceFunction ){
		// If the design doc doesn't exist, bail.
		if( !designDocumentExists( arguments.designDocumentName ) ) {
			return 0;
		}
    	var designDocument = getDesignDocument( arguments.designDocumentName );
		var views = designDocument.getViews();
		
		var i = 0;
		// Search to see if this view is already in the design document
		for( var view in views ) {
			i++;
			// If we find it (by name)
			if( view.getName() == arguments.viewName ) {
				// If there was a mapFunction specified, enforce the match
				if( structKeyExists(arguments, 'mapFunction') && arguments.mapFunction != view.getMap()) {
					return 0;
				}
				// If there was a reduceFunction specified, enforce the match
				if( structKeyExists(arguments, 'reduceFunction') && arguments.reduceFunction != view.getReduce()) {
					return 0;
				}
				// Passed all the tests
				return i;
			}
		}
		
		// Exhausted the array with no match
		return 0;
	}


	/**
	* Creates a new instance of a viewDesign Java object (com.couchbase.client.protocol.views.ViewDesign)
	*	 
	* <pre>
	* viewDesign = client.newViewDesign( viewName, mapFunction, reduceFunction );
	* </pre>
	* 
	* @viewName.hint The name of the view to be created 
	* @mapFunction.hint The map function for the view represented as a string
	* @reduceFunction.hint The reduce function for the view represented as a string
	*
	* @Return An instance of the Java class com.couchbase.client.protocol.views.ViewDesign
	*/
	any function newViewDesign( required string viewName, required string mapFunction, string reduceFunction = ''  ){
		return newJava( "com.couchbase.client.protocol.views.ViewDesign" ).init( arguments.viewName, arguments.mapFunction, arguments.reduceFunction );	
	}

	/**
	* Asynchronously Saves a View.  Will save the view and or designDocument if they don't exist.  Will update if they already exist.  This method
	* will return immediatley, but the view probalby won't be available to query for a few seconds. 
	*	 
	* <pre>
	* client.asyncSaveView(
	* &nbsp;&nbsp;'manager',
	* &nbsp;&nbsp;'listBreweries',
	* &nbsp;&nbsp;'function (doc, meta) {
	* &nbsp;&nbsp;if ( doc.type == ''brewery'' ) {
	* &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;emit(doc.name, null);
	* &nbsp;&nbsp;&nbsp;&nbsp;}
	* &nbsp;&nbsp;}',
	* &nbsp;&nbsp;'_count'
	* );
	* </pre>
	* 
	* @designDocumentName.hint The name of the design document for the view to be saved under.  The design document will be created if neccessary
	* @viewName.hint The name of the view to be saved
	* @mapFunction.hint The map function for the view represented as a string
	* @reduceFunction.hint The reduce function for the view represented as a string
	*
	* @Return True if the view was saved, false if no save occurred due to the view already existing.
	*/
	boolean function asyncSaveView( required string designDocumentName, required string viewName, required string mapFunction, string reduceFunction = '' ){
		
		// This is required to clean up carriage returns
		arguments.mapFunction = variables.util.normalizeViewFunction(arguments.mapFunction);
		arguments.reduceFunction = variables.util.normalizeViewFunction(arguments.reduceFunction);
		
		// If this exact view already exists, we've nothing to do here
		if( viewExists( argumentCollection=arguments ) ) {
			return false;
		}
	
		// Does the design doc exist?
    	if( designDocumentExists( arguments.designDocumentName ) ) {
    		// Get it
    		var designDocument = getDesignDocument( arguments.designDocumentName );	
    	} else {	
    		// Create it
			var designDocument = newDesignDocument( arguments.designDocumentName );
		}
		
		// Create a representation of our new view
		var viewDesign = newViewDesign( arguments.viewName, arguments.mapFunction, arguments.reduceFunction );
		
		var views = designDocument.getViews();
		// Check for this view by name (A less specific check than the one at the top of this method)
		var matchIndex = viewExists( arguments.designDocumentName, arguments.viewName );
		// And update or add it into the array as neccessary
		if( matchIndex ) {
			// Update existing
			views[matchIndex] = viewDesign;	
		} else {
			// Insert new
			views.add( viewDesign );
		}
		
		// Even though this method is called "create", it will turn the design document into JSON
		// and PUT it into the REST API which will also update existing design docs
		variables.couchbaseClient.createDesignDoc( designDocument );
		
		return true;			
	}


	/**
	* Saves a View.  Will save the view and or designDocument if they don't exist.  Will update if they already exist.  
	*	 
	* <pre>
	* client.saveView(
	* &nbsp;&nbsp;'manager',
	* &nbsp;&nbsp;'listBreweries',
	* &nbsp;&nbsp;'function (doc, meta) {
	* &nbsp;&nbsp;if ( doc.type == ''brewery'' ) {
	* &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;emit(doc.name, null);
	* &nbsp;&nbsp;&nbsp;&nbsp;}
	* &nbsp;&nbsp;}',
	* &nbsp;&nbsp;'_count'
	* &nbsp;&nbsp;20
	* );
	* </pre>
	* 
	* @designDocumentName.hint The name of the design document for the view to be saved under.  The design document will be created if neccessary
	* @viewName.hint The name of the view to be saved
	* @mapFunction.hint The map function for the view represented as a string
	* @reduceFunction.hint The reduce function for the view represented as a string
	* @waitFor.hint How many seconds to wait for the view to save before giving up.  Defaults to 20, but may need to be higher for larger buckets.
	*
	* @Return True when the view is ready.  If the view is still not accessable after the number of seconds specified in the "waitFor" parameter, the method will return false.
	*/
	boolean function saveView( required string designDocumentName, required string viewName, required string mapFunction, string reduceFunction = '', waitFor = 20 ){
		
    	var viewSaved = asyncSaveView( argumentCollection=arguments );
    	
    	// Bail now if no save actually occurred
    	if( !viewSaved ) {
			return true;
		}
    		
	  	// View creation and population is asynchronous so we'll wait a while until it's ready.  
		var attempts = 0;
		while(++attempts <= arguments.waitFor) {
			try {
				// Access the view
				this.query( designDocumentName=arguments.designDocumentName, viewName=arguments.viewName, options={ limit: 20, stale: 'FALSE' } );
				
				// The view is ready to be used!
				return true;
			}
			catch(Any e) {
				// Wait 1 second before trying again
				sleep(1000);
			}
		}
		
		// We've given up and the view never worked. There could be a problem, but most 
		// likely the bucket just isn't finished indexing
		return false;
		
	}



	/**
	* Deletes a View.  Will delete the view from the designDocument if it exists.  
	*	 
	* <pre>
	* client.deleteView( 'myDoc', 'myView' );
	* </pre>
	* 
	* @designDocumentName.hint The name of the design document for the view to be deleted from
	*
	* @viewName.hint The name of the view to be created
	*/
	void function deleteView( required string designDocumentName, required string viewName ){
		
		// Check for this view by name
		var matchIndex = viewExists( arguments.designDocumentName, arguments.viewName );
		
		// Only bother continuing if it exists
		if( matchIndex ) {
			
	    	var designDocument = getDesignDocument( arguments.designDocumentName );	
	    	var views = designDocument.getViews();
			
			// Remove the view from the array
			ArrayDeleteAt( views, matchIndex );

			// If there are other views left, then save
			if( arrayLen(views) ) {
				// Even though this method is called "create", it will turn the design document into JSON
				// and PUT it into the REST API which will also update existing design docs
				variables.couchbaseClient.createDesignDoc( designDocument );				
			} else {
				// If this was the last view, nuke the entire design document.  
				// This is a limitation of the Java client as it will refuse to save a design doc with no views.
				deletedesigndocument( arguments.designDocumentName );
			}

			
		} // end view exists?		
	}


	/************************* SERIALIZE/DESERIALIZE INTEGRATION ***********************************/

	/**
	* Deserializes an incoming data string via JSON and according to our rules. It can also accept an optional 
	* inflateTo parameter wich can be an object we should inflate our data to.
	*
	* @data.hint A JSON document to deserialize according to our rules
	* @inflateTo.hint The object that will be used to inflate the data with according to our conventions
	* @deserialize.hint The boolean value that marks if we should deserialize or not. Default is true
	*
	* @Return The deserialized data
	*/
	any function deserializeData( required string data, any inflateTo="", boolean deserialize=true ){
		// Data marshaler
		return variables.dataMarshaller.deserializeData( arguments.data, arguments.inflateTo, arguments.deserialize );
	}

	/**
	* Serializes incoming data according to our rules.
	*
	* @data.hint The data to serialize
	*
	* @Return A string representation, usually JSON.
	*/
	string function serializeData( required any data ){
		// Go to data marshaler
		return variables.dataMarshaller.serializeData( arguments.data );
	}

	/************************* JAVA INTEGRATION ***********************************/

	/**
    * Get the java loader instance
	*
    * @Return The javaLoader CFC.
    */
    any function getJavaLoader() {
    	if( ! structKeyExists( server, variables.javaLoaderID ) ){ loadSDK(); }
		return server[ variables.javaLoaderID ];
	}

	/**
    * Get a java class using either the JavaLoader or createOject() based on the "useClassloader" config value.
    * You will need to call init() if you want to run the class constructor and get an instance of it.  
	*
    * @className.hint The class to get
	*
    * @Return The java class specified. 
    */
    any function newJava( required className ) {
    	return ( variables.couchbaseConfig.getUseClassloader() ? getJavaLoader().create( arguments.className ) : createObject( "java", arguments.className ) );
	}
	
	/************************* PRIVATE ***********************************/

	/**
	* Build the data marshaller
	*
	* @config.hint The CFCouchbase config object
	*
	* @Return The data marshaller 
	*/
	private any function buildDataMarshaller( required any config ){
		var marshaller = arguments.config.getDataMarshaller();

		// Build the data marshaller
		if( isSimpleValue( marshaller ) and len( marshaller ) ){
			return new "#marshaller#"();
		} else if( isObject( marshaller ) ){
			return marshaller;
		} else {
			// build core marshaller.
			return new data.CoreMarshaller();
		}
	}

	/**
	* Build a couchbase connection client according to config and returns the raw java connection client object
	*
	* @config.hint The CFCouchbase config object
	*
	* @Return The java CouchbaseClient class (com.couchbase.client.CouchbaseClient).
	*/
	private any function buildCouchbaseClient( required any config ){
		// get config options
		var configData = arguments.config.getMemento();
		// cleanup server URIs and build java URI classes
		var serverURIs = variables.util.buildServerURIs( configData.servers );

		// Create a connection factory builder
		factoryBuilder = newJava( "com.couchbase.client.CouchbaseConnectionFactoryBuilder" ).init();
		
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
		return newJava( "com.couchbase.client.CouchbaseClient" ).init( cf );
	}

	/**
	* Standardize and validate configuration object
	*
	* @config.hint The config options as a struct, path or instance.
	*
	* @Return The CFCouchbase config CFC
	*/
	private any function validateConfig( required any config ){
		// do we have a simple path to inflate
		if( isSimpleValue( arguments.config ) ){
			// build out cfc
			arguments.config = new "#arguments.config#"();
		}

		// We've been given a CFC instance		
		if( isObject( arguments.config ) ){
			
			// Validate the configure() method
			if( !structKeyExists( arguments.config, 'configure' ) ) {
				throw( message='Config file must have a configure() method', detail='Valid config CFCs must set their config settings into the variables scope in a configure() method.', type='InvalidConfig' );
			}
			
			// Configure the CFC
			arguments.config.configure();
			
			// check family, for memento injection
			if( isInstanceOf( arguments.config, "cfcouchbase.config.CouchbaseConfig" ) ) {
				return arguments.config;				
			} else {
				// get memento out via mixin
				var oConfig = new config.CouchbaseConfig();
				arguments.config.getMemento = oConfig.getMemento;
				return oConfig.init( argumentCollection=arguments.config.getMemento() );				
			}
			
		}

		// check if its a struct literal of config options
		if( isStruct( arguments.config ) ){
			// init config object with memento
			return new config.CouchbaseConfig( argumentCollection=arguments.config );
		}

	}

	/**
	* Get a list of all the jars in the lib directory
	*
	* @Return An array of jar file names
	*/
	private array function getLibJars(){
		return directoryList( variables.libPath, false, "path" );
	}

	/**
	* Load JavaLoader with the SDK
	*/
	private void function loadSDK(){
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
	* Default persist and replicate from arguments.  Will create "persistTo" with a default value of ZERO and "replicateTo" with a 
	* default value of ZERO if they don't exist.  Also translates from string inputs to the Java enum value
	*
	* @args.hint The argument collection to process
	*
	* @Return The argument collection with the defaulted values. 
	*/
	private any function defaultPersistReplicate( required args ) {
		var validPersistTo = 'ZERO,MASTER,ONE,TWO,THREE,FOUR';
		var validReplicateTo = 'ZERO,ONE,TWO,THREE';

		// persistTo
		if( structKeyExists( args, "persistTo" ) ) {
			args.persistTo = trim( args.persistTo );
			if( !listFindNoCase( validPersistTo, args.persistTo ) ) {
						throw( message='Invalid persistTo value of [#args.persistTo#]', detail='Valid values are [#validPersistTo#]', type='InvalidPersistTo' );
			}
			args.persistTo = this.persistTo[args.persistTo];
		} else {
			// Default it
			args.persistTo = this.persistTo.ZERO;
		}

		// replicateTo
		if( structKeyExists( args, "replicateTo" ) ) {
			args.replicateTo = trim( args.replicateTo );
			if( !listFindNoCase( validReplicateTo, args.replicateTo ) ) {
						throw( message='Invalid replicateTo value of [#args.replicateTo#]', detail='Valid values are [#validReplicateTo#]', type='InvalidReplicateTo' );
			}
			args.replicateTo = this.replicateTo[args.replicateTo];
		} else {
			// Default it
			args.replicateTo = this.replicateTo.ZERO;
		}

		return args;
	}

}