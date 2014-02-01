// CustomUser is an object that implements its own serialization scheme
// using pipe-delimited lists to store the data instead of JSON.  It has both
// a $serialize() and $deserialize() method to facilitate that.
component accessors="true"{

	property name="firstName";
	property name="lastName";
	property name="age";

	function init(){
		firstName = "";
		lastName = "";
		age = 0;
	}

	function $serialize(){

		// Serialize as pipe-delimited list
		return '#getFirstName()#|#getLastName()#|#getAge()#';

	}
	
	function $deserialize( data ){

		// Deserialize the pipe-delimited list
		setFirstName( listGetAt( data, 1, '|' ) );
		setLastName( listGetAt( data, 2, '|' ) );
		setAge( listGetAt( data, 3, '|' ) );
		
	}

}