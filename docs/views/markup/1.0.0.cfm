<div class="header">
= CFCouchbase SDK =
</div>
	
CFCouchbase is a client library designed to make it easy for applications written in CFML to integrate with [http://www.couchbase.com Couchbase Server] for caching and NoSQL.  
Here is a quick sample showing how easy it is to work with the Couchbase SDK.


<source lang="javascript">
// Create the client
client  = new cfcouchbase.CouchbaseClient();

// Create a document in the cluster
client.set( 'brad', { name: 'Brad', age: 33, hair: 'red' } );

// Retrieve that doc
person = client.get( 'brad' );

// Use the document
writeOutput( '#person.name# is #person.age# years old and has #person.hair# hair.' );
	
// Shutdown the client
client.shutdown( 10 );
</source>


</source>


<p>&nbsp;</p>

<blockquote>
Interactive applications have changed dramatically over the last 15 years, and so have the data management needs of those apps. Today, three interrelated megatrends - Big Data, Big Users, and Cloud Computing - are driving the adoption of NoSQL technology. NoSQL is increasingly considered a viable alternative to relational databases...
<small>[http://www.couchbase.com Couchbase]</small>
</blockquote>

<p>&nbsp;</p>

<div class="well well-small text-center">
<img src="includes/images/monitor_graph.png" class="img-polaroid"/>
<p>The web console of a Couchbase cluster</p>
</div>

== Requirements ==

* Couchbase Server 1.8+
* ColdFusion 9.01+
* Railo 3.1+

== Features In A Nutshell ==

* Lightweight, standalone library can be used with any application
* High performance
* Asynchronous calls 
* Auto-sharding of documents evenly across cluster
* 24/7 uptime via on-the-fly node removal and rebalance operations   
* Easily configurable
* Fully-featured API includes view management and execution
* Built on the official Java SDK, but customized to take advantage of CFML
* Optimistic concurrency control (Documents are not locked by default for maximum throughput)
* Conflict managment via Compare And Swap (CAS) mechanism
* Full cluster and document stats available
* Provides direct access to underlying Java SDK for advanced usage 


== Installation ==

Download the SDK from our [http://www.coldbox.org/download download page] and unzip the contents.  

* '''/cfcouchbase''' - This is the actual SDK code
* '''/documentation''' - This is a standalone version of the documentation you are reading right now
* '''/apidocs''' - The API docs that show you the FULL list of SDK methods and their arguments (even ones not covered here)


<p>&nbsp;</p>

<span class="alert alert-info">
'''Note''' : The API Docs also have descriptions and code samples for every method.  They area must read!  
</span>

<p>&nbsp;</p>


The CFCouchase SDK is contained in a single folder.  The easiest way to install it is to copy "cfcouchbase" in the web root.  For a more secure installation, place it outside the web root and create a mapping called "cfcouchbase".   

<source lang="javascript">
this.mappings[ '/cfcouchbase' ] = 'C:\path\to\cfcouchbase';
</source>

Now that the code is in place, all you need to do is create an instance of <span class="label">cfcouchbase.CouchbaseClient</span> for each bucket you want to connect to.  
CouchbaseClient is thread safe and you only need one instance per bucket for your entire application.  It is recommended that you store the instantiated client 
in a persistent scope such as "application" when your app starts up so you can access easily.  

<source lang="javascript">
public boolean function onApplicationStart(){
	application.couchbase = new cfcouchbase.CouchbaseClient();
	return true;
}
</source>

When you are finished with the client, you need to call its '''shutdown()''' method to close open connections to the Couchbase server.  The following code sample will wait up to 10 seconds for connections to be closed. 

<source lang="javascript">
public boolean function onApplicationStop(){		
	application.couchbase.shutdown( 10 );
	return true;
}
</source>


<div class="alert">
<strong>Important</strong>: Each Couchbase bucket operates independantly and ues its own authentication.  You need an instance of '''CouchbaseClient''' for each bucket you want to interact with.  
</div>

== Configuration ==

The default configuration for CFCouchbase is located in <span class="label">/cfcouchbase/config/CouchbaseConfig.cfc</span>.  You can create the CouchbaseClient with no configuration and it will connect to the "default" bucket on localhost.

There are 2 ways to configure into the Couchbase client.

* Pass a config struct directly into client constructor
* Pass a config CFC into the client constructor


<p>&nbsp;</p>

<span class="alert alert-info">
'''Note''' : The config CFC is the most contained and portable way to store your configuration.
</span>

<p>&nbsp;</p>

There are a number of configuration otions you can set for the client, but most of them can be left at their default value.  To see a full list of options, look in <span class="label">/cfcouchbase/config/CouchbaseConfig.cfc</span>.
Here are some of the most common setting you will need to use:
 
=== Common Config Settings ===

{| cellpadding=”5”, class="table table-hover table-striped"
! '''Setting''' !! '''Type''' !! '''Default''' !! '''Description''' 
|-
|| '''servers''' || any || http://127.0.0.1:8091 || The list of servers to connect to.  Can be comma-delimited list or an array.  If you have more than one server in your cluster, you only need to specify one, but adding more than one will help in the event a node is down when the client connnect. 
|-
|| '''bucketName''' || string || default || The bucketname to connect to on the cluster.  This is case-sensitive
|-
|| '''password''' || string ||  --- || The optional password of the bucket.
|-
|| '''dataMarshaller''' || any ||  --- || The data marshaller to use for serializations and deserializations, please put the class path or the instance of the marshaller to use.  Remember that it must implement our interface: cfcouchbase.data.IDataMarshaller  
|}


=== Config Struct ===

The simplest way to get started using the SDK is to simply pass a struct of config settings into the constructor when you create the client.

<source lang="javascript">
couchbase = new cfcouchbase.CouchbaseClient(
	{
		servers = ['http://cache1:8091','http://cache2:8091'],
		bucketName = 'myBucket',
		bucketName = 'myPass'
	} 
);
</source>


=== Config CFC ===

The most portable method for configuring the client is to use a CFC to place your config settings in much like our other libraries such as WireBox and CacheBox allow.
To do this simply create a plain CFC with a public method called '''configure()'''.  Inside of that method, put your config settings into the variables scope of the component.  The '''configure()''' method does not need to return any value.  It will be automatically invoked by the SDK prior to the config settings being extracted from the CFC. 

<span class="label label-info">myConfig.cfc</span>
<source lang="javascript">
component {
	
	function configure() {
		servers = ['http://cache1:8091','http://cache2:8091'];
		bucketName = 'myBucket';
		bucketName = 'myPass';
	}

}
</source>

To use the config CFC, simply pass it into the CouchbaseClient's constructor.

<source lang="javascript">
// You can pass an instance
couchbase = new cfcouchbase.CouchbaseClient( new path.to.config() );

// You can also pass a path to the CFC
couchbase = new cfcouchbase.CouchbaseClient( 'path.to.config' );
</source>


== Usage ==

Whether you are using Couchbase for simple caching or as the NoSQL database for an application, your most common operations are going to be getting and setting data.  
Data is most commonly a JSON document, but can really be any string you want including binary representations of serialized objects.

For the comprehensive list of SDK methods, parameters, descriptions, and code samples, please look in the '''API docs''' (in the download).  Click on the <span class="label">cfcouchbase</span> package and then the <span class="label">CouchbaseClient</span> class.  
 
=== Storing Documents ===

The easiest way to store a document in your Couchbase cluster is by calling the '''set()''' method.  In this example we are passing a struct directly in as the value to be stored.  The SDK will automatically serialize the struct into a JSON document for storage in the cluster.    

<source lang="javascript">
client.set(
	ID = 'brad',
	value = { name: 'Brad', age: 33, hair: 'red' } 
);
</source>

The '''ID''' of the document is 'brad' and it will live in the cluster forever until it is deleted.  If I want my document to expire and be automatically removed from the cluster after a certain amount of time, I can specify the '''timeout''' argument.
This document will be cached for 20 minutes before expiring.  Couchbase will automatically remove it for you once it has expired.

<source lang="javascript">
client.set(
	ID = 'cached-site-menus',
	value = menuHTML,
	timeout = 20
);
</source>

=== Storage Durability === 

Couchbase autos-shareds master and replica documents across your cluster out-of-the-box.  Documents are stored both in RAM for fast access and persisted to disk for long term storage.  
By default, all storage operations are asynchrnous which means the '''set()''' call returns potentially before the document is fully stored and replicated.  
This is a break from the consistency offered by a typical RDBMS, but it is key to the high-performance and scalable architecture. See the [http://en.wikipedia.org/wiki/CAP_theorem CAP Theorem]

If your application requires you to confirm that a document has been persisted to disk, use the '''persistTo''' argument.  

If you need to confirm that the document has been copied to a given number replica nodes, use the '''replicateTo''' argument.

The call is still async but returns a Java future object.  Calling the '''get()''' method on the future will wait until the operation is complete.

<source lang="javascript">
// This document will be persisted to disk on at least two nodes
future = client.set(
	ID = 'brad',
	value = { name: 'Brad', age: 33, hair: 'red' },
	persistTo = client.persistTo.TWO, 
	replicateTo = client.persistTo.TWO
);
		 
// IMPORTANT: Wait for the operation to actually complete
future.get()
</source>

<span class="alert alert-info">
'''Note''' : All documents will eventually replicate and persist by themselves.  You only need these options if the application cannot continue without it.
</span>

<p>&nbsp;</p>

There are many other methods for storing data.  Please check the API docs (in the download) to see full descriptions and code samples for all of them.  Here are a few to whet your appetite:

* '''setMulti()''' -  Set multiple documents in the cache with a single operation.
* '''setWithCAS()''' - Update a document only if no one else has changed it since you last retreived it using Compare And Swap (CAS).
* '''touch()''' - "Touch" a document to reset its expiration time.
* '''incr()''' / '''decr()''' -  Increment or Decrement a numeric value
* '''prepend()''' / '''append()''' - add content to the beginning or end of an existing document

=== Retrieving Documents ===

The easiest way to retrieve a specific document by ID from your Couchbase cluster is by calling the '''get()''' method.  

<source lang="javascript">
person = client.get( ID = 'brad' );
</source>

There are many other methods for getting data.  Please check the API docs (in the download) to see full descriptions and code samples for all of them.

* '''asyncGet()''' - Get an object from couchbase asynchronously.
* '''getMulti()''' - Get multiple objects from couchbase with a single call.
* '''getWithCAS()''' - Get an object from couchbase with a special Compare And Swap (CAS) version (for use wit '''setWithCAS()''')
* '''getStats()''' -  Get all of the stats from all of the servers in the cluster.
* '''getDocStats()''' -  Get stats for a specific document ID.

=== Data Serialization ===

Couchbase can literally store anything in a bucket as long as it's represented as a string and no larger than 20MB.  
The CFCouchbase SDK will automatically serialize complex data for you when storing it and deserialize it when you ask for it again.  

You can skip everything below and get the raw data back from Couchbase as a string if you pass ''deserialize=false'' into your '''get()''' method.

Here are the rules for the built-in data marshaller:

* '''JSON Strings''' and other '''Simple Values''' - Will be stored as-is
* '''Structs''' and '''Arrays''' - Will be converted via ''serializeJSON()''
* '''Queries''' - Will be converted to binary with ''objectSave()'' and wrapped in a struct with the following metadata:
** '''type''' - ''cfcouchbase-query''
** '''recordcount''' - The query record count
** '''columnlist''' - The columns in the query

<p>&nbsp;</p>
For '''CFCs''' the following rules will be used:

* If the CFC has a public method '''$serialize''', it will be called and its results saved.  The method must return a string.
* If the CFC has at least one property defined and an annotation called '''autoInflate''', it will be stored as a struct with the following metadata:
** '''type''' - ''cfcouchbase-cfcdata''
** '''data''' -  A struct of property name/values
** '''classpath''' - The name of the CFC
* If the CFC has at least one property defined but no '''autoInflate''' annotation, a struct of property name/values will be stored but without the metdata above.
* All other CFC's will converted to binary with ''objectSave()'' and wrapped in a struct with the following metadata:
** '''type''' - ''cfcouchbase-cfc''
** '''binary''' - A binary representation of the CFC
** '''classpath''' -  - The name of the CFC

In some instances when retrieving CFCs from Couchbase, you will want to have more control over how the object gets created, or perhaps you are using a serialization method that doesn't even track the original component path.
In this case, you can use the inflateTo parameter.  

Pass in a component path and the SDK will instantiate that component and call setters to repopulate it with the data.
   
<source lang="javascript">
person = client.get(
	ID = 'brad',
	inflateTo = 'path.to.person'
);
</source>

If you need even more control such as performing dependency injection, passing construtor args to the CFC, or dynamically choosing the component to create, you can supply a closure that acts as a provider and produces an empty object ready to be populated.

<source lang="javascript">
person = client.get(
	ID = 'brad',
	inflateTo = function( document ){
		// Create object
		var obj = new path.to.person();
		// Special setup
		if( document.role == 'admin' ) {
			obj.setAdmin(true);
		}
		// Autowire object
		wirebox.autowire(obj);
		// Return it
		return obj;
	}
);
</source>


===== Custom Transformers =====

If you don't like how we set up data serialization, or just have super-custom requirements you can provide your own data marshaller to have full control.
Create a CFC that implements the <span class="label">cfcouchbase.data.IDataMarshaller</span> interface.  It only needs to have three methods:

* '''serializeData()''' - Returns the data in a string form so it can be persisted in Couchbase
* '''deserializeData()''' - Received the raw string data from Couchbase and inflates it as neccessary to the original state
* '''setCouchbaseClient()''' - Gives the marshaller a chance to store a local reference to the client in case it needs to talk back.

<span class="label label-info">myDataMarshaller.cfc</span>
<source lang="javascript">
component implements='cfcouchbase.data.IDataMarshaller' {

	any function setCouchbaseClient( required couchcbaseClient ){
		variables.couchbaseClient = arguments.couchcbaseClient;
		return this;
	}

	string function serializeData( required any data ){
		if( !isSimpleValue( data ) ) {
			return serializeJSON( data );
		}
		return data;
	}

	any function deserializeData( required string data, any inflateTo="", boolean deserialize=true ){
		if( isJSON( data ) && deserialize ) {
			return deserializeJSON( data );
		}
		return data;
	}
	
}
</source>

After you have created your custom marshaller, simply pass in an instance of it or the full component path as a config setting:

<source lang="javascript">
couchbase = new cfcouchbase.CouchbaseClient(
	{
		bucketName = 'myBucket',
		dataMarshaller = 'path.to.myDataMarshaller'
	} 
);
</source>

=== Executing Queries ===

One of the most powerful parts of Couchbase Server is the ability to define views (or indexes) on your data and execute queries against your buckets of data.
The minimum information you need to execute a query is the name of the design document and view you wish you use.

<source lang="javascript">
results = client.query( designDocumentName='beer', viewName='brewery_beers' );

for( var result in results ) {
	writeOutput( result.document.name );
	writeOutput( '<br>' );
}
</source>

==== Results ====

This code will return an array of structs for each key in the view.  Each struct will have the following peices of data:
* '''id''' - The unique document id.  Only avaialble on non-reduced queries
* '''document''' - The actual JSON document that was stored.  Only available on non-reduced views
* '''key''' - For non-reduced queries, the key emitted from the map  function.  For reduced views, null.
* '''value''' - For non-reduced queries, the value emitted from the map function. For reduced views, the output of the reduce function.

<p>&nbsp;</p>

==== Query Options ====

You can also pass in a struct of options to control how the query is executed.  Here are some of the most common options.  Please check the API docs for the full list.

{| cellpadding=”5”, class="table table-hover table-striped"
! '''Option''' !! '''Description''' 
|-
|| '''sortOrder''' || Specifies the direction to sort the results based on the map function's "key" value.  Valid values are ASC and DESC.
|-
|| '''limit''' || Number of records to return
|-
|| '''offset''' || Number of records to skip when returning
|-
|| '''reduce''' || Flag to control whether the reduce portion of the view is run. If false, only the results of the map function are returned.
|-
|| '''includeDocs''' || Specifies whether or not to include the entire document in the results or just the key names. Default is false.
|-
|| '''startkey''' || Specify the start of a range of keys to return.
|-
|| '''endkey''' || Specify the end of a range of keys to return.
|-
|| '''group''' || Flag to control whether the results of the reduce function are grouped.
|-
|| '''keys''' || An array of keys to return.  For complex keys, pass each key as an array.
|-
|| '''stale''' || Specifies if stale data can be returned with the view.  Possible values are:
* '''OK''' - (default) - stale data is ok
* '''FALSE''' - force index of view
* '''UPDATE_AFTER''' - potentially returns stale data, but starts an asynch re-index.
|}


<source lang="javascript">
// Return 10 records, skipping the first 20.  Force fresh data
results = client.query( designDocumentName='beer', viewName='brewery_beers', options={ limit = 10, offset = 20, stale = 'FALSE' } );

// Only return 20 records and skip the reduce function in the view
results = client.query( designDocumentName='beer', viewName='by_location', options={ limit = 20, reduce = false } );

// Group results (Will return a single record with the count as the value)
results = client.query( designDocumentName='beer', viewName='brewery_beers', options={ group = true } );

// Start at the specified key and sort descending 
results = client.query( designDocumentName='beer', viewName='brewery_beers', options={ sortOrder = 'DESC', startKey = ["aldaris","aldaris-zelta"] } );
</source>


==== Controlling Query Output ====

Here are some additional parameters to the '''query()''' method to help you control the output.

===== Fiter =====

Specify a closure to the '''filter''' argument that returns true for records that should be included in the final output.

<source lang="javascript">
// Only return breweries
results = client.query(
	designDocumentName = 'beer', 
	viewName = 'brewery_beers', 
	filter = function( row ){
		if( row.document.type == 'brewery' ) {
			return true;
		}
		return false;
	}
);
</source>

===== Transform =====

You can provide custom transformations for each result by passing a closure for '''transform'''.

<source lang="javascript">
results = couchbase.query(
	designDocumentName = 'beer', 
	viewName = 'brewery_beers', 
	deserialize = false,
	transform = function( row ){
		row.document = deserializeJSON( row.document );
	}
);
</source>

===== Return Type =====

You can ask the '''query()''' method to return an array (default), a Java ViewReponse object, or a Java iterator.  
By default we use the cf type which uses transformations, automatic deserializations and inflations.

<source lang="javascript">
// Get an iterator of Java objects
iterator = couchbase.query(
	designDocumentName = 'beer', 
	viewName = 'brewery_beers', 
	returnType = 'Iterator' 
);

while( iterator.hasNex() ) {
	writeOutput( iterator.getNext().getKey() );
}
</source>



=== Managing Views ===

Views define via JavaScript a '''map''' function that populates keys from the data in your bucket.  
Views can also define an addition '''reduce''' function that is used to aggregate data down.  One or more views live inside of a design document.  

Please read more about views in the [http://docs.couchbase.com/couchbase-manual-2.0/#views-and-indexes Couchbase Docs].

You can manage views and design documents from the Couchbase web console and you can also manage them programattically via the SDK as well.  Here's a list of some useful methods:

* '''designDocumentExists()''' - Check for the existance of a design document.
* '''getDesignDocument()''' - Retreive a design document and all its views
* '''deleteDesignDocument()''' - Delete a design document and all its views from the cluster
* '''viewExists()''' - Check for the existance of a single view
* '''saveView()''' - Save/update a view and wait for it to index
* '''asyncSaveView()''' - Save/update a view but don't wait for it to become usable
* '''deleteView()''' - Delete a single view from its design document

The really nice thing about '''saveView()''' and '''asyncSaveView()''' is they either insert or udpate an existing view based on whether it already exists.
They also only save to the cluster if the view doesn't exist or is different.  This means you can repeatedly call saveView() and nothing will happen on any call but the first.

This allows you to specify the views that you need in your application when it starts up and they will only save if neccessary:

<source lang="javascript">
// application start
public boolean function onApplicationStart(){
	application.couchbase = new cfcouchbase.CouchbaseClient( { bucketName="beer-sample" } );
	
	// Specify the views the applications needs here.  They will be created/updated
	// when the client is initialized if they don't already exist or are out of date.
	
	application.couchbase.saveView(
		'manager',
		'listBreweries',
		'function (doc, meta) {
		  if ( doc.type == ''brewery'' ) {
		    emit(doc.name, null);
		  }
		}',
		'_count'
	);
			
	application.couchbase.saveView(
		'manager',
		'listBeersByBrewery',
		'function (doc, meta) {
		  if ( doc.type == ''beer'' ) {
		    emit(doc.brewery_id, null);
		  }
		}',
		'_count'
	);
			
	return true;
}
</source>


=== Working with Futures ===

You have probably noticed that all the asyncronous operations in the SDK return a Java [http://www.couchbase.com/autodocs/couchbase-java-client-1.0.3/net/spy/memcached/internal/OperationFuture.html OperationFuture] object.
This allows control of your application to return immediately to your code without waiting for the remote calls to complete.  The '''future''' object gives you a window into whats going on and you can elect to monitor the progress on your terms-- deciding how long you're willing to wait-- or ignore it entirely in order to complete the request as quickly as possible.

The most common method is '''get()'''.  Calling this will instruct your code to wait until th eoperation is complete before continuing.  Calling future.get() essentially makes an ''ansynchronou'' call ''syncronous''.   

<source lang="javascript">
future = client.asyncGet( ID = 'brad' );
person = future.get();
</source>

OperationFutures are parameterized which means they can each return a different data type from their get().  Check the API docs to see what each asynchronous future returns.

<span class="alert alert-info">
'''Note''' : Operations are always subject to the timeouts configured for the client regardless of how you interact with the future.
</span>

<p>&nbsp;</p>

Here are some other methods you can call on a future to handle the response on your terms:

* '''cancel()''' - Cancel this operation, if possible.
* '''getStatus()''' - Get the current status of this operation.
* '''isDone()''' - Whether or not the Operation is done and result can be retrieved with get().
* '''get(duration, units)''' - Get the results of the given operation, but specify how long you're willing to wait.

More information on Futures is available here in the Java Docs: [http://www.couchbase.com/autodocs/couchbase-java-client-1.0.3/net/spy/memcached/internal/OperationFuture.html OperationFuture]

== Help & Support ==

If you need any help related to our ProfileBox product, you can use our online help group at http://groups.google.com/group/coldbox .  If you need any type of custom consulting or support package hours, please contact us at [mailto:consulting@ortussolutions.com consulting@ortussolutions.com] or visit
us at [http://www.ortussolutions.com www.ortussolutions.com].
