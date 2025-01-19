resource "aws_s3_bucket" "tf_state" {
  bucket = "project-terraform-backend-dev"
}

resource "aws_s3_bucket_versioning" "tf_lock" {
  bucket = aws_s3_bucket.tf_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_dynamodb_table" "tf_lock" {
  name         = "project-terraform-backend-dev"
  billing_mode = "PAY_PER_REQUEST"

  attribute {
    name = "LockID"
    type = "S"
  }

  hash_key = "LockID"
}
