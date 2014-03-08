component singleton {
	property name='cbClient' inject='CouchbaseClient';
	property name='wirebox' inject='wirebox';

	// Breweries

	function getBreweryCount() {
		var result = cbClient.query( 'manager', 'listBreweries' );
		return result[1].value;
	}
	
	function getBreweries( offset=0, limit=10 ) {
		return cbClient.query(
			designDocumentName = 'manager',
			viewName = 'listBreweries',
			inflateTo = function( doc ) {
				return variables.wirebox.getInstance( 'brewery' );	
			},
			options = {
				includeDocs = true,
				limit = arguments.limit,
				offSet = arguments.offset,
				reduce = false
			});
	}
	
	function getBrewery( breweryID ) {
		return cbClient.get(
			ID = arguments.breweryID,
			inflateTo = function( doc ) {
				return wirebox.getInstance( 'brewery' );	
			}
		);
	}
		
	// Beers
	
	function getBeerCount() {
		var result = cbClient.query('manager', 'listBeersByBrewery');
		return result[1].value;
	}	
	
	function getBeers( breweryID ) {
		return cbClient.query(
			designDocumentName = 'manager',
			viewName = 'listBeersByBrewery',
			inflateTo = function( doc ) {
				return wirebox.getInstance( 'beer' );	
			},
			options = {
				reduce = false,
				key = arguments.breweryID,
				includeDocs = true
			}
		);
	}	
	
	function getBeer( beerID ) {
		return cbClient.get(
			ID = arguments.beerID,
			inflateTo = function( doc ) {
				return wirebox.getInstance( 'beer' );	
			}
		);
	}


}