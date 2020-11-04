#!/bin/bash
cd /opt/tomcat/bin
touch setenv.sh
sudo chmod +x setenv.sh
echo "export CONNECTIONSTRING='jdbc:mysql://${dbhostname}/csye6225?createDatabaseIfNotExist=true&useUnicode=true&useJDBCCompliantTimezoneShift=true&useLegacyDatetimeCode=false&serverTimezone=UTC'" >> setenv.sh
echo "export PASSWORD=${dbpassword}" >> setenv.sh
echo "export DBUSERNAME=${dbusername}" >> setenv.sh 
echo "export region='${awsregion}'" >> setenv.sh
echo "export bucketName='${bucketname}'" >> setenv.sh 
echo "export JAVA_OPTS=\"\$JAVA_OPTS -Dspring.datasource.url='${connectionStringName}' -Djava.io.tmpdir='/opt/tomcat/temp' -Dspring.servlet.multipart.location='/opt/tomcat/temp' -Dspring.datasource.username=${dbusername} -Dspring.datasource.password=${dbpassword}\"" >> setenv.sh








