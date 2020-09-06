<html>
<body>
<h1>Sample App</h1>
Instance-ID: <?=file_get_contents("http://169.254.169.254/latest/meta-data/instance-id") ?><br>
Public IP: <?=file_get_contents("http://169.254.169.254/latest/meta-data/public-ipv4") ?><br>
<a href="?kill">Kill</a>
</body>
</html>

<?php
if (isset($_REQUEST['kill'])) {
    // Remove self if kill query / post variable is set
    unlink(__FILE__);
}
?>
