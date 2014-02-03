<cfoutput>
	<h1>Edit Brewery Details</h1>
		
	<a href="index.cfm">Back to Brewery List</a><br><br>
	
	<cfparam name="url.breweryID" default="not_supplied"> 
	
	<cfset cbClient = application.couchbase>
	<cfset brewery = cbClient.get("#url.breweryID#")>
	
	<cfif isnull(brewery)>
		
		Invalid BreweryID "#HTMLEditFormat(url.breweryID)#"
	
	<cfelse>
			
		<a href="brewery.cfm?breweryID=#HTMLEditFormat(url.breweryID)#">Back to Brewery Details</a><br><br>
		
		<form action="breweryUpdate.cfm" method="post">
			<input type="hidden" value="#HTMLEditFormat(url.breweryID)#" name="breweryID" id="breweryID">
		
			<table>
				<tr>
					<td>Name:</td>
					<td><input type="text" value="#HTMLEditFormat(brewery.name)#" name="name" id="name" size=50></td>
				</tr>
				<tr>
					<td>Website:</td>
					<td><input type="text" value="#HTMLEditFormat(brewery.website)#" name="website" id="website" size=50></td>
				</tr>
				<tr>
					<td>Phone:</td>
					<td><input type="text" value="#HTMLEditFormat(brewery.phone)#" name="phone" id="phone" size=50></td>
				</tr>
				<tr>
					<td>Description:</td>
					<td>
						<textarea name="description" id="description" rows="7" cols="75">#HTMLEditFormat(brewery.description)#</textarea>
					</td>
				</tr>
				<tr>
					<td>Address 1:</td>
					<td><input type="text" value="<cfif arrayLen(brewery.address)>#HTMLEditFormat(brewery.address[1])#</cfif>" name="address1" id="address1" size=50></td>
				</tr>
				<tr>
					<td>Address 2:</td>
					<td><input type="text" value="<cfif arrayLen(brewery.address) GT 1>#HTMLEditFormat(brewery.address[2])#</cfif>" name="address2" id="address2" size=50></td>
				</tr>
				<tr>
					<td>City:</td>
					<td><input type="text" value="#HTMLEditFormat(brewery.city)#" name="city" id="city" size=50></td>
				</tr>
				<tr>
					<td>State:</td>
					<td><input type="text" value="#HTMLEditFormat(brewery.state)#" name="state" id="state" size=50></td>
				</tr>
				<tr>
					<td>Zip:</td>
					<td><input type="text" value="#HTMLEditFormat(brewery.code)#" name="code" id="code" size=50></td>
				</tr>
				<tr>
					<td>Country:</td>
					<td><input type="text" value="#HTMLEditFormat(brewery.country)#" name="country" id="country" size=50></td>
				</tr>
				<tr>
					<td>Last Updated:</td>
					<td>#dateFormat(brewery.updated,"full")#</td>
				</tr>
			</table>
			
			<button type="submit">Save Brewery</button>
		
		</form>
		
	</cfif>
	
</cfoutput>