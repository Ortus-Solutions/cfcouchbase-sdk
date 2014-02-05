<cfoutput>
	<h1>Edit Beer Details</h1>
				
	<cfif isnull(prc.beer)>
		
		Invalid beerID "#HTMLEditFormat( rc.beerID )#"
	
	<cfelse>
			
		<a href="#event.buildLink( linkTo="brewery.view", queryString="breweryID=#HTMLEditFormat( prc.beer.getBrewery_id() )#" )#">Back to Brewery Details</a><br><br>
		<a href="#event.buildLink( linkTo="beer.view", queryString="beerID=#HTMLEditFormat( prc.beer.getBeerID() )#" )#">Back to beer Details</a><br><br>
		
		<form action="#event.buildLink( "beer.update" )#" method="post">
			<input type="hidden" value="#HTMLEditFormat( prc.beer.getBeerID() )#" name="beerID" id="beerID">
		
			<table>
				<tr>
					<td>Name:</td>
					<td><input type="text" value="#HTMLEditFormat( prc.beer.getName() )#" name="name" id="name" size=50></td>
				</tr>
				<tr>
					<td>Category:</td>
					<td>
						<input type="text" value="#HTMLEditFormat( prc.beer.getCategory() )#" name="category" id="category" size=50>
					</td>
				</tr>
				<tr>
					<td>Style:</td>
					<td>
						<input type="text" value="#HTMLEditFormat( prc.beer.getStyle() )#" name="style" id="style" size=50>
					</td>
				</tr>
				<tr>
					<td>Description:</td>
					<td>
						<textarea name="description" id="description" rows="7" cols="75">#HTMLEditFormat( prc.beer.getDescription() )#</textarea>
					</td>
				</tr>
				<tr>
					<td>IBU:</td>
					<td><input type="text" value="#HTMLEditFormat( prc.beer.getIBU() )#" name="ibu" id="ibu" size=50></td>
				</tr>
				<tr>
					<td>SRM:</td>
					<td><input type="text" value="#HTMLEditFormat( prc.beer.getSRM() )#" name="srm" id="srm" size=50></td>
				</tr>
				<tr>
					<td>UPC</td>
					<td><input type="text" value="#HTMLEditFormat( prc.beer.getUPC() )#" name="upc" id="upc" size=50></td>
				</tr>
				<tr>
					<td>Last Updated:</td>
					<td>#dateFormat( prc.beer.getUpdated(), "full" )#</td>
				</tr>
			</table>
			
			<button type="submit">Save beer</button>
		
		</form>
		
	</cfif>
	
</cfoutput>