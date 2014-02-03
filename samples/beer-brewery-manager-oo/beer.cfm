<cfoutput>
	<h1>Beer Details</h1>
	
	<a href="index.cfm">Back to beer List</a><br><br>
	
	<cfparam name="url.beerID" default="not_supplied"> 
	
	<cfset cbClient = application.couchbase>
	<cfset beer = cbClient.get("#url.beerID#")>
		
	<cfif isnull(beer)>
		
		Invalid beerID "#HTMLEditFormat(url.beerID)#"
	
	<cfelse>
		<a href="brewery.cfm?breweryID=#HTMLEditFormat(beer.brewery_id)#">Back to brewey Details</a><br><br>
		<a href="beerEdit.cfm?beerID=#HTMLEditFormat(url.beerID)#">Edit this beer's Details</a><br><br>

		<table>
			<tr>
				<td>Name:</td>
				<td>#HTMLEditFormat(beer.name)#</td>
			</tr>
			<tr>
				<td>Category:</td>
				<td>
					<cfif structkeyExists(beer,"category")>
						#HTMLEditFormat(beer.category)#
					</cfif>
				</td>
			</tr>
			<tr>
				<td>Style:</td>
				<cfif structkeyExists(beer,"category")>
					<td>#HTMLEditFormat(beer.style)#</td>
				</cfif>
			</tr>
			<tr>
				<td>Description:</td>
				<td>#HTMLEditFormat(beer.description)#</td>
			</tr>
			<tr>
				<td title="International Bitterness Units">IBU:</td>
				<td>#HTMLEditFormat(beer.ibu)#</td>
			</tr>
			<tr>
				<td title="Standard Reference Method">SRM:</td>
				<td>#HTMLEditFormat(beer.srm)#</td>
			</tr>
			<tr>
				<td>UPC:</td>
				<td>#HTMLEditFormat(beer.upc)#</td>
			</tr>
			<tr>
				<td>Last Updated:</td>
				<td>#dateFormat(beer.updated,"full")#</td>
			</tr>
		</table>
							
	</cfif>
	
</cfoutput>
