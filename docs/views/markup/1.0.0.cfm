<div class="header">
= CFCouchbase SDK =
</div>
	
CFCouchbase is a client library designed to make it easy for applications written in CFML to integrate with [http://www.couchbase.com Couchbase Server] for caching and NoSQL.  
Here is a quick sample showing how easy it is to work with the Couchbase SDK.


<source lang="javascript">
// Create the client
client  = new cfcouchbase.CouchbaseClient();

// Create a document in the cluster
client.set( 'brad', { name: "Brad", age: 33, hair: "red" } );

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
this.mappings[ "/cfcouchbase" ] = "C:\path\to\cfcouchbase";
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
|}


=== Config Struct ===

The simplest way to get started using the SDK is to simply pass a struct of config settings into the constructor when you create the client.

<source lang="javascript">
couchbase = new cfcouchbase.CouchbaseClient(
	{
		servers = ['http://cache1:8091','http://cache2:8091'],
		bucketName = "myBucket",
		bucketName = "myPass"
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
		bucketName = "myBucket";
		bucketName = "myPass";
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
	value = { name: "Brad", age: 33, hair: "red" } 
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
	value = { name: "Brad", age: 33, hair: "red" },
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

=== Working with Views ===

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
