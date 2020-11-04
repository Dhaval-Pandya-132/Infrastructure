provider "aws" {
  region                  = var.region_name
  shared_credentials_file = var.credentials
  profile                 = var.profile
}

resource "aws_vpc" "vpc1" {
  cidr_block           = var.vpc[var.vpccidr]
  enable_dns_hostnames = var.vpc[var.vpcenablehost]
  tags = {
    Name = var.vpc[var.vpccidr]
  }
}

resource "aws_subnet" "subnet1" {
  vpc_id                  = aws_vpc.vpc1.id
  availability_zone       = var.availabilityZone[0]
  map_public_ip_on_launch = var.subnet_map_public
  cidr_block              = var.subnetcidr[0]
  tags = {
    Name = var.subnetname[0]
  }
}

resource "aws_subnet" "subnet2" {
  vpc_id                  = aws_vpc.vpc1.id
  map_public_ip_on_launch = var.subnet_map_public
  availability_zone       = var.availabilityZone[1]
  cidr_block              = var.subnetcidr[1]
  tags = {
    Name = var.subnetname[1]
  }
}

resource "aws_subnet" "subnet3" {
  vpc_id                  = aws_vpc.vpc1.id
  map_public_ip_on_launch = var.subnet_map_public
  availability_zone       = var.availabilityZone[2]
  cidr_block              = var.subnetcidr[2]
  tags = {
    Name = var.subnetname[2]
  }
}

resource "aws_internet_gateway" "internetgateway" {
  vpc_id = aws_vpc.vpc1.id
  tags = {
    Name = var.ig_name
  }
}
resource "aws_route_table" "routetable" {
  vpc_id = aws_vpc.vpc1.id

  route {
    cidr_block = var.publicroute
    gateway_id = aws_internet_gateway.internetgateway.id
  }
  tags = {
    Name = var.route_table_name
  }
}

resource "aws_main_route_table_association" "associate_vpc" {
  vpc_id         = aws_vpc.vpc1.id
  route_table_id = aws_route_table.routetable.id
}

resource "aws_route_table_association" "associate_subnet1" {
  subnet_id      = aws_subnet.subnet1.id
  route_table_id = aws_route_table.routetable.id
}

resource "aws_route_table_association" "associate_subnet2" {
  subnet_id      = aws_subnet.subnet2.id
  route_table_id = aws_route_table.routetable.id
}

resource "aws_route_table_association" "associate_subnet3" {
  subnet_id      = aws_subnet.subnet3.id
  route_table_id = aws_route_table.routetable.id
}

resource "aws_security_group" "allow_all" {
  name   = var.application_security_group_name
  vpc_id = aws_vpc.vpc1.id

  egress {
    from_port   = var.egress_from_port
    to_port     = var.egress_to_port
    protocol    = var.publicprotocol
    cidr_blocks = [var.publicroute]
  }

  tags = {
    Name = var.application_security_group_name
  }
}


resource "aws_security_group_rule" "ingress_http" {
  count = "${length(var.http_ports)}"

  type        = "ingress"
  protocol    = var.protocol
  cidr_blocks = [var.publicroute]
  from_port   = "${element(var.http_ports, count.index)}"
  to_port     = "${element(var.http_ports, count.index)}"

  security_group_id = "${aws_security_group.allow_all.id}"
}
resource "aws_security_group" "database" {
  name   = var.database_security_group_name
  vpc_id = aws_vpc.vpc1.id

  ingress {
    from_port       = var.mysql_protocol
    to_port         = var.mysql_protocol
    protocol        = var.protocol
    security_groups = ["${aws_security_group.allow_all.id}"]
  }
  egress {
    from_port   = var.egress_from_port
    to_port     = var.egress_to_port
    protocol    = var.publicprotocol
    cidr_blocks = [var.publicroute]
  }

  tags = {
    Name = var.database_security_group_name
  }
}

resource "aws_db_subnet_group" "default" {
  name       = var.aws_db_subnet_group_name
  subnet_ids = [aws_subnet.subnet1.id, aws_subnet.subnet2.id, aws_subnet.subnet3.id]

  tags = {
    Name = var.aws_db_subnet_group_name
  }
}

resource "aws_db_instance" "mysqlinstance" {
  allocated_storage      = var.db_allocated_storage
  storage_type           = var.db_storage_type
  engine                 = var.db_engine
  engine_version         = var.db_engine_version
  instance_class         = var.db_instance_class
  name                   = var.db_name
  username               = var.db_username
  password               = var.db_password
  parameter_group_name   = var.db_parameter_group_name
  skip_final_snapshot    = var.db_skip_final_snapshot
  publicly_accessible    = var.db_publicly_accessible
  vpc_security_group_ids = [aws_security_group.database.id]
  db_subnet_group_name   = aws_db_subnet_group.default.name
}


resource "aws_s3_bucket" "s3bucket" {
  bucket        = var.bucket_name
  acl           = var.bucket_acl
  force_destroy = true
  lifecycle_rule {
    id      = var.lifecycle_id
    enabled = var.lifecycle_enabled

    transition {
      days          = var.transition_days
      storage_class = var.transition_class
    }
  }
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = var.sse_algorithm
      }
    }
  }
  tags = {
    Name = var.bucket_name
  }
}

resource "aws_iam_role" "iamrole" {
  name               = var.instance_role
  assume_role_policy = "${file("${path.module}/assume_policy.json")}"
}

resource "aws_iam_instance_profile" "instance_profile" {
  name = var.instance_role
  role = "${aws_iam_role.iamrole.name}"
}


data "template_file" "policytemplate" {
  vars = {
    bucket_name = var.bucket_name
  }
  template = "${file("${path.module}/policy.json")}"
}

resource "aws_iam_role_policy" "s3policy" {
  name   = "WebAppS3"
  role   = "${aws_iam_role.iamrole.id}"
  policy = "${data.template_file.policytemplate.rendered}"
}


data "template_file" "CodeDeploy_EC2S3Policy_template" {
  template = "${file("${path.module}/codeDeployEC2Policy.json")}"
}

resource "aws_iam_policy" "CodeDeploy_EC2S3Policy" {
  name   = var.GH-Upload-To-S3
  policy = "${data.template_file.CodeDeploy_EC2S3Policy_template.rendered}"
}

resource "aws_iam_role_policy_attachment" "test-attach" {
  role       = aws_iam_role.iamrole.name
  policy_arn = aws_iam_policy.CodeDeploy_EC2S3Policy.arn
}

data "template_file" "codeDeployService_template" {
  template = "${file("${path.module}/codeDeployServicePolicy.json")}"
}

resource "aws_iam_role" "codedeploy_service" {
  name               = var.codedeploy-service-role
  assume_role_policy = "${data.template_file.codeDeployService_template.rendered}"
}

data "template_file" "CodeDeployService_S3Policy_template" {
  vars = {
    region_name        = var.region_name
    accountid          = var.accountid
    codedeploy_appname = var.codedeploy_appname
  }

  template = "${file("${path.module}/codeDeployS3Policy.json")}"
}

resource "aws_iam_policy" "CodeDeployService_S3Policy" {
  name   = var.GH-Code-Deploy
  policy = "${data.template_file.CodeDeployService_S3Policy_template.rendered}"
}

resource "aws_iam_role_policy_attachment" "attach-AWSCodeDeployRole-service-policy" {
  role       = aws_iam_role.codedeploy_service.name
  policy_arn = var.aws_codedeploye_arn
}

resource "aws_codedeploy_app" "codedeploymentApp" {
  compute_platform = var.compute_platform
  name             = var.codedeploy_appname
}

resource "aws_codedeploy_deployment_group" "deploymentGroup" {
  app_name               = aws_codedeploy_app.codedeploymentApp.name
  deployment_group_name  = var.codedeploy_groupname
  service_role_arn       = aws_iam_role.codedeploy_service.arn
  deployment_config_name = var.deployment_config_name
  ec2_tag_set {
    ec2_tag_filter {
      key   = var.instance_tag_key
      type  = var.instance_tag_type
      value = var.instance_tag_value
    }

  }
}

resource "aws_iam_user_policy_attachment" "CodeDeployService_S3Policy_IAM" {
  user       = var.cicd_username
  policy_arn = aws_iam_policy.CodeDeployService_S3Policy.arn
}
resource "aws_iam_user_policy_attachment" "CodeDeploy_EC2S3Policy_IAM" {
  user       = var.cicd_username
  policy_arn = aws_iam_policy.CodeDeploy_EC2S3Policy.arn
}


data "template_file" "userdata" {
  vars = {
    dbhostname           = aws_db_instance.mysqlinstance.endpoint,
    dbpassword           = var.dbpassword,
    dbusername           = var.dbusername,
    awsregion            = var.region_name,
    bucketname           = var.bucket_name,
    connectionStringName = join("", var.connectionstring1) //format("$%s", "{CONNECTIONSTRING}")
  }
  template = "${file("${path.module}/myuserdata.sh")}"
}

resource "aws_instance" "ec2instance" {
  ami                         = var.instanceAmi
  instance_type               = var.instanceType
  key_name                    = var.instanceKey
  vpc_security_group_ids      = [aws_security_group.allow_all.id]
  subnet_id                   = aws_subnet.subnet1.id
  associate_public_ip_address = var.associatepublicip
  iam_instance_profile        = aws_iam_instance_profile.instance_profile.name
  user_data                   = "${data.template_file.userdata.rendered}"

  root_block_device {
    volume_type = var.instance_volume_type
    volume_size = var.instance_volume_size
  }

  tags = {
    Name = var.instance_name
  }
}

data "aws_route53_zone" "primaryZone" {
  name         = var.route53_zone_name
  private_zone = false
}

resource "aws_route53_record" "api" {
  zone_id = data.aws_route53_zone.primaryZone.zone_id
  name    = "api.${data.aws_route53_zone.primaryZone.name}"
  type    = var.route53_zone_record_type
  ttl     = var.ttl
  records = [aws_instance.ec2instance.public_ip]
}


resource "aws_dynamodb_table" "csye6225" {
  name           = var.dynamodb_table_name
  hash_key       = var.dynamodb_column_name
  write_capacity = var.write_capacity
  read_capacity  = var.read_capacity
  attribute {
    name = var.dynamodb_column_name
    type = var.dynamodb_column_type
  }
}
