variable "region_name" {
}
variable "profile" {
}
variable "credentials" {
}

variable "vpcname" {
  default = "name"
}

variable "vpccidr" {
  default = "cidr"
}
variable "vpcenablehost" {
  default = "enablehost"
}
variable "vpc" {
  type = "map"
}

variable "availabilityZone" {
  type = list(string)
}

variable "subnetcidr" {
  type = list(string)
}

variable "subnetname" {
  type = list(string)
}

variable "publicroute" {

}
variable "route_table_name" {

}

variable "ig_name" {
}

variable "subnet_map_public" {
}

variable "publicprotocol" {
}

variable "application_security_group_name" {
}

variable "database_security_group_name" {
}

variable "ingress_from_port" {
}

variable "ingress_to_port" {
}
variable "egress_from_port" {
}

variable "egress_to_port" {
}

variable "http_ports" {
  type = list(number)
}

variable "protocol" {
}

variable "mysql_protocol" {
}


## variable for S3 bucket

variable "transition_days" {
}

variable "transition_class" {
}
variable "lifecycle_id" {
}

variable "lifecycle_enabled" {
}

variable "sse_algorithm" {
}

variable "bucket_name" {
}

variable "bucket_acl" {
}

variable "dbusername" {
}

variable "dbpassword" {
}

variable "instanceAmi" {
}


variable "instanceKey" {
}

variable "instanceType" {
}

variable "associatepublicip" {
}

variable "instance_volume_type" {
}

variable "instance_volume_size" {
}

variable "instance_role" {
}


variable "db_allocated_storage" {
}

variable "db_storage_type" {
}

variable "db_engine" {
}

variable "db_engine_version" {
}

variable "db_instance_class" {
}

variable "db_name" {
}

variable "db_username" {
}
variable "db_password" {
}

variable "db_parameter_group_name" {
}

variable "db_skip_final_snapshot" {
}

variable "db_publicly_accessible" {
}


variable "aws_db_subnet_group_name" {
}


variable "connectionstring1" {
}
# variable "connectionstring2" {
# }

variable "GH-Upload-To-S3" {
}

variable "codedeploy-service-role" {
}

variable "GH-Code-Deploy" {
}

variable "aws_codedeploye_arn" {
}

variable "compute_platform" {
}
variable "codedeploy_appname" {
}
variable "codedeploy_groupname" {
}

variable "cicd_username" {
}


variable "instance_tag_key" {
}

variable "instance_tag_type" {
}

variable "instance_tag_value" {
}
variable "instance_name" {
}

variable "route53_zone_name" {
}

variable "route53_zone_record_type" {
}
variable "ttl" {
}


variable "accountid" {
}
variable "deployment_config_name" {
}

variable "dynamodb_table_name" {
}

variable "dynamodb_column_name" {
}

variable "dynamodb_column_type" {
}

variable "write_capacity" {
}

variable "read_capacity" {
}

