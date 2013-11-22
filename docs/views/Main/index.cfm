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
<!---Google Analytics --->
<script type="text/javascript">

  var _gaq = _gaq || [];
  _gaq.push(['_setAccount', 'UA-16538389-2']);
  _gaq.push(['_trackPageview']);

  (function() {
    var ga = document.createElement('script'); ga.type = 'text/javascript'; ga.async = true;
    ga.src = ('https:' == document.location.protocol ? 'https://ssl' : 'http://www') + '.google-analytics.com/ga.js';
    var s = document.getElementsByTagName('script')[0]; s.parentNode.insertBefore(ga, s);
  })();

</script>
</cfoutput>