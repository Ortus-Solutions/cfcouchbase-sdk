<cfoutput>
	<h1>Edit Brewery Details</h1>
		
	<a href="index.cfm">Back to Brewery List</a><br><br>
	
	<cfparam name="url.breweryID" default="not_supplied"> 
	
	<cfset brewery = application.BreweryService.getBrewery( url.breweryID )>
	
	<cfif isnull(brewery)>
		
		Invalid BreweryID "#HTMLEditFormat(url.breweryID)#"
	
	<cfelse>
			
		<a href="brewery.cfm?breweryID=#HTMLEditFormat( brewery.getBreweryID() )#">Back to Brewery Details</a><br><br>
		
		<form action="breweryUpdate.cfm" method="post">
			<input type="hidden" value="#HTMLEditFormat( brewery.getBreweryID() )#" name="breweryID" id="breweryID">
		
			<table>
				<tr>
					<td>Name:</td>
					<td><input type="text" value="#HTMLEditFormat( brewery.getName() )#" name="name" id="name" size=50></td>
				</tr>
				<tr>
					<td>Website:</td>
					<td><input type="text" value="#HTMLEditFormat( brewery.getWebsite() )#" name="website" id="website" size=50></td>
				</tr>
				<tr>
					<td>Phone:</td>
					<td><input type="text" value="#HTMLEditFormat( brewery.getPhone() )#" name="phone" id="phone" size=50></td>
				</tr>
				<tr>
					<td>Description:</td>
					<td>
						<textarea name="description" id="description" rows="7" cols="75">#HTMLEditFormat( brewery.getDescription() )#</textarea>
					</td>
				</tr>
				<tr>
					<td>Address 1:</td>
					<td><input type="text" value="#HTMLEditFormat( brewery.getAddress1() )#" name="address1" id="address1" size=50></td>
				</tr>
				<tr>
					<td>Address 2:</td>
					<td><input type="text" value="#HTMLEditFormat( brewery.getAddress2() )#" name="address2" id="address2" size=50></td>
				</tr>
				<tr>
					<td>City:</td>
					<td><input type="text" value="#HTMLEditFormat( brewery.getCity() )#" name="city" id="city" size=50></td>
				</tr>
				<tr>
					<td>State:</td>
					<td><input type="text" value="#HTMLEditFormat( brewery.getState() )#" name="state" id="state" size=50></td>
				</tr>
				<tr>
					<td>Zip:</td>
					<td><input type="text" value="#HTMLEditFormat( brewery.getCode() )#" name="code" id="code" size=50></td>
				</tr>
				<tr>
					<td>Country:</td>
					<td><input type="text" value="#HTMLEditFormat( brewery.getCountry() )#" name="country" id="country" size=50></td>
				</tr>
				<tr>
					<td>Last Updated:</td>
					<td>#dateFormat( brewery.getUpdated(), "full" )#</td>
				</tr>
			</table>
			
			<button type="submit">Save Brewery</button>
		
		</form>
		
	</cfif>
	
</cfoutput>