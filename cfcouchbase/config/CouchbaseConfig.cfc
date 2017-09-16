/**
* <strong>Copyright Since 2005 Ortus Solutions, Corp</strong><br>
* <a href="http://www.ortussolutions.com">www.ortussolutions.com</a>
* <p>The Couchbase Client Configuration Object</p>
* @author Luis Majano, Brad Wood, Aaron Benton
*/
component accessors="true"{

  //****************************************************************************************
  // CFCouchbase Client Specific Configuration Properties
  //****************************************************************************************

  /**
  * By default we class load all the Couchbase SDK, if false, then the SDK library must be in the servlet library path
  */
  property name="useClassLoader" default="true" type="boolean";
  /**
  * The data marshaller to use for serializations and deserializations, please put the class path or the instance of the
  * marshaller to use. Please remember that it must implement our interface: cfcouchbase.data.IDataMarshaller
  */
  property name="dataMarshaller" default="";
  /**
  * The default timeout of records sent to Couchbase for storage in minutes. 0 means persist forever.
  */
  property name="defaultTimeout" default="0" type="numeric";
  /**
  * The default value for keys / document ids.  The initial value is false, in this setting all keys are
  * automatically lowercased for set / get / view operations
  */
  property name="caseSensitiveKeys" default="false" type="boolean";

  //****************************************************************************************
  // Couchbase Configuration Properties
  //****************************************************************************************

  /**
  * The list of servers to connect to
  */
  property name="servers" default="127.0.0.1";
  /**
  * The bucketname to connect to
  */
  property name="bucketName" default="default";
  /**
  * The optional password of the bucket
  */
  property name="password" default="";

  //****************************************************************************************
  // Couchbase Environment Configuration Properties
  // http://developer.couchbase.com/documentation/server/4.0/sdks/java-2.2/env-config.html
  //****************************************************************************************

  // Bootstrapping options
  /**
  * If encrypted communication should be enabled. This feature is only available against a Couchbase Server 3.0 EE cluster
  * or later. Please see the "Connection Management" section for more details on how to set it up properly.
  */
  property name="sslEnabled" default="false" type="boolean";
  /**
  * The location to the JVM keystore where the certificates are stored. This feature is only available against a Couchbase
  * Server 3.0 EE cluster or later. See the "Connection Management" section for more details on how to set it up properly.
  * java.lang.String SSL_KEYSTORE_FILE
  */
  property name="sslKeystoreFile" default="";
  /**
  * The password of the JVM keystore where the certificates are stored. This feature is only available against a Couchbase
  * Server 3.0 EE cluster or later. Please see the "Connection Management" section for more details on how to set it up
  * properly. java.lang.String SSL_KEYSTORE_PASSWORD
  */
  property name="sslKeystorePassword" default="";
  /**
  * If experimental support for N1Ql should be enabled. Note that this setting is going to be deprecated as soon as the
  * server comes with N1QL embedded, because it will be advertised and picked up by the SDK automatically. This setting
  * should only be used to explicitly enable the N1QL service against a standalone N1QL. In addition, every Couchbase
  * Server node in the cluster is expected to run a N1QL instance when this flag is enabled.
  * ** DEPRECATED **
  */
  property name="queryEnabled" default="true" type="boolean";
  /**
  * Defines the port for the experimental N1QL support when enabled. Every node in the cluster is expected to run a
  * N1QL service against this port. This setting is going to be deprecated as soon as the server comes with N1QL
  * embedded, because it will be advertised and picked up by the SDK automatically. This setting should only be used
  * to explicitly enable the N1QL service against a stand-alone N1QL.
  * ** DEPRECATED **
  */
  property name="queryPort" default="8093" type="numeric";
  /**
  * If it should be possible for the client to bootstrap and grab configurations over the HTTP port 8091 (and also attach
  * a streaming connection). If you are running Couchbase Server 2.2 or earlier, this setting must be set to true. Against
  * newer clusters it can be disabled, but it doesn't hurt to keep it enabled as a last-resort fallback option. Also, if
  * configuration loading through carrier publication is manually disabled, this option is used as a fallback. If both
  * option are disabled, the client is not able to function properly. If you don't have a good reason to disable it (for
  * example as instructed by Couchbase Support), keep it enabled.
  */
  property name="bootstrapHttpEnabled" default="true" type="boolean";
  /**
  * The port which is used if encryption is not enabled and the client needs to bootstrap through HTTP. In general, there
  * is no need to change this value (unless you run a custom Couchbase Server build during development or testing that
  * runs on different ports).
  */
  property name="bootstrapHttpDirectPort" default="8091" type="numeric";
  /**
  * The port which is used if encryption is enabled and the client needs to bootstrap through HTTP. In general, there is
  * no need to change this value (unless you run a custom Couchbase Server build during development or testing that runs
  * on different ports).
  */
  property name="bootstrapHttpSslPort" default="18091" type="numeric";
  /**
  * If you are running Couchbase Server 2.5 or later, this is the preferred way to bootstrap and grab configurations. It is
  * not done over HTTP, but through the key-value connections automatically. If this setting is manually disabled, the
  * client will fallback to HTTP (if enabled). If both option are disabled, the client is not able to function properly. If
  * you don't have a good reason to disable it (for example as instructed by Couchbase Support), keep it enabled.
  */
  property name="bootstrapCarrierEnabled" default="true" type="boolean";
  /**
  * The port which is used if encryption is not enabled and the client needs to bootstrap through carrier publication. In
  * general, there is no need to change this value (unless you run a custom Couchbase Server build during development or
  * testing that runs on different ports).
  */
  property name="bootstrapCarrierDirectPort" default="11210" type="numeric";
  /**
  * The port which is used if encryption is enabled and the client needs to bootstrap through carrier publication. In general,
  * there is no need to change this value (unless you run a custom Couchbase Server build during development or testing that
  * runs on different ports).
  */
  property name="bootstrapCarrierSslPort" default="11207" type="numeric";
  /**
  * Enable manually if you explicitly want to grab a bootstrap node list through a DNS SRV record. See the "Connection
  * Management" section for more information on how to use it properly.
  */
  property name="dnsSrvEnabled" default="false" type="boolean";
  /**
  * If mutation tokens should be enabled, adding more overhead to every mutation but providing enhanced durability
  * requirements as well as advanced N1QL querying capabilities.
  */
  property name="mutationTokensEnabled" default="false" type="boolean";

  // Timeout options
  /**
  * The Key/Value default timeout (milliseconds) is used on all blocking operations which are performed on a specific
  * key if not overridden by a custom timeout. It does not affect asynchronous operations. This includes all commands
  * like get(), getFromReplica() and all mutation commands.
  */
  property name="kvTimeout" default="2500" type="numeric";
  /**
  * The View timeout (milliseconds) is used on both regular and geospatial view operations if not overridden by a custom
  * timeout. It does not affect asynchronous operations. Note that it is set to such a high timeout compared to key/value
  * since it can affect hundreds or thousands of rows. Also, if there is a node failure during the request the internal
  * cluster timeout is set to 60 seconds.
  */
  property name="viewTimeout" default="75000" type="numeric";
  /**
  * The Query timeout (milliseconds) is used on all N1QL query operations if not overridden by a custom timeout. It
  * does not affect asynchronous operations. Note that it is set to such a high timeout compared to key/value since
  * it can affect hundreds or thousands of rows.
  */
  property name="queryTimeout" default="75000" type="numeric";
  /**
  * The connect timeout (milliseconds) is used when a Bucket is opened and if not overridden by a custom timeout. It
  * does not affect asynchronous operations. If you feel the urge to change this value to something higher, there is
  * a good chance that your network is not properly set up. Opening a bucket should in practice not take longer than
  * a second on a resonably fast network.
  */
  property name="connectTimeout" default="5000" type="numeric";
  /**
  * The disconnect timeout (milliseconds) is used when a Cluster is disconnect or a Bucket is closed synchronously and
  * if not overridden by a custom timeout. It does not affect asynchronous operations. A timeout is applied here always
  * to make sure that your code does not get stuck at shutdown. 25 seconds should provide enough room to drain all
  * outstanding operations properly, but make sure to adapt this timeout to fit your application requirements.
  */
  property name="disconnectTimeout" default="25000" type="numeric";
  /**
  * The management timeout is used on all synchronous BucketManager and ClusterManager operations and if not overridden
  * by a custom timeout. It set to a quite high timeout because some operations might take a longer time to complete
  * (for example flush).
  */
  property name="managementTimeout" default="75000" type="numeric";

  // Reliability options
  /**
  * The reconnect delay defines the time intervals between a socket getting closed on the SDK side and trying to reopen
  * (reconnect) to it. The default is to retry relatively quickly (32ms) and then gradually approach 4 second intervals,
  * so that in case a server is longer down than usual the clients do not flood the server with socket requests. Feel
  * free to tune this interval based on your application requirements. Applying a very large ceiling may lead to longer
  * down times than needed, while very short delays may flood the target node and spam the network unnecessarily.
  * com.couchbase.client.core.time.Delay
  */
  property name="reconnectDelay" default="";
  /**
  * When a request needs to be retried for some reason (for example if the retry strategy is best effort and the target
  * node is not reachable), this delay configures the boundaries. An internal counter tracks the number of retries for a
  * given request and it gradually increases by default from a very quick 100 microseconds up to a 100 millisecond delay.
  * The operation will be retried until it succeeds or the maximum request lifetime is reached. If you find yourself
  * wanting to tweak this value to a very low setting, you might want to consider a different retry strategy like "fail
  * fast" to get tighter control on the retry handling yourself. com.couchbase.client.core.time.Delay
  */
  property name="retryDelay" default="";
  /**
  * The retry strategy decides if an operation should be retried or canceled. While implementing a custom strategy is
  * fairly advanced, the SDK ships with two out of the box: BestEffortRetryStrategy and FailFastRetryStrategy. The first
  * one will retry the operation until it either succeeds or the maximum request lifetime is reached. The fail fast
  * strategy will cancel it right away and therefore the client needs to be prepared to retry on its own, but gets much
  * tighter control on when and how to retry. See the advanced section in the documentation on more specific information
  * on retry strategies and failure management. com.couchbase.client.core.retry.RetryStrategy
  */
  property name="retryStrategy" default="";
  /**
  * The maximum request lifetime is used by the best effort retry strategy to decide if its time to cancel the request
  * instead of retrying it again. This is needed in order to prevent requests from circling around forever and occupying
  * precious slots in the request ring buffer. Make sure to set this higher than the largest timeout in your application,
  * otherwise you risk requests being canceled prematurely. This is why the default value is set to 75 seconds, which is
  * the highest default timeout on the environment.
  */
  property name="maxRequestLifetime" default="75000" type="numeric";
  /**
  * To avoid nasty firewalls and other network equipment cutting of stale TCP connections, at the configured interval
  * the client will send a heartbeat keepalive message to the remote node and port. This only happens if for the given
  * amount of time no traffic has happened, so if a socket is busy sending data back and forth it will have no effect.
  * If you set this value to 0, no keepalive will be sent over the sockets.
  */
  property name="keepAliveInterval" default="30000" type="numeric";

  // Performance options
  /**
  * The way PersistTo and ReplicateTo work is that once the regular mutation operation succeeds, the key state on the
  * target nodes is polled until the desired state is reached. Since replication and persistence latency differs
  * greatly on servers (fast or slow networks and disks), this value can be tuned for maximum efficiency. The tradeoffs
  * to consider here is how quickly the desired state is detected as well as how much the SDK will spam the network. The
  * default is an exponential delay, starting with very short intervals but very quickly approaching the 100
  * milliseconds if replication or persistence takes longer than expected. You should monitor the average persistence
  * and replication latency and adjust the delay accordingly. com.couchbase.client.core.time.Delay
  */
  property name="observeIntervalDelay" default="";
  /**
  * The number of actual endpoints (sockets) to open per Node in the cluster against the Key/value service. By default,
  * for every node in the cluster one socket is opened where all traffic is pushed through. That way the SDK implicitly
  * benefits from network batching characteristics when the workload increases. If you suspect based on profiling and
  * benchmarking that the socket is saturated you can think about slightly increasing it to have more "parallel
  * pipelines". This might be especially helpful if you need to push large documents through it. The recommendation is
  * keeping it at 1 unless there is other evidence.
  */
  property name="kvEndpoints" default="1" type="numeric";
  /**
  * The number of actual endpoints (sockets) to open per node in the cluster against the view service. By default only one
  * socket is opened to avoid unnecessary wasting resources. If you plan to run a view heavy workload, especially paired
  * with larger responses, increasing this value significantly (most likely between 5 and 10) can provide greater
  * throughput. Keep in mind that these sockets will then be always open, even when no load is passed through. We
  * recommend that you tune this value based on evidence obtained during benchmarking with a real workload. If no view
  * load is expected, setting this value explicitly to 0 can avoid one socket to 8092 per node.
  */
  property name="viewEndpoints" default="1" type="numeric";
  /**
  * The number of actual endpoints (sockets) to open per Node in the cluster against the Query (N1QL) service. By
  * default only one socket is opened to avoid unnecessary wasting resources. If you plan to run a query heavy
  * workload, especially paired with larger responses, increasing this value significantly (most likely between 5 and
  * 10) can provide greater throughput. Keep in mind that these sockets will then be always open, even when no load
  * is passed through. We are recommending to tune this value based on evidence during benchmarking with a real
  * workload. If no query load is expected, setting this value explicitly to 0 can avoid one socket to 8093 per node.
  */
  property name="queryEndpoints" default="1" type="numeric";
  /**
  * The number of threads in the I/O thread pool. This defaults to the number of available processors that the runtime
  * returns (which, as a well known fact, sometimes does not represent the actual number of processors). Every thread
  * represents an internal event loop where all needed socket are multiplexed on. The default value should be fine most
  * of the time, it may only need to be tuned if you run a very large number of nodes in the cluster or the runtime
  * value is incorrect. As a rule of thumb, it should roughly correlate with the number of cores available to the JVM.
  * 0 means the value will be computed at runtime.
  */
  property name="ioPoolSize" default="0" type="numeric";
  /**
  * The number of threads in the computation thread pool. This defaults to the number of available processors that the
  * runtime returns (which, as a well known fact, sometimes does not represent the actual number of processors). Every
  * thread represents an internal event loop where all needed computation tasks are run. The default value should be fine
  * most of the time, it might only need to be tuned if you run more than usual CPU-intensive tasks and profiling the
  * application indicates fully saturated threads in the pool. As a rule of thumb, it should roughly correlate with the
  * number of cores available to the JVM. 0 means the value will be computed at runtime.
  */
  property name="computationPoolSize" default="0" type="numeric";
  /**
  * For those who want the last drop of performance, on Linux Netty provides a way to use edge triggered epoll instead
  * of going through JVM NIO. This provides better throughput, lower latency and less garbage. Note that this mode has
  * not been tested by Couchbase and therefore is not supported officially. If you like to take a walk on the wild side,
  * you can find out more here: https://github.com/netty/netty/wiki/Native-transports
  * com.couchbase.client.deps.io.netty.channel.EventLoopGroup
  */
  property name="ioPool" default="";
  /**
  * By default, TCP Nodelay is turned on (which in effect turns off "nagleing"), and if possible negotiated with the server
  * as well. If this is set to false, "nagleing" is turned on. Make sure to only turn off TCP nodelay if you know what you
  * are doing, because it can lead to decreased performance.
  */
  property name="tcpNodelayEnabled" default="true" type="boolean";

  // Advanced options
  /**
  * The size of the request ring buffer where all request initially are stored and then picked up to be pushed onto the
  * I/O threads. Tuning this to a lower value will more quickly lead to BackpressureExceptions during overload or failure
  * scenarios. Setting it to a higher value means backpressure will take longer to occur, but more requests will
  * potentially be queued up and more heap space is used.
  */
  property name="requestBufferSize" default="16384" type="numeric";
  /**
  * The size of the response ring buffer where all responses are passed through from the I/O threads before the target
  * observable is completed. Since the I/O threads are pushing data in this ring buffer, setting it to a lower value is
  * likely to have a negative effect on I/O performance. In general it should be kept in line with the request ring
  * buffer size.
  */
  property name="responseBufferSize" default="16384" type="numeric";
  /**
  * The scheduler used for all CPU-intensive, non-blocking computations in the core, client and in user space. This is a
  * slightly modified version of the ComputationScheduler that ships with RxJava, mainly for the reason to manually name
  * threads as needed. Changing the scheduler should be used with extra care, especially since lots of internal components
  * also depend on it. rx.Scheduler
  */
  property name="scheduler" default="";
  /**
  * The user agent string that is used to identify the SDK against the Couchbase Server cluster on different occasions, for
  * example when doing a view or query request. There is no need to tune that because it is dynamically generated based on
  * properties set during build time (based on the package name and version, OS and runtime). Leave empty to have determined
  * at runtime.
  */
  property name="userAgent" default="";
  /**
  * The package name and identifier is used as part of the user agent string and in the environment info output to see
  * which version of the SDK the application is running. There is no need to change it because it is dynamically
  * generated based on properties set during build time.  Leave empty to determine at build time.
  */
  property name="packageNameAndVersion" default="";
  /**
  * The event bus implementation used to transport system, performance and debug events from producers to subscribers.
  * The default implementation is based on an internal RxJava Subject which does not cache the values and only pushes
  * subsequent events to the subscribers. If you provide a custom implementation, double check that it fits with the
  * contract of the event bus as documented. com.couchbase.client.core.event.EventBus
  */
  property name="eventBus" default="";
  /**
  * DCP is not ready for prime time in clients, but this configuration switch is available because all parameters from
  * the core-io module are inherited. If you have active need for DCP, get in touch with the Couchbase team.
  */
  property name="dcpEnabled" default="false" type="boolean";
  /**
  * Size of the buffer to control speed of DCP producer.
  */
  property name="dcpConnectionBufferSize" default="0" type="numeric";
  /**
  * When a DCP connection read bytes reaches this percentage of the CoreEnvironment.dcpConnectionBufferSize(), a DCP Buffer Acknowledge message is sent to the server
  */
  property name="dcpConnectionBufferAckThreshold" default="0" type="numeric";
  /**
  * The default DCP connection name
  */
  property name="dcpConnectionName" default="" type="string";
  /**
  * If the SDK is suspect to buffer leaks (it pools buffers in its IO layer for performance) you can set this field to
  * false. This will make sure buffers are not pooled, but remember the tradeoff here is higher GC pressure on the system.
  * Only turn off to prevent a memory leak from happening (in production). If you suspect a memory leak, please open a
  * bug ticket.
  */
  property name="bufferPoolingEnabled" default="true" type="boolean";
  /**
  * The configuration of the runtime metrics collector can be modified (or completely disabled). By default, it will emit
  * an event every hour. com.couchbase.client.core.metrics.MetricsCollectorConfig
  */
  property name="runtimeMetricsCollectorConfig" default="";
  /**
  * The configuration of the network latency metrics collector can be modified (or completely disabled). By deault, it
  * will emit an event every hour, but collect the stats all the time.
  * com.couchbase.client.core.metrics.LatencyMetricsCollectorConfig
  */
  property name="networkLatencyMetricsCollectorConfig" default="";
  /**
  * The default metric consumer which will log all metric events. You can configure if it should be enabled, as well as
  * the log level and the target output format. com.couchbase.client.core.logging.CouchbaseLogLevel
  */
  property name="defaultMetricsLoggingConsumer" default="";
  /**
  * There is no documentation on this property but there is a method for it, I would recommend not
  * changing it from the default value.
  */
  property name="autoReleaseAfter" default="2000" type="numeric";
  /**
  * Sets a custom socket connect timeout
  */
  property name="socketConnectTimeout" default="0" type="numeric";
  /**
  * Set to true if the Observable callbacks should be completed on the IO event loops.
  */
  property name="callbacksOnIoPool" default="false" type="boolean";

  // Default params, just in case using cf9
  variables['useClassLoader'] = true;
  variables['dataMarshaller'] = "";
  variables['servers'] = "127.0.0.1";
  variables['bucketName'] = "default";
  variables['password'] = "";
  variables['sslEnabled'] = false;
  variables['sslKeystoreFile'] = "";
  variables['sslKeystorePassword'] = "";
  variables['queryEnabled'] = true; // DEPRECATED
  variables['queryPort'] = 8093; // DEPRECATED
  variables['bootstrapHttpEnabled'] = true;
  variables['bootstrapHttpDirectPort'] = 8091;
  variables['bootstrapHttpSslPort'] = 18091;
  variables['bootstrapCarrierEnabled'] = true;
  variables['bootstrapCarrierDirectPort'] = 11210;
  variables['bootstrapCarrierSslPort'] = 11207;
  variables['dnsSrvEnabled'] = false;
  variables['mutationTokensEnabled'] = false;
  variables['kvTimeout'] = 2500;
  variables['viewTimeout'] = 75000;
  variables['queryTimeout'] = 75000;
  variables['connectTimeout'] = 5000;
  variables['disconnectTimeout'] = 25000;
  variables['managementTimeout'] = 75000;
  variables['reconnectDelay'] = "";
  variables['retryDelay'] = "";
  variables['retryStrategy'] = "";
  variables['maxRequestLifetime'] = 75000;
  variables['keepAliveInterval'] = 30000;
  variables['observeIntervalDelay'] = "";
  variables['kvEndpoints'] = 1;
  variables['viewEndpoints'] = 1;
  variables['queryEndpoints'] = 1;
  variables['ioPoolSize'] = 0;
  variables['computationPoolSize'] = 0;
  variables['ioPool'] = "";
  variables['tcpNodelayEnabled'] = true;
  variables['requestBufferSize'] = 16384;
  variables['responseBufferSize'] = 16384;
  variables['scheduler'] = "";
  variables['userAgent'] = "";
  variables['packageNameAndVersion'] = "";
  variables['eventBus'] = "";
  variables['dcpEnabled'] = false;
  variables['dcpConnectionBufferAckThreshold'] = 0;
  variables['dcpConnectionBufferSize'] = 0;
  variables['dcpConnectionName'] = "";
  variables['bufferPoolingEnabled'] = true;
  variables['runtimeMetricsCollectorConfig'] = "";
  variables['networkLatencyMetricsCollectorConfig'] = "";
  variables['defaultMetricsLoggingConsumer'] = "";
  variables['autoReleaseAfter'] = 2000;
  variables['socketConnectTimeout'] = 0;
  variables['callbacksOnIoPool'] = false;
  /**
  * Constructor
  * You can pass any name-value pair as arguments to the constructor that matches the properties in this configuration object to be set.
  */
  public function init(){

    // Check incoming arguments
    for(var thisArg in arguments){
      if(structKeyExists(arguments, thisArg)){
        variables[thisArg] = arguments[thisArg];
      }
    }

    return this;
  }

  /**
  * Configure method
  * Don't put anything here since people extending this component may not call super.configure().
  * It exists so people can create this component directly as their config and call setters on it.
  */
  function configure(){}

  /**
  * Get a memento representation of the config options
  */
  function getMemento(){
    var results = {};

    for(var thisProp in variables){
      if(!isCustomFunction(variables[thisProp]) && thisProp neq "this" ){
        results[thisProp] = variables[thisProp];
      }
    }

    return results;
  }
}