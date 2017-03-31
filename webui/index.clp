<!DOCTYPE html>
<html>
<head>
	<script src="https://ajax.googleapis.com/ajax/libs/jquery/3.1.0/jquery.min.js"></script>
	<script>
		$(document).ready(function() {

			$('#first-action').click(function() {
			console.log('click');
				$.ajax({
					type: 'POST',
					dataType: 'html',
					data: {
					 test: 'test'
					},
					url: 'first-action-function',
					error:function() {
						alert('error');
					},
					success: function(data, textStatus, jqXHR) {
						console.log(jqXHR.responseText);
					}
				});
			});
			
			$('#first-action-xml').click(function() {
			console.log('click');
				$.ajax({
					type: 'POST',
					dataType: 'xml',
					data: {
					 test: 'test'
					},
					url: 'first-action-function-xml',
					error:function() {
						alert('error');
					},
					success: function(data, textStatus, jqXHR) {
						console.log(jqXHR.responseText);
					}
				});
			});

		});
	</script>
</head>
<body>
	<h1>
		LKM Artwork DB
	</h1>

	<p>
		There are currently <strong><art_item-count/></strong> item(s) in the database.
	</p>

	<button id="first-action">Send HTML back</button>
	<button id="first-action-xml">Send XML back</button>

	<h2>View items</h2>
	<a href="view-items">view</a>

	<h2>Add an item</h2>
	<a href="add-item">add</a>
</body>
</html>