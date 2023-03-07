!/bin/bash
sudo yum install -y mariadb-server
sudo systemctl enable mariadb
sudo systemctl start mariadb
mysql -u root -e "CREATE DATABASE mydb"
mysql -u root -e "CREATE USER 'myuser'@'localhost' IDENTIFIED BY 'mypassword'"
mysql -u root -e "GRANT ALL PRIVILEGES ON mydb.* TO 'myuser'@'localhost'"