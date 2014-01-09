component accessors="true" extends="Base" autoInflate=true{

	property name="firstName";
	property name="lastName";
	property name="age";

	function init(){
		super.init();
		firstname = "";
		lastName = "";
		age = "";
	}

}