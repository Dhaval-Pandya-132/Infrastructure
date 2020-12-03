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

resource "aws_security_group" "sg_loadBalancer" {
  name   = var.loadBalanceSecurityGroupName //"sg_loadBalancer"
  vpc_id = aws_vpc.vpc1.id

  ingress {
    from_port   = var.httpPort // 80
    to_port     = var.httpPort //80
    protocol    = var.protocol
    cidr_blocks = [var.publicroute]
  }
  egress {
    from_port   = var.egress_from_port
    to_port     = var.egress_to_port
    protocol    = var.publicprotocol
    cidr_blocks = [var.publicroute]
  }
  tags = {
    Name = var.loadBalanceSecurityGroupName //"lb_securitygroup"
  }
}

resource "aws_security_group" "allow_all" {
  name   = var.application_security_group_name
  vpc_id = aws_vpc.vpc1.id

  ingress {
    from_port       = var.apachePort //8080
    to_port         = var.apachePort //8080
    protocol        = var.protocol
    security_groups = [aws_security_group.sg_loadBalancer.id]

  }

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

  type                     = "ingress"
  protocol                 = var.protocol
  source_security_group_id = aws_security_group.sg_loadBalancer.id
  from_port                = "${element(var.http_ports, count.index)}"
  to_port                  = "${element(var.http_ports, count.index)}"

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

  vars = {
    codedeploy_bucket_name = var.codedeploy_bucket_name
  }

  template = "${file("${path.module}/codeDeployEC2Policy.json")}"
}

resource "aws_iam_policy" "CodeDeploy_EC2S3Policy" {
  name   = var.GH-Upload-To-S3
  policy = "${data.template_file.CodeDeploy_EC2S3Policy_template.rendered}"
}

resource "aws_iam_role_policy_attachment" "attach-codedeploy-policy" {
  role       = aws_iam_role.iamrole.name
  policy_arn = aws_iam_policy.CodeDeploy_EC2S3Policy.arn
}


resource "aws_iam_role_policy_attachment" "attach-cloudwatch-policy" {
  role       = aws_iam_role.iamrole.name
  policy_arn = var.cloudwatch_role_arn
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
  autoscaling_groups     = [aws_autoscaling_group.autoscalingGroup.name]

  deployment_style {
    deployment_type = "IN_PLACE"
  }

  # load_balancer_info {
  #   elb_info          = aws_lb.applicationLoadBalancer.name
  #   target_group_info = aws_lb_target_group.application_target_group.name
  # }
  load_balancer_info {
    target_group_info {
      name = aws_lb_target_group.application_target_group.name
    }

  }

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
    loggingPath          = var.loggingPath,
    loggingFile          = var.loggingFile,
    loggingLevel         = var.loggingLevel,
    topicarn             = aws_sns_topic.question_updates.arn
    connectionStringName = join("", var.connectionstring1) //format("$%s", "{CONNECTIONSTRING}")
  }
  template = "${file("${path.module}/myuserdata.sh")}"
}
/**
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
**/
data "aws_route53_zone" "primaryZone" {
  name         = var.route53_zone_name
  private_zone = false
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



resource "aws_lb_target_group" "application_target_group" {
  name        = var.targetGroupName     //"appliactionTargetGroup"
  port        = var.targetGroupPort     //8080
  protocol    = var.targetGroupProtocol //"HTTP"
  target_type = var.targetGroupType     //"instance"
  vpc_id      = aws_vpc.vpc1.id
}


resource "aws_lb" "applicationLoadBalancer" {
  name               = var.loadBalancerName     //"applicationLoadBalancer"
  internal           = var.loadBalancerInternal //false
  load_balancer_type = var.loadBalancerType     //"application"
  security_groups    = [aws_security_group.sg_loadBalancer.id]
  subnets = [aws_subnet.subnet1.id,
    aws_subnet.subnet2.id,
  aws_subnet.subnet3.id]
  enable_deletion_protection = false

  tags = {
    Name = var.loadBalancerName //"applicationLoadBalancer"
  }
}
resource "aws_lb_listener" "lb_listener" {
  load_balancer_arn = aws_lb.applicationLoadBalancer.arn
  port              = var.listenerPort     // "80"
  protocol          = var.listenerProtocol // "HTTP"

  default_action {
    type             = var.listenerDefaultActionType //"forward"
    target_group_arn = aws_lb_target_group.application_target_group.arn
  }
}

resource "aws_launch_configuration" "as_conf" {
  name_prefix                 = var.launchConfigurationName //"asg_launch_config"
  image_id                    = var.instanceAmi
  instance_type               = var.instanceType
  key_name                    = var.instanceKey
  security_groups             = [aws_security_group.allow_all.id]
  associate_public_ip_address = var.associatepublicip
  iam_instance_profile        = aws_iam_instance_profile.instance_profile.name
  user_data                   = "${data.template_file.userdata.rendered}"

  root_block_device {
    volume_type = var.instance_volume_type
    volume_size = var.instance_volume_size
  }

  lifecycle {
    create_before_destroy = true
  }
}


resource "aws_autoscaling_group" "autoscalingGroup" {
  name                 = var.autoScalingGroupName            //"autoscalingGroup"
  max_size             = var.autoScalingGroupMaxSize         //2
  min_size             = var.autoScalingGroupMinSize         //1
  desired_capacity     = var.autoScalingGroupDesiredCapacity //1
  launch_configuration = aws_launch_configuration.as_conf.name
  vpc_zone_identifier = [aws_subnet.subnet1.id
    , aws_subnet.subnet2.id
    , aws_subnet.subnet3.id
  ]

  target_group_arns = [aws_lb_target_group.application_target_group.arn]

  tags = [{
    "key"                 = "Name"
    "value"               = var.instance_name
    "propagate_at_launch" = var.autoScalingGroupPropogateOnLaunch // true
  }]
}


resource "aws_route53_record" "api" {
  zone_id = data.aws_route53_zone.primaryZone.zone_id
  name    = "${data.aws_route53_zone.primaryZone.name}"
  type    = var.route53_zone_record_type

  alias {
    name                   = aws_lb.applicationLoadBalancer.dns_name
    zone_id                = aws_lb.applicationLoadBalancer.zone_id
    evaluate_target_health = false
  }

}

resource "aws_cloudwatch_metric_alarm" "CPUAlarmHigh" {
  alarm_name          = var.alarmHighName               //"CPUAlarmHigh"
  comparison_operator = var.alarmHighComparisonOperator //"GreaterThanThreshold"
  evaluation_periods  = var.alarmHighEvalPeriod         //"1"
  metric_name         = var.alarmHighMetricName         //"CPUUtilization"
  namespace           = var.alarmHighNamespace          //"AWS/EC2"
  period              = var.alarmHighPeriod             //"300"
  statistic           = var.alarmHighStatistic          //"Average"
  threshold           = var.alarmHighThreshold          //"5"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.autoscalingGroup.name
  }
  alarm_description = "This metric monitors ec2 cpu utilization"
  alarm_actions     = [aws_autoscaling_policy.WebServerScaleUpPolicy.arn]
}


resource "aws_autoscaling_policy" "WebServerScaleUpPolicy" {
  policy_type            = var.scalUpPolicyType                  //"SimpleScaling"
  name                   = var.scalUpPolicyName                  //"WebServerScaleUpPolicy"
  scaling_adjustment     = var.scalUpPolicyScalingAdjustment     //1
  adjustment_type        = var.scalUpPolicyScalingAdjustmentType //"ChangeInCapacity"
  cooldown               = var.scalUpPolicyCooldown              //60
  autoscaling_group_name = aws_autoscaling_group.autoscalingGroup.name
}

resource "aws_autoscaling_policy" "WebServerScaleDownPolicy" {
  policy_type            = var.scalDownPolicyType                  //"SimpleScaling"
  name                   = var.scalDownPolicyName                  //"WebServerScaleDownPolicy"
  scaling_adjustment     = var.scalDownPolicyScalingAdjustment     //-1
  adjustment_type        = var.scalDownPolicyScalingAdjustmentType //"ChangeInCapacity"
  cooldown               = var.scalDownPolicyCooldown              //60
  autoscaling_group_name = aws_autoscaling_group.autoscalingGroup.name
}


resource "aws_cloudwatch_metric_alarm" "CPUAlarmLow" {
  alarm_name          = var.alarmLowName               //"CPUAlarmLow"
  comparison_operator = var.alarmLowComparisonOperator //"LessThanThreshold"
  evaluation_periods  = var.alarmLowEvalPeriod         //"1"
  metric_name         = var.alarmLowMetricName         //"CPUUtilization"
  namespace           = var.alarmLowNamespace          //"AWS/EC2"
  period              = var.alarmLowPeriod             //"300"
  statistic           = var.alarmLowStatistic          //"Average"
  threshold           = var.alarmLowThreshold          //"3"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.autoscalingGroup.name
  }
  alarm_description = "This metric monitors ec2 cpu utilization"
  alarm_actions     = [aws_autoscaling_policy.WebServerScaleDownPolicy.arn]
}


resource "aws_sns_topic" "question_updates" {
  name = "question-updates"
}




data "template_file" "snspolicytemplate" {
  vars = {
    region    = var.region_name,
    accountid = var.accountid,
    topicname = var.topicname
  }

  template = "${file("${path.module}/sns_policy.json")}"
}

// Create SNS Policy 

resource "aws_iam_policy" "snspolicy" {
  name   = "sns_policy"
  policy = "${data.template_file.snspolicytemplate.rendered}"

}

data "template_file" "dynamodbpolicytemplate" {
  vars = {
    region    = var.region_name,
    accountid = var.accountid,
    tablename = var.dynamodb_table_name
  }
  template = "${file("${path.module}/dynamodb_policy.json")}"
}

data "template_file" "lambdacicduserpolicytemplate" {
  vars = {
    region          = var.region_name,
    accountId       = var.accountid,
    lambda_function = var.lambdafunction
  }
  template = "${file("${path.module}/lambda_codedeploy_policy.json")}"
}

resource "aws_iam_policy" "lambdacicduserpolicy" {
  name   = "lambda-cicd-user-policy"
  policy = "${data.template_file.lambdacicduserpolicytemplate.rendered}"
}


// Create DynamoDB Policy 

resource "aws_iam_policy" "dynamopolicy" {
  name   = "dynamodb_policy"
  policy = "${data.template_file.dynamodbpolicytemplate.rendered}"
}

data "template_file" "sespolicytemplate" {

  vars = {
    region       = var.region_name,
    accountid    = var.accountid,
    identityname = var.route53_zone_name
  }
  template = "${file("${path.module}/SES_policy.json")}"
}

// Create SES Policy 

resource "aws_iam_policy" "sespolicy" {
  name   = "ses_policy"
  policy = "${data.template_file.sespolicytemplate.rendered}"
}

data "template_file" "lambdapolicytemplate" {

  template = "${file("${path.module}/lambda_assume_role_policy.json")}"
}

// role for lambda function 

resource "aws_iam_role" "iam_for_lambda" {
  name               = "lambda-role"
  assume_role_policy = "${data.template_file.lambdapolicytemplate.rendered}"
}

resource "aws_iam_role_policy_attachment" "attach-dynamodb-policy" {
  role       = aws_iam_role.iam_for_lambda.name
  policy_arn = aws_iam_policy.dynamopolicy.arn
}

resource "aws_iam_role_policy_attachment" "attach-ses-policy" {
  role       = aws_iam_role.iam_for_lambda.name
  policy_arn = aws_iam_policy.sespolicy.arn
}

resource "aws_iam_role_policy_attachment" "attach-lambdacloudwatch-policy" {
  role       = aws_iam_role.iam_for_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}


resource "aws_iam_role_policy_attachment" "attach-sns-policy" {
  role       = aws_iam_role.iamrole.name
  policy_arn = aws_iam_policy.snspolicy.arn
}

resource "aws_lambda_function" "lambdafunction" {
  filename      = "Lambda.zip"
  function_name = var.lambdafunction
  role          = aws_iam_role.iam_for_lambda.arn
  handler       = var.handler
  memory_size   = var.memorysize
  timeout       = var.timeout
  runtime       = var.runtime

  environment {
    variables = {
      dynamodbTable = var.dynamodb_table_name
      identity      = var.route53_zone_name
    }
  }
}
resource "aws_sns_topic_subscription" "user_updates_sqs_target" {
  topic_arn = aws_sns_topic.question_updates.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.lambdafunction.arn
}


resource "aws_lambda_permission" "with_sns" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambdafunction.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.question_updates.arn
}

resource "aws_iam_user_policy_attachment" "lambda_cicd_policy_IAM" {
  user       = var.lambda_cicd_user
  policy_arn = aws_iam_policy.lambdacicduserpolicy.arn
}

resource "aws_iam_user_policy_attachment" "lambda_cicd_S3Policy_IAM" {
  user       = var.lambda_cicd_user
  policy_arn = aws_iam_policy.CodeDeploy_EC2S3Policy.arn
}
