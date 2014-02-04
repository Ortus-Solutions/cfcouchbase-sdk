component accessors=true autoInflate {
	property name='breweryID' fieldType='id';
	property name='country';
	property name='geo';
	property name='code';
	property name='updated';
	property name='state';
	property name='name';
	property name='type';
	property name='website';
	property name='city';
	property name='phone';
	property name='description';
	property name='address';
	
	property name='beerCount';
	
	function getBeerCount() {
		var result = application.couchbase.query("manager", "listBeersByBrewery", { group = true, key = getBreweryID() });
		
		if( arraylen( result ) ) {
			return result[1].value;
		}
		
		return 0;
	}

}