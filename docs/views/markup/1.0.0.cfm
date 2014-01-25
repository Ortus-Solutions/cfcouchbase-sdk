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

=== Basic operations ===

=== Data marshalling ===

=== Working with Views ===

== Help & Support ==

If you need any help related to our ProfileBox product, you can use our online help group at http://groups.google.com/group/coldbox .  If you need any type of custom consulting or support package hours, please contact us at [mailto:consulting@ortussolutions.com consulting@ortussolutions.com] or visit
us at [http://www.ortussolutions.com www.ortussolutions.com].
