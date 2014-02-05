<cfparam name="form.beerID" default="not_supplied"> 

<cfset beer = application.BreweryService.getBeer( form.beerID )>

<cfif isnull(beer)>
	
	Invalid beerID "#HTMLEditFormat(form.beerID)#"

<cfelse>

	<cfloop list="name,category,style,description,ibu,srm,upc" index="field">
		<cfset evaluate( "beer.set#field#( form[field] )" )>
	</cfloop>
		
	<cfset beer.setUpdated( "#dateFormat(now(),"yyyy-mm-dd")# #timeFormat(now(),"HH:mm:ss")#" )>
	
	<cfset beer.save()>
	
	<cflocation url="beer.cfm?beerID=#URLEncodedFormat( beer.getBeerID() )#" addToken="no">
	
</cfif>		


