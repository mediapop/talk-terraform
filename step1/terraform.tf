provider "aws" {
  region = "ap-southeast-1"
}

resource "aws_s3_bucket" "bucket" {
  bucket = "fluff.mediapop.co"
  acl = "public-read"
  "website" {
    index_document = "index.html"
  }
}
