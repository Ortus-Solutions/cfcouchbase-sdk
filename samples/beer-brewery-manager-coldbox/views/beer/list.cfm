<cfoutput>
	<table border="1" cellpadding=5 cellspacing=0>
		<tr>
			<td></td>
			<td>Name</td>
			<td>Category</td>
			<td>Style</td>
			<td>Description</td>
		</tr>
		<cfloop array="#prc.breweryBeers#" index="beerRow">
			<cfset beer = beerRow.document>
			<tr>
				<td><a href="#event.buildLink( linkTo="beer.view", queryString="beerID=#beer.getBeerID()#" )#">View</a></td>
				<td>#HTMLEditFormat( beer.getName() )#</td>
				<td>
					#HTMLEditFormat( beer.getCategory() )#
				</td>
				<td>
					#HTMLEditFormat( beer.getStyle() )#
				</td>
				<td>
					<cfif len( beer.getDescription() ) GT 50>
						<span title="#HTMLEditFormat( beer.getDescription() )#">#HTMLEditFormat( left( beer.getDescription(), 50) )#...</span>
					<cfelse>
						#HTMLEditFormat( beer.getDescription() )#
					</cfif>
				</td>
			</tr>
		</cfloop>
	</table>
</cfoutput>		