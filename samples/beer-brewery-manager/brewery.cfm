<cfoutput>
	<h1>Brewery Details</h1>
	
	<a href="index.cfm">Back to Brewery List</a><br><br>
	
	<cfparam name="url.breweryID" default="not_supplied"> 
	
	<cfset cbClient = application.couchbase>
	<cfset brewery = cbClient.get("#url.breweryID#")>
	
	<cfif isnull(brewery)>
		
		Invalid BreweryID "#HTMLEditFormat(url.breweryID)#"
	
	<cfelse>
		
		<a href="breweryEdit.cfm?breweryID=#HTMLEditFormat(url.breweryID)#">Edit this Brewery's Details</a><br><br>

		<table>
			<tr>
				<td>Name:</td>
				<td>#HTMLEditFormat(brewery.name)#</td>
			</tr>
			<tr>
				<td>website:</td>
				<td>#HTMLEditFormat(brewery.website)#</td>
			</tr>
			<tr>
				<td>Phone:</td>
				<td>#HTMLEditFormat(brewery.phone)#</td>
			</tr>
			<tr>
				<td>Description:</td>
				<td>#HTMLEditFormat(brewery.description)#</td>
			</tr>
			<tr>
				<td>Address 1:</td>
				<td><cfif arrayLen(brewery.address)>#HTMLEditFormat(brewery.address[1])#</cfif></td>
			</tr>
			<tr>
				<td>Address 2:</td>
				<td><cfif arrayLen(brewery.address) GT 1>#HTMLEditFormat(brewery.address[2])#</cfif></td>
			</tr>
			<tr>
				<td>City:</td>
				<td>#HTMLEditFormat(brewery.city)#</td>
			</tr>
			<tr>
				<td>State:</td>
				<td>#HTMLEditFormat(brewery.state)#</td>
			</tr>
			<tr>
				<td>Zip:</td>
				<td>#HTMLEditFormat(brewery.code)#</td>
			</tr>
			<tr>
				<td>Country:</td>
				<td>#HTMLEditFormat(brewery.country)#</td>
			</tr>
			<tr>
				<td>Last Updated:</td>
				<td>#dateFormat(brewery.updated,"full")#</td>
			</tr>
		</table>
			
	</cfif>
	
</cfoutput>