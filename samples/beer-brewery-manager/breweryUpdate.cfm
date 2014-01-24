<cfparam name="form.breweryID" default="not_supplied"> 

<cfset cbClient = application.couchbase>
<cfset brewery = cbClient.get("#form.breweryID#")>

<cfif isnull(brewery)>
	
	Invalid BreweryID "#HTMLEditFormat(form.breweryID)#"

<cfelse>

	<cfloop list="name,website,phone,description,city,state,code,country" index="field">
		<cfset brewery[field] = form[field]>
	</cfloop>
		
	<cfset brewery.address[1] = form.address1>
	
	<cfif len(form.address2)>
		<cfset brewery.address[2] = form.address2>
	<cfelseif arrayLen(brewery.address) GT 2>
		<cfset arrayDeleteAt(brewery.address,2)>
	</cfif>
	
	<cfset brewery.updated = "#dateFormat(now(),"yyyy-mm-dd")# #timeFormat(now(),"HH:mm:ss")#">
	
	<cfset cbClient.set(form.breweryID, brewery)>
	
	<cflocation url="brewery.cfm?breweryID=#URLEncodedFormat(form.breweryID)#" addToken="no">
	
</cfif>		


