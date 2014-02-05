component {

	// Breweries

	function getBreweryCount() {
		var result = application.couchbase.query('manager', 'listBreweries');
		return result[1].value;
	}
	
	function getBreweries( offset=0, limit=10 ) {
		return application.couchbase.query(
			designDocumentName = 'manager',
			viewName = 'listBreweries',
			inflateTo = 'root.model.brewery',
			options = {
				includeDocs = true,
				limit=arguments.limit,
				offSet = arguments.offset,
				reduce = false
			});
	}
	
	function getBrewery( breweryID ) {
		return application.couchbase.get(
			ID = arguments.breweryID,
			inflateTo = 'root.model.brewery'
		);
	}
		
	// Beers
	
	function getBeerCount() {
		var result = application.couchbase.query('manager', 'listBeersByBrewery');
		return result[1].value;
	}	
	
	function getBeers( breweryID ) {
		return application.couchbase.query(
			designDocumentName = 'manager',
			viewName = 'listBeersByBrewery', 
			inflateTo = 'root.model.beer',
			options = {
				reduce = false,
				key = arguments.breweryID,
				includeDocs = true
			}
		);
	}	
	
	function getBeer( beerID ) {
		return application.couchbase.get(
			ID = arguments.beerID,
			inflateTo = 'root.model.beer'
		);
	}


}