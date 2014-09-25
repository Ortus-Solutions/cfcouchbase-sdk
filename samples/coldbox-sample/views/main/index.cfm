<cfoutput>
<cfloop array="#prc.beers#" index="thisBeer">
<div class="well well-sm">
	<h1>#thisBeer.id# (<small>#thisBeer.key#</small>)</h1>
	<h2>Properties:</h2>
	<ul>
		<cfloop collection="#thisBeer.document#" item="thisDoc">
			<li>
				<strong>#lcase( thisDoc )#:</strong>
				<cfif isSimpleValue( thisBeer.document[ thisDoc ] )>
					#thisBeer.document[ thisDoc ]#
				<cfelse>
					<cfdump var="#thisBeer.document[ thisDoc ]#">
				</cfif>
			</li>
		</cfloop>
	</ul>
</div>
</cfloop>
</cfoutput>