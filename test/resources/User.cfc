component accessors="true"{

  property name="name";
  property name="age";

  function init(){
    name = "";
    age = 0;
  }

  function $serialize(){

    return serializeJSON({
      name = getName(),
      age  = getAge(),
      type = "UserCF",
      when = now()
    });

  }

  function $deserialize( ID, data ){

    setName( data.name );
    setAge( data.age );

  }

}