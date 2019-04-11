/*
This is a good place to CREATE USERs, DATABASEs, and maybe GRANT some permissions to those users. 
Also, we override the default password declared in the docker-compose, and set it to something better. 
*/
SET PASSWORD FOR 'root'@'localhost' = PASSWORD('strongerPassword');
FLUSH PRIVILEGES;


