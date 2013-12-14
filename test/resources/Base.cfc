component accessors="true"{

	property name="id";
	property name="createdDate";
	property name="updatedDate";

	function init(){
		id = createUUID();
		createdDate = now();
		updatedDate = now();
	}

}