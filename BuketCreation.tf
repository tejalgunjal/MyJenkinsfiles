provider "aws" {
  region = "us-west-2"
access_key = "xxx"
  secret_key = "xxx"
}
resource "aws_s3_bucket" "example" {
  bucket = "${var.environment}1234-example-bucket"
  acl    = "private"
}
output "bucket_name" {
  value = aws_s3_bucket.example.bucket
}
