<cfparam name="form.breweryID" default="not_supplied"> 

<cfset brewery = application.BreweryService.getBrewery( form.breweryID )>

<cfif isnull(brewery)>
	
	Invalid BreweryID "#HTMLEditFormat(form.breweryID)#"

<cfelse>

	<!--- Save some typing --->
	<cfloop list="name,website,phone,description,city,state,code,country,address1,address2" index="field">
		<cfset evaluate( "brewery.set#field#( form[field] )" )>
	</cfloop>
		
	<cfset brewery.setUpdated( "#dateFormat(now(),"yyyy-mm-dd")# #timeFormat(now(),"HH:mm:ss")#" )>
	
	<cfset brewery.save()>
	
	<cflocation url="brewery.cfm?breweryID=#URLEncodedFormat( brewery.getBreweryID() )#" addToken="no">
	
</cfif>		


