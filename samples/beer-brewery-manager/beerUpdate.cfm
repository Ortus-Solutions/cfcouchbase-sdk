<cfparam name="form.beerID" default="not_supplied"> 

<cfset cbClient = application.couchbase>
<cfset beer = cbClient.get("#form.beerID#")>

<cfif isnull(beer)>
	
	Invalid beerID "#HTMLEditFormat(form.beerID)#"

<cfelse>

	<cfloop list="name,category,style,description,ibu,srm,upc" index="field">
		<cfset beer[field] = form[field]>
	</cfloop>
		
	<cfset beer.updated = "#dateFormat(now(),"yyyy-mm-dd")# #timeFormat(now(),"HH:mm:ss")#">
	
	<cfset cbClient.set(form.beerID, beer)>
	
	<cflocation url="beer.cfm?beerID=#URLEncodedFormat(form.beerID)#" addToken="no">
	
</cfif>		


