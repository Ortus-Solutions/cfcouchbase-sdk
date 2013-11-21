component extends="cfcouchbase.config.CouchbaseConfig"{

	function init(){

		super.init(
			bucketname = "default",
			servers = "http://127.0.0.1:8091",
			viewTimeout = 10000
		);

		return this;
	}

}