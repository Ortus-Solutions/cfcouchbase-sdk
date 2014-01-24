<div class="header">
= CFCouchbase SDK =
</div>
	
CFCouchbase is a library designed to make it easy for applications written in CFML to integrate with [http://www.couchbase.com Couchbase Server] for caching and NoSQL.

<p>&nbsp;</p>

<blockquote>
Interactive applications have changed dramatically over the last 15 years, and so have the data management needs of those apps. Today, three interrelated megatrends - Big Data, Big Users, and Cloud Computing - are driving the adoption of NoSQL technology. NoSQL is increasingly considered a viable alternative to relational databases...
<small>[http://www.couchbase.com Couchbase]</small>
</blockquote>

<p>&nbsp;</p>

<div class="well well-small text-center">
<img src="includes/images/monitor_graph.png" class="img-polaroid"/>
<p>ProfileBox</p>
</div>

== Requirements ==

* Couchbase Server 1.8+
* ColdFusion 9.01+
* Railo 4.0+

== Features In A Nutshell ==

* Lightweight, standalone library can be used with any application
* High performance, asynchronous calls   
* Easily configurable
* Fully-featured API incluides view management and execution
* Built on the official Java SDK, but customized to take advantage of CFML


== Installation ==

The CFCouchase SDK is contained in a single folder.  The easiest way to install it is to copy "cfcouchbase" in the web root.  For a more secure installation, place it outside the web root and create a mapping called "cfcouchbase".   

<source lang="javascript">
this.mappings[ "/cfcouchbase" ] = "C:\path\to\cfcouchbase";
</source>

Now that the code is in place, all you need to do is create an instance of <span class="label label-info">cfcouchbase.CouchbaseClient</span> for each bucket you want to connect to.  
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
<strong>Important</strong>: Each Couchbase bucket operates independantly and ues its own authenication.  You need an instance of '''CouchbaseClient''' for each bucket.  
</div>

== Configuration ==

The default configuration for CFCouchbase is located in <span class="label label-info">cfcouchbase.config.CouchbaseConfig</span>.  You can create the CouchbaseClient with no configuration and it will connect to the "default" bucket on localhost.

There are 3 ways to pass configuration into the CouchbaseClient.

* Pass a config struct directly into client constructor
* Pass an instance of a config CFC into the client constructor
* Pass the path to a config CFC to the client constructor

<p>&nbsp;</p>

<span class="alert alert-info">
'''Note''' : The config CFC is the most contained and portable way to store your configuration.
</span>

<p>&nbsp;</p>


=== Config Struct ===

=== Config CFC instance ===

=== Config CFC path ===

{| cellpadding=”5”, class="table table-hover table-striped"
! '''Setting''' !! '''Type''' !! '''Default''' !! '''Description''' 
|-
|| '''licenseKey''' || string || --- || The license key for your server provided at purchase time
|-
|| '''licenseEmail''' || string || --- || The email you used to purchase your server license
|-
|| '''profileHandlers''' || boolean ||  true || Profiles ColdBox events
|}


== Usage ==

=== Basic operations ===

=== Data marshalling ===

=== Working with Views ===

== Help & Support ==

If you need any help related to our ProfileBox product, you can use our online help group at https://groups.google.com/a/ortussolutions.com/forum/#!forum/profilebox.  If you need any type of custom consulting or support package hours, please contact us at [mailto:consulting@ortussolutions.com consulting@ortussolutions.com] or visit
us at [http://www.ortussolutions.com www.ortussolutions.com].
