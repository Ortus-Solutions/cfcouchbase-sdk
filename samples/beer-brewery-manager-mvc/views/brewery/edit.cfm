<cfoutput>
	<h1>Edit Brewery Details</h1>
		
	<a href="#event.buildLink( "brewery.list" )#">Back to Brewery List</a><br><br>
	
	<cfif isnull(prc.brewery)>
		
		Invalid BreweryID "#HTMLEditFormat(rc.breweryID)#"
	
	<cfelse>
			
		<a href="#event.buildLink( linkTo="brewery.view", queryString="breweryID=#HTMLEditFormat( prc.brewery.getBreweryID() )#" )#">Back to Brewery Details</a><br><br>
		
		<form action="#event.buildLink( "brewery.update" )#" method="post">
			<input type="hidden" value="#HTMLEditFormat( prc.brewery.getBreweryID() )#" name="breweryID" id="breweryID">
		
			<table>
				<tr>
					<td>Name:</td>
					<td><input type="text" value="#HTMLEditFormat( prc.brewery.getName() )#" name="name" id="name" size=50></td>
				</tr>
				<tr>
					<td>Website:</td>
					<td><input type="text" value="#HTMLEditFormat( prc.brewery.getWebsite() )#" name="website" id="website" size=50></td>
				</tr>
				<tr>
					<td>Phone:</td>
					<td><input type="text" value="#HTMLEditFormat( prc.brewery.getPhone() )#" name="phone" id="phone" size=50></td>
				</tr>
				<tr>
					<td>Description:</td>
					<td>
						<textarea name="description" id="description" rows="7" cols="75">#HTMLEditFormat( prc.brewery.getDescription() )#</textarea>
					</td>
				</tr>
				<tr>
					<td>Address 1:</td>
					<td><input type="text" value="#HTMLEditFormat( prc.brewery.getAddress1() )#" name="address1" id="address1" size=50></td>
				</tr>
				<tr>
					<td>Address 2:</td>
					<td><input type="text" value="#HTMLEditFormat( prc.brewery.getAddress2() )#" name="address2" id="address2" size=50></td>
				</tr>
				<tr>
					<td>City:</td>
					<td><input type="text" value="#HTMLEditFormat( prc.brewery.getCity() )#" name="city" id="city" size=50></td>
				</tr>
				<tr>
					<td>State:</td>
					<td><input type="text" value="#HTMLEditFormat( prc.brewery.getState() )#" name="state" id="state" size=50></td>
				</tr>
				<tr>
					<td>Zip:</td>
					<td><input type="text" value="#HTMLEditFormat( prc.brewery.getCode() )#" name="code" id="code" size=50></td>
				</tr>
				<tr>
					<td>Country:</td>
					<td><input type="text" value="#HTMLEditFormat( prc.brewery.getCountry() )#" name="country" id="country" size=50></td>
				</tr>
				<tr>
					<td>Last Updated:</td>
					<td>#dateFormat( prc.brewery.getUpdated(), "full" )#</td>
				</tr>
			</table>
			
			<button type="submit">Save Brewery</button>
		
		</form>
		
	</cfif>
	
</cfoutput>