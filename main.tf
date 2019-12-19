provider "aws" {
  region = "us-east-1"
  profile = "cmf"
}

#
# EMR IAM resources
#
data "aws_iam_policy_document" "emr_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["elasticmapreduce.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "emr_service_role" {
  name               = "emr${var.environment}ServiceRole"
  assume_role_policy = "${data.aws_iam_policy_document.emr_assume_role.json}"
}

resource "aws_iam_role_policy_attachment" "emr_service_role" {
  role       = "${aws_iam_role.emr_service_role.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonElasticMapReduceRole"
}

#
# EMR IAM resources for EC2
#
data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "emr_ec2_instance_profile" {
  name               = "${var.environment}JobFlowInstanceProfile"
  assume_role_policy = "${data.aws_iam_policy_document.ec2_assume_role.json}"
}

resource "aws_iam_role_policy_attachment" "emr_ec2_instance_profile" {
  role       = "${aws_iam_role.emr_ec2_instance_profile.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonElasticMapReduceforEC2Role"
}

resource "aws_iam_instance_profile" "emr_ec2_instance_profile" {
  name = "${aws_iam_role.emr_ec2_instance_profile.name}"
  role = "${aws_iam_role.emr_ec2_instance_profile.name}"
}

#
# Security group resources
#
resource "aws_security_group" "emr_master" {
  vpc_id                 = "${var.vpc_id}"
  revoke_rules_on_delete = true

  tags = {
    Name        = "sg${var.name}Master"
    Project     = "${var.project}"
    Environment = "${var.environment}"
  }

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "emr_slave" {
  vpc_id                 = "${var.vpc_id}"
  revoke_rules_on_delete = true

  tags = {
    Name        = "sg${var.name}Slave"
    Project     = "${var.project}"
    Environment = "${var.environment}"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "emr_svc_access" {
  vpc_id                 = "${var.vpc_id}"
  revoke_rules_on_delete = true

  tags = {
    Name        = "sg${var.name}ServiceAccess"
    Project     = "${var.project}"
    Environment = "${var.environment}"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


# Create EMR bootstrap action
module "bootstrap" {
  source = "./modules/bootstrap"

  cluster_name                = "${var.name}"
  region                      = "${var.region}"
  env                         = "${var.environment}"
}

#
# EMR resources
#
resource "aws_emr_cluster" "cluster" {
  name           = "${var.name}"
  release_label  = "${var.release_label}"
  applications   = "${var.applications}"
  configurations = "${var.configurations}"

  ec2_attributes {
    key_name                          = "${var.key_name}"
    subnet_id                         = "${var.subnet_id}"
    emr_managed_master_security_group = "${aws_security_group.emr_master.id}"
    emr_managed_slave_security_group  = "${aws_security_group.emr_slave.id}"
    service_access_security_group  = "${aws_security_group.emr_svc_access.id}"
    instance_profile                  = "${aws_iam_instance_profile.emr_ec2_instance_profile.arn}"
  }

  
  master_instance_group {
    instance_type = "m4.xlarge"
  }
  core_instance_group {
    instance_type  = "c4.xlarge"
    instance_count = 2

    ebs_config {
      size                 = "40"
      type                 = "gp2"
      volumes_per_instance = 1
    }
  }

  bootstrap_action {
    path = "${module.bootstrap.bootstrap_script_s3_object}"
    name = "configure_system"
    # args = "${var.bootstrap_args}"
  }

  log_uri      = "${var.log_uri}"
  service_role = "${aws_iam_role.emr_service_role.arn}"

  tags = {
    Name        = "${var.name}"
    Project     = "${var.project}"
    Environment = "${var.environment}"
  }
}
