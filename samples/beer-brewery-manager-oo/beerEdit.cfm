<cfoutput>
	<h1>Edit Beer Details</h1>
			
	<cfparam name="url.beerID" default="not_supplied"> 
	
	<cfset cbClient = application.couchbase>
	<cfset beer = cbClient.get("#url.beerID#")>
	
	<cfif isnull(beer)>
		
		Invalid beerID "#HTMLEditFormat(url.beerID)#"
	
	<cfelse>
			
		<a href="brewery.cfm?breweryID=#HTMLEditFormat(beer.brewery_id)#">Back to brewey Details</a><br><br>
		<a href="beer.cfm?beerID=#HTMLEditFormat(url.beerID)#">Back to beer Details</a><br><br>
		
		<form action="beerUpdate.cfm" method="post">
			<input type="hidden" value="#HTMLEditFormat(url.beerID)#" name="beerID" id="beerID">
		
			<table>
				<tr>
					<td>Name:</td>
					<td><input type="text" value="#HTMLEditFormat(beer.name)#" name="name" id="name" size=50></td>
				</tr>
				<tr>
					<td>Category:</td>
					<td>
						<input type="text" value="<cfif structkeyExists(beer,"category")>#HTMLEditFormat(beer.category)#</cfif>" name="category" id="category" size=50>
					</td>
				</tr>
				<tr>
					<td>Style:</td>
					<td>
						<input type="text" value="<cfif structkeyExists(beer,"category")>#HTMLEditFormat(beer.style)#</cfif>" name="style" id="style" size=50>
					</td>
				</tr>
				<tr>
					<td>Description:</td>
					<td>
						<textarea name="description" id="description" rows="7" cols="75">#HTMLEditFormat(beer.description)#</textarea>
					</td>
				</tr>
				<tr>
					<td>IBU:</td>
					<td><input type="text" value="#HTMLEditFormat(beer.ibu)#" name="ibu" id="ibu" size=50></td>
				</tr>
				<tr>
					<td>SRM:</td>
					<td><input type="text" value="#HTMLEditFormat(beer.srm)#" name="srm" id="srm" size=50></td>
				</tr>
				<tr>
					<td>UPC</td>
					<td><input type="text" value="#HTMLEditFormat(beer.upc)#" name="upc" id="upc" size=50></td>
				</tr>
				<tr>
					<td>Last Updated:</td>
					<td>#dateFormat(beer.updated,"full")#</td>
				</tr>
			</table>
			
			<button type="submit">Save beer</button>
		
		</form>
		
	</cfif>
	
</cfoutput>