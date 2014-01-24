<cfoutput>
<div class="container-fluid">
	<div class="hero-unit text-center" id="header">
		<img class="margin10" src="includes/images/couchbase_logo.png" alt="logo"/>
		<div class="pull-right">
			<span class="label label-warning"> <i class="icon-book icon-white"></i> Version #rc.version#</span>
		</div>
	</div>
	<div class="row-fluid">
		#prc.wikiContent#
	</div>
</div>
<script>
$(function() {
	$("table.toc").wrap( '<div class="toc-container" />');
	$("table.toc h2").html( "Table of Contents" );
})
</script>
</cfoutput>