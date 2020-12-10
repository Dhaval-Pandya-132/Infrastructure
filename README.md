# Infrastructure

### Index 

  1) [Introduction](#Introduction)
  2) [Project Dependencies](#Project-Dependencies)
  3) [Import certificate using  aws cli](#Import-certificate-using-aws-cl)
 
 

## Introduction 
This project will create basic infrastructure to deploy amazon EC2 instance 


## Project Dependencies

    Terraform v0.13.4

## Import certificate using aws cli 

    aws acm import-certificate --certificate fileb://certificateBody.pem --certificate-chain fileb://certificateChain.pem --private-key fileb://privateKey.pem --region us-east-1 --profile prod


## Verify RDS is connection is secured 
    mysql> SELECT distinct id, user, host, connection_type 
       FROM performance_schema.threads pst 
       INNER JOIN information_schema.processlist isp 
       ON pst.processlist_id = isp.id;     

## Install mysql client
    sudo apt install mysql-client-core-5.7 -y