#!/bin/bash

# Install Apache and configure web page
sudo apt-get update
sudo apt-get install -y apache2
sudo systemctl start apache2
sudo echo "<h1>This is a test</h1>" > /var/www/html/index.html

# Set hostname and IP address variables
HOSTNAME=$(hostname)
IP_ADDRESS=$(hostname -I | awk '{print $1}')

# Generate VM information web page
sudo cat <<EOF > /var/www/html/index.html
<html>
<head>
<title>VM Information</title>
</head>
<body>
<h1>VM Information</h1>
<h2>Hostname: $HOSTNAME</h2>
<h2>IP Address: $IP_ADDRESS</h2>
</body>
</html>
EOF