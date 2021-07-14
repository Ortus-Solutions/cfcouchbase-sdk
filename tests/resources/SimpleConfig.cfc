component{

  function configure(){

    bucketName     = "default";
    servers     = "http://127.0.0.1:8091";
    defaultTimeout   = 30;
    username = "cfcouchbase";
    password = "";

    return this;
  }

}
