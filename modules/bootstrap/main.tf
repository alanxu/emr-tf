resource "aws_s3_bucket" "bootstrap" {
  bucket = "${var.cluster_name}-bootstrap-${var.region}-${var.env}"
  # acl    = "private"

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

data "template_file" "configure_system" {
  template = "${file("${path.module}/templates/configure-system.sh.tpl")}"

  vars = {
    bootstrap_bucket           = "${aws_s3_bucket.bootstrap.bucket}"
  }
}

resource "aws_s3_bucket_object" "configure_system" {
  key     = "configure-system.sh"
  bucket  = "${aws_s3_bucket.bootstrap.bucket}"
  content = "${data.template_file.configure_system.rendered}"
  etag    = "${md5(data.template_file.configure_system.rendered)}"
}

resource "aws_s3_bucket_object" "log4j_spark" {
  key    = "log4j_spark.properties"
  bucket = "${aws_s3_bucket.bootstrap.bucket}"
  source = "${path.module}/files/log4j_spark.properties"
  etag   = "${md5(file("${path.module}/files/log4j_spark.properties"))}"
}
