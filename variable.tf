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

