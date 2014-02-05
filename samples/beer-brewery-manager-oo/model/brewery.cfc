component accessors=true {
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
		
	// Convenience methods for breaking up address
	function getAddress1() {
		var address = getAddress();
		if( arrayLen( address ) ) {
			return address[1];
		} else {
			return '';
		}
	}
	
	function getAddress2() {
		var address = getAddress();
		if( arrayLen( address ) > 1 ) {
			return address[2];
		} else {
			return '';
		}
	}
	
	function setAddress1( required address1 ) {
		var address = getAddress();
		address[1] = arguments.address1;
		setAddress(address);
	}
	
	function setAddress2( required address2 ) {
		var address = getAddress();
		address[2] = arguments.address2;
		setAddress(address);
	}

	// Composed objects	
	function getBeerCount() {
		var result = application.couchbase.query("manager", "listBeersByBrewery", { group = true, key = getBreweryID() });
		
		if( arraylen( result ) ) {
			return result[1].value;
		}
		
		return 0;
	}
		
	function getBeers() {
		return application.BreweryService.getBeers( getBreweryID() );
	}
	
	// Save yourself!
		
	function save() {
		return application.couchbase.set( getBreweryID(), this );
	}	

}