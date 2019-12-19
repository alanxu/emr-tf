variable "project" {
  default = "alan-poc"
}

variable "environment" {
  default = "dev"
}

variable "name" {
  default = "my-emr-1"
}

variable "region" {
  default = "us-east-1"
}


variable "vpc_id" {
  default = "vpc-01373d642560468d7"
}

variable "release_label" {
  default = "emr-5.28.0"
}

variable "applications" {
  default = ["Spark", "Hive", "Hadoop", "Livy", "JupyterHub"]
  type    = "list"
}

variable "configurations" {
  default = <<EOF
[
  {
    "Classification": "spark-env",
    "Configurations": [
      {
        "Classification": "export",
        "Properties": {
            "PYSPARK_PYTHON": "/usr/bin/python3"
          }
      }
    ]
  }
]
EOF
}

variable "key_name" {
  default = "cmf-ec2"
}

variable "subnet_id" {
  default = "subnet-0303e60e78b5262d3"
}

variable "instance_groups" {
  default = [
    {
      name           = "MasterInstanceGroup"
      instance_role  = "MASTER"
      instance_type  = "m3.xlarge"
      instance_count = 1
    },
    {
      name           = "CoreInstanceGroup"
      instance_role  = "CORE"
      instance_type  = "m3.xlarge"
      instance_count = "4"
    }
  ]

  type = "list"
}

variable "bootstrap_name" {
  default = ""
}

variable "bootstrap_uri" {
  default = ""
}

variable "bootstrap_args" {
  default = []
  type    = "list"
}

variable "log_uri" {
  default = "s3n://alan-1/logs/emr"
}
