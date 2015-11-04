component extends="cfcouchbase.config.CouchbaseConfig"{

  function configure(){

    bucketName   = "default";
    servers   = "http://127.0.0.1:8091";
    viewTimeout = 10000;

    return this;
  }

}