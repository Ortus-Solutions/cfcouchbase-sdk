component {

	function getBreweryCount() {
		var result = application.couchbase.query("manager", "listBreweries");
		return result[1].value;
	}
	
	function getBeerCount() {
		var result = application.couchbase.query("manager", "listBeersByBrewery");
		return result[1].value;
	}
	
	function getBreweries( offset=0, limit=10) {
		return application.couchbase.query(
			designDocumentName = "manager",
			viewName = "listBreweries",
			inflateTo = 'root.model.brewery',
			options = {
				includeDocs = true,
				limit=url.recordsPerPage,
				offSet = url.startRecord-1,
				reduce = false
			});
	}

}