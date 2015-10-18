component accessors="true" extends="Base"{

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