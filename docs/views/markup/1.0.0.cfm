<div class="header">
= Ortus ProfileBox =
</div>
	
Ortus ProfileBox is a ColdBox module that will provide you with profiling, metrics, CacheBox reports, exception notifications, LogBox integration and much more for any ColdBox 3.5 application via Integral's [http://www.fusion-reactor.com/fr/ FusionReactor] server monitor application for both Adobe ColdFusion and Railo.

<p>&nbsp;</p>

<blockquote>
FusionReactor is a professional server monitor for Java application servers such as Tomcat, JBoss and WebSphere and is recommended for monitoring Adobe ColdFusion and Railo.

FusionReactor continuously monitors and gathers metrics on your production servers, so you can diagnose and analyze, server and application issues. Keep servers alive with FusionReactor's unattended monitoring to maintain server availability and safeguard against server crashes.
<small>[http://www.fusion-reactor.com/fr/ Integral Gmbh]</small>
</blockquote>

<p>&nbsp;</p>

<div class="well well-small text-center">
<img src="includes/shots/pb_requests.png" class="img-polaroid"/>
<p>ProfileBox</p>
</div>

== Requirements ==

* FusionReactor 5
* ColdFusion 9.01 and above
* Railo 4.1.0.001 and above

== Features In A Nutshell ==

* Profile and take metrics of any ColdBox Event including ability to trace hierarchical executions, renderings and handler results
* Profile ColdBox User Experience metrics from time spent in ColdBox code, to Client Code to Network time
* Profile rendering of any layout or view
* Ability to trace the request collections via any ColdBox event requested
* Ability to profile any WireBox-managed object via our very own method and component annotations
* LogBox appender for creating FusionReactor notifications
* LogBox appender for creating FusionReactor request tracers
* WireBox mappings for interacting with FusionReactor tracers and notifications a-la-carte
* Ability to profile all caches monitored by CacheBox
* Exception handling that can send your exceptions to the FusionReactor Notifications
* Much more

<div class="well well-small text-center">
<img src="includes/shots/pb_cachebox.png" class="img-polaroid"/>
<p>CacheBox Monitoring</p>
</div>

<div class="well well-small text-center">
<img src="includes/shots/pb_longest.png" class="img-polaroid"/>
<p>Longest ColdBox Requests</p>
</div>

<div class="well well-small text-center">
<img src="includes/shots/pb_userexperience.png" class="img-polaroid"/>
<p>User Experience Tracking</p>
</div>

<div class="well well-small text-center">
<img src="includes/shots/pb_notifications.png" class="img-polaroid"/>
<p>Notifications</p>
</div>


== Installation ==

ProfileBox is installed as a ColdBox Module into ANY ColdBox 3.5 application and above.  

<div class="well well-small text-center">
<img src="includes/shots/pb_installation.png" class="img-polaroid"/>
<p>ProfileBox Module Installed</p>
</div>

<div class="alert">
<strong>Important</strong>: FusionReactor must be installed and monitoring the same CFML instance as well.  
</div>

Once the module is installed you will need to install your server license key and email information into the 
<span class="label label-info">/modules/fr-profilebox/config/settings.json.cfm</span> file.  Please look at our configuration section for more information.

<source lang="javascript">
{
	"licenseKey" : "",
	"licenseEmail" : ""
}
</source>

<div class="alert alert-error">
<strong>Important</strong>: Please note that ProfileBox is licensed on a per physical or virtual server and each module installation must contain the license key and the email used to purchase the license in order to activate your server for ProfileBox monitoring.
</div>

Once the module is installed and your application is restarted or started for the first time you will be able to access all of the profiling information via the FusionReactor administration console.  ProfileBox will also register a notification that it is up and running.

<div class="well well-small text-center">
<img src="includes/shots/pb_loaded.png" class="img-polaroid"/>
<p>ProfileBox Loaded Notification</p>
</div>



== Configuration ==

ProfileBox has some configuration settings that can alter its behavior and you do this in our configuration file that can be located at 
<span class="label label-info">/modules/fr-profilebox/config/settings.json.cfm</span>.

<p>&nbsp;</p>

<span class="alert alert-info">
'''Note''' : The JSON file is actually a cfm extension so it cannot be viewed or executed for security purposes
</span>

<p>&nbsp;</p>

<source lang="javascript">
{
	"licenseKey" : "",
	"licenseEmail" : "",
	"profileHandlers" : true,
	"handlerRegex" : "handlers.*",
	"profileViews" : false,
	"profileObjects" : false,
	"traceCollections" : false,
	"traceObjectResults" : false,
	"traceHandlerResults" : false,
	"traceAppender" : false,
	"notifyAppender" : false,
	"notifyExceptions" : true,
	"userExperienceTracking" : true,
	"profileCacheBox" : true,
	"profileCacheBoxFrequency" : 2,
	"useTrackedTransaction" : true
}
</source>

From here you will be able to configure the following settings:

{| cellpadding=”5”, class="table table-hover table-striped"
! '''Setting''' !! '''Type''' !! '''Default''' !! '''Description''' 
|-
|| '''licenseKey''' || string || --- || The license key for your server provided at purchase time
|-
|| '''licenseEmail''' || string || --- || The email you used to purchase your server license
|-
|| '''profileHandlers''' || boolean ||  true || Profiles ColdBox events
|-
|| '''handlerRegex''' || regex || ''handlers.*'' || The regular expression used match against the handlers you want to profile.  By default, it mostly profiles all application handlers
|-
|| '''profileViews''' || boolean || true || Profiles ColdBox renderings using ''renderView, renderExternalView and renderLayout''
|-
|| '''profileObjects''' || boolean || false || If activated it will profile the methods that are annotated with '''profile''' or profile ALL methods in a component that is annotated with '''profile''' 
|-
|| '''traceObjectResults''' || boolean || false || If enabled it will trace the results to FusionReactor from the objects that where annotated to be profiled
|-
|| '''traceCollections''' || boolean || false || By default ProfileBox will send the PRC and RC collections at the end of the request to the request profiler
|-
|| '''traceHandlerResults''' || boolean || false || If enabled, ProfileBox will trace the results of any handler call as properties of the request
|-
|| '''traceAppender''' || boolean || false || If enabled, it will attach this appender to your LogBox configuration
|-
|| '''notifyAppender''' || boolean || false || If enabled, it will attach this appender to your LogBox configuration
|-
|| '''notifyExceptions''' || boolean || true || Whenever global exceptions occur in your system, ProfileBox will send the exception as a FusionReactor Notification
|-
|| '''userExperienceTracking''' || boolean || true || If enabled, ProfileBox will send the FusionReactor monitoring JavaScript to your UI for non-ajax requests so FusionReactor can monitor your user experience.
|-
|| '''profileCacheBox''' || boolean || true || If enabled, ProfileBox will send metrics of all the caches you have defined in your CacheBox configuration
|-
|| '''profileCacheBoxFrequency''' || minutes || 2 || The frequency that ProfileBox should send statistics about the caches to FusionReactor
|-
|| '''useTrackedTransaction''' || boolean || true || Switch between FusionReactor base transactions or tracked transactions.  The difference is only that Base Transactions do not track samples for the activity and execution time for graphs. Base Transactions still have a history, slowest and longest etc as do Tracked Transactions, but Tracked Transactions produces activity and execution sample graphs and is more memory intensive but cooler!
|}


== Usage ==

Once you have installed ProfileBox and activated it via its license you will be able to log into FusionReactor and see different metrics, notifications, charts and much more.  Let's start investigating what you can do.

<div class="alert">
'''Important''' : Please note that the more you profile the slower your application can get. So please be conscious about what you decide to profile especially in Production environments.  Try the different profiling settings and combinations to produce the needed results.
</div>


=== Event/View Profiling ===

ProfileBox will profile all your application's handler events and view/layout renderings by default.  You can change the regular expression via the <span class="label">handlerRegex</span> setting to meet your liking for choosing which events will be profiled.  You can also deactivate the view profiling via the <span class="label">profileViews</span> setting.

<source lang="javascript">
{
	"profileHandlers" : true,
	"handlerRegex" : "handlers.*",
	"profileViews" : true,
	"traceCollections" : true,
	"traceHandlerResults" : false,
}
</source>

What this profiling will do is tell FusionReactor when a new ColdBox request starts.  It will then monitor all internal events, ORM transactions, and even view renderings within a request; which are called transactions.  At the end of the request if <span class="label">traceCollections</span> is enabled, it will record the PRC and RC collections for you alongside metadata about the request.

<div class="well well-small text-center">
<img src="includes/shots/pb_nestedtransactions.png" class="img-polaroid"/>
<p>ProfileBox Event Transactions</p>
</div>

You can also click on the view icon and get an in-depth overview of the ColdBox request with 4 main tabs: 

* '''Main''' : Shows you the main memory and aspects of the ColdBox request
* '''Properties''' : All the ColdBox metadata about the request including the tracing of the collections
* '''Relations''' : All the different sub-transactions this ColdBox request created such as nested ''runEvents()'', rendering of views, etc
* '''Transit''' : FusionReactor transit statistics

<div class="well well-small text-center">
<img src="includes/shots/pb_coldboxrequest_details.png" class="img-polaroid"/>
<p>ColdBox Request Details</p>
</div>

<div class="well well-small text-center">
<img src="includes/shots/pb_coldboxrequest.png" class="img-polaroid"/>
<p>ColdBox Request Relations</p>
</div>

You can delve deeper into each of these relational transactions and see the timing and profiling of each event and view rendering as well.  The view details tells you how long a view took to render and what arguments it received in order to be rendering.  If you did a-la-carte renderings with ColdBox using <span class="label label-info">renderView(), renderLayout() or renderExternalView()</span> they will all be profiled so you can inspect them at a later point in time.


<div class="well well-small text-center">
<img src="includes/shots/pb_coldboxrequest_viewdata.png" class="img-polaroid"/>
<p>ColdBox Request View Rendering</p>
</div>


<p>&nbsp;</p>
----
<p>&nbsp;</p>

=== Event/View Metrics ===

FusionReactor also allows you to view metric snapshots of your running events and views in their '''Metrics > Metrics''' section:

<div class="alert alert-error">
'''Important''' : Metric graphs are only available if you have enabled '''tracked transactions''' in your configuration file via the <span class="label">useTrackedTransaction=true</span> setting. If not, metrics will NOT be available.
</div>

<div class="well well-small text-center">
<img src="includes/shots/pb_frmetrics.png" class="img-polaroid"/>
<p>FusionReactor Metrics</p>
</div>

This will allow you to select a specific event or view and get real-time feedback of:

* <nowiki>#</nowiki>Requests/sec
* Avg Time
* Heap Memory
* CPU
* Overview Stats
* Much More


<div class="well well-small text-center">
<img src="includes/shots/pb_eventmetrics.png" class="img-polaroid"/>
<p>Event Metrics</p>
</div>

<p>&nbsp;</p>
----
<p>&nbsp;</p>

=== Activity Reports & Graphs ===

If event profiling is enabled you will be able to monitor the activity for all profiled events and views in the FusionReactor '''transactions''' panel:

<div class="well well-small text-center">
<img src="includes/shots/pb_transactionspanel.png" class="img-polaroid"/>
<p>Transactions Panel</p>
</div>

From here you will be able to see the following:

* '''Activity''' : See the activity of current running requests, events and even view renderings
* '''History''' : See the historical activity of events and view renderings
* '''Activity Graph''' : Graph the activity of specific events and view renderings
* '''Time Graph''' : Graph the time spent in specific events and view renderings
* '''Longest Requests''' : View the longest time spent in events and view renderings
* '''Slow Requests''' : View the slowest running and finished events and view renderings
* '''Transit''' : View all activity around events and view renderings

Below you can see many screenshots of all the different types of reports and graphics you can get out of the event/view profiling.


<div class="well well-small text-center">
<img src="includes/shots/pb_eventactivity_running.png" class="img-polaroid"/>
<p>Running Event Activity</p>
</div>

<div class="well well-small text-center">
<img src="includes/shots/pb_eventactivity.png" class="img-polaroid"/>
<p>Historical Event Activity</p>
</div>

<div class="well well-small text-center">
<img src="includes/shots/pb_eventmetrics.png" class="img-polaroid"/>
<p>Running Event Metrics</p>
</div>

<div class="well well-small text-center">
<img src="includes/shots/pb_longest.png" class="img-polaroid"/>
<p>Longest Event Activity</p>
</div>


<p>&nbsp;</p>
----
<p>&nbsp;</p>

=== User Experience ===

ProfileBox will allow you to monitor your user experience by enabling it via the <span class="label">userExperienceTracking</span> setting.  This will output to the browser a small JavaScript file for all non-ajax request that will send information back into FusionReactor for live monitoring and historical tracking.  You will see something like the following in your head section.

<source lang="javascript">
<script>
var anUrl = "/fusionreactor/UEM.cfm?db=0&wr=3044&s=58D82DF3AB0274AB47234EC447957F3A&t=1701";
document.write(unescape("%3Cscript src='/fusionreactor/UEMJS.cfm' type='text/javascript'%3E%3C/script%3E"));
</script>
</source>


This tracking will provide you with the following statistics:

* '''DB Time''' : Time spent in the database including ORM operations
* '''WebRequest Time''' : Time spent in ColdFusion and ColdBox
* '''Network Time''' : Time in transit
* '''Client Time''' : Time spent in the browser to render

<div class="well well-small text-center">
<img src="includes/shots/pb_userexperience.png" class="img-polaroid"/>
<p>User Experience Tracking</p>
</div>


<p>&nbsp;</p>
----
<p>&nbsp;</p>


=== CacheBox Profiling ===

ProfileBox can also enable the profiling of certain metrics of all the caches registered within CacheBox for your given ColdBox application.  You will enable this via the <span class="label">profileCacheBox</span> setting and you can also control the frequency in which they are stored using the <span class="label">profileCacheBoxFrequency</span> setting.

<source lang="javascript">
{
	"profileCacheBox" : true,
	"profileCacheBoxFrequency" : 2
}
</source>

<div class="alert alert-info">
The <span class="label">profileCacheBoxFrequency</span> setting value is in minutes.  This means that snapshots of the caches will be evaluated at a minimum interval of this setting in minutes.  The default is 2 minutes.
</div>

You will be able to find the metrics and graphs for CacheBox in the '''Metrics''' section under '''Custom Series''':

<div class="well well-small text-center">
<img src="includes/shots/pb_frmetrics.png" class="img-polaroid"/>
<p>FusionReactor Metrics</p>
</div>

Once this is registered it will profile for you the following statistics for each registered cache provider:

* '''hits''' : The number of hits into the cache
* '''misses''' : The number of misses into the cache
* '''performance ratio''' : The performance ratio of hits/misses in your cache
* '''size''' : The number of items in the cache
* '''gc''' : The number of Java garbage collections when using soft references caches
* '''evictions''' : The number of objects evicted using the eviction policies


<div class="alert alert-info">
ProfileBox will create a hierarchy based on the application you are profiling: <span class="label">/cachebox/{application name}/{provider name}/{statistic}</span>
</div>


<div class="well well-small text-center">
<img src="includes/shots/pb_cachebox_dropdown.png" class="img-polaroid"/>
<p>CacheBox Metrics Chooser</p>
</div>

<div class="well well-small text-center">
<img src="includes/shots/pb_cachebox.png" class="img-polaroid"/>
<p>CacheBox Metrics</p>
</div>


<p>&nbsp;</p>
----
<p>&nbsp;</p>


=== Object Profiling ===

ProfileBox will allow you to profile any CFC managed by WireBox via AOP and annotations.  Out of the box it will inspect objects that have been annotated with the keyword <span class="label label-info">profile</span> in the <span class="label label-info">cfcomponent</span> and <span class="label label-info">cffunction</span> tags.  The setting that enables object profiling is <span class="label">profileObjects</span> which allows the timing of methods and also the setting <span class="label">traceObjectResults</span> which will trace the results of such functions into FusionReactor.

==== Profile All Methods ====

If you annotate your component with <span class="label label-info">profile</span> then ProfileBox will profile ALL the methods in the CFC; public and private by default.

<source lang="coldfusion">
<cfcomponent name="Service" output="False" profile>
...	
</cfcomponent>


component profile{
	
}
</source>

You can also give the <span class="label label-info">profile</span> annotation a value and that will be the name of the transaction that will come up in FusionReactor, graphs, metrics and much more.  By default it will use the name of the object + the name of the method.

<source lang="coldfusion">
<cfcomponent name="Service" output="False" profile="userService">
...	
</cfcomponent>


component profile="userService"{
	
}
</source>

==== Profile Some Methods ====

If you annotate your functions with <span class="label label-info">profile</span> then ProfileBox will profile the method whether its public or private:

<source lang="coldfusion">
<cffunction name="save" output="False" returntype="any" access="public" profile>
...	
</cffunction>


public function save(required user) profile{
	
}
</source>

You can also give the <span class="label label-info">profile</span> annotation a value and that will be the name of the transaction that will come up in FusionReactor, graphs, metrics and much more.  By default it will use the name of the object + the name of the method.

<source lang="coldfusion">
<cffunction name="save" output="False" returntype="any" access="public" profile="userservice.save">
...	
</cffunction>


public function save(required user) profile="userservice.save"{
	
}
</source>

<div class="alert">
'''Important''': Make sure you use unique names when choosing your profile keys as if you are profiling more than 1 application, you won't want overlaps or false positives.
</div>


==== Custom Profiling ====

You can also do custom profiling with ProfileBox since we give you access to the WireBox AOP Aspect.  So you can bind the aspect to any CFC that matches your own personal criteria.  Below is the actual matcher we use internally which you can season to your own liking in your application's WireBox configuration.  The name of the aspect we register is called <span class="label">FRObjectProfiler</span>.

<source lang="coldfusion">
// Bind Object Aspects to monitor all a-la-carte profilers via method and component annotations
binder.bindAspect(classes=binder.match().any(),
		methods=binder.match().annotatedWith( "profile" ),
		aspects="FRObjectProfiler");
binder.bindAspect(classes=binder.match().annotatedWith( "profile" ),
		methods=binder.match().any(),
		aspects="FRObjectProfiler");
</source>



<p>&nbsp;</p>
----
<p>&nbsp;</p>


=== Exception Notifications ===

ProfileBox by default will intercept all exceptions that occur in your application and send them to the notifications area of FusionReactor with the exception information.  This is controlled by the <span class="label">notifyExceptions</span> setting.


<div class="well well-small text-center">
<img src="includes/shots/pb_exceptions.png" class="img-polaroid"/>
<p>Exception Tracking</p>
</div>



<p>&nbsp;</p>

== LogBox Integration ==

ProfileBox also allows you to integrate your application's logging capabilities via LogBox so it can talk to FusionReactor via ''notifications'' and ''tracers''.


<div class="well well-small text-center">
<img src="includes/shots/pb_tracers.png" class="img-polaroid"/>
<p>Tracers</p>
</div>

<div class="well well-small text-center">
<img src="includes/shots/pb_notifications.png" class="img-polaroid"/>
<p>Notifications</p>
</div>

<p>&nbsp;</p>
----
<p>&nbsp;</p>

=== Tracer Appender ===

We have created the '''TracerAppender''' that will send traces to FusionReactor and they will appear in the '''traces''' tab within a request monitor.  If you enable the <span class="label">tracerAppender</span> setting, then ProfileBox will automatically register the appender for you in your application with the name of <span class="label">fr_tracer</span> and attach it ONLY to the ''root'' logger with a min level of '''fatal''' and max level of '''info'''.  However, if you want more control in the levels it logs and to what categories it will be attached, it will be up to you to register it manually:


<source lang="coldfusion">
//LogBox DSL
logBox = {
	// Define Appenders
	appenders = {
		fr_tracer = { class="myapp.modules.fr-profilebox.logbox.TracerAppender" }
	},
	// Root Logger
	root = { levelmax="INFO", appenders="*" },
	// Implicit Level Categories
	info = [ "coldbox.system" ]
};
</source>


<p>&nbsp;</p>
----
<p>&nbsp;</p>

=== Notify Appender ===

We have created the '''NotifyAppender''' that will send notifications to FusionReactor.  If you enable the <span class="label">notifyAppender</span> setting, then ProfileBox will automatically register the appender for you in your application with the name of <span class="label">fr_notify</span> and attach it ONLY to the ''root'' logger with a min level of '''fatal''' and max level of '''info'''.  However, if you want more control in the levels it logs and to what categories it will be attached, it will be up to you to register it manually:


<source lang="coldfusion">
//LogBox DSL
logBox = {
	// Define Appenders
	appenders = {
		fr_notify = { class="myapp.modules.fr-profilebox.logbox.NotifyAppender" }
	},
	// Root Logger
	root = { levelmax="INFO", appenders="*" },
	// Implicit Level Categories
	info = [ "coldbox.system" ]
};
</source>


<p>&nbsp;</p>

== Tracers & Notifications API ==

ProfileBox also registers two objects with WireBox that will allow you to send tracers and notifications to FusionReactor a-la-carte.  The mappings are:

* '''FRNotify''' : Notify API
* '''FRTrace''' : Tracer API

=== Trace ===

The trace API is very easy to use as it has only one method: <span class="label label-info">trace(required message)</span>

<source lang="coldfusion">
getModel("FRTrace").trace( "message" );
</source>


=== Notify ===

The notify API is very easy to use as well and it has three methods: <span class="label label-info">info(), warning(), error()</span> each taking three arguments to it:

* '''title''' : Title of your notification
* '''message''' : The message of the notification
* '''origin''' : Where the message came from

<source lang="coldfusion">
getModel("FRNotify").info( title="A new order has been made!", message="What up ProfileBox", origin="MyService" );
getModel("FRNotify").warning( title="Credit card denied", message="What up ProfileBox", origin="MyService" );
getModel("FRNotify").error( title="An error ocurred, oopsy", message="What up ProfileBox", origin="MyService" );
</source>


== Help & Support ==

If you need any help related to our ProfileBox product, you can use our online help group at https://groups.google.com/a/ortussolutions.com/forum/#!forum/profilebox.  If you need any type of custom consulting or support package hours, please contact us at [mailto:consulting@ortussolutions.com consulting@ortussolutions.com] or visit
us at [http://www.ortussolutions.com www.ortussolutions.com].
