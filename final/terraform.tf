provider "aws" {
  region = "ap-southeast-1"
}

variable "domain" {
  "type" = "string"
  "default" = "terraform-demo.mediapop.co"
}

variable "zone" {
  "type" = "string"
  "default" = "mediapop.co."
}

variable "certificate" {
  "type" = "string"
  "default" = "arn:aws:acm:us-east-1:178284945954:certificate/7dfb01ff-f2bb-470e-b945-8970ae05547f"
}

data "aws_route53_zone" "zone" {
  name = "${var.zone}"
}

resource "aws_s3_bucket" "bucket" {
  bucket = "${var.domain}"
  acl = "public-read"
  "website" {
    index_document = "index.html"
  }
}

resource "aws_cloudfront_distribution" "distribution" {
  "origin" {
    domain_name = "${aws_s3_bucket.bucket.bucket}.s3.amazonaws.com"
    origin_id = "website"
  }
  enabled = true
  is_ipv6_enabled = true

  aliases = [
    "${var.domain}"
  ]

  default_root_object = "index.html"

  "default_cache_behavior" {
    allowed_methods = [
      "HEAD",
      "GET"
    ]
    cached_methods = [
      "HEAD",
      "GET"
    ]
    "forwarded_values" {
      query_string = false
      "cookies" {
        forward = "none"
      }
    }
    default_ttl = 0
    max_ttl = 0
    min_ttl = 0
    target_origin_id = "website"
    viewer_protocol_policy = "redirect-to-https"
    compress = true
  }

  cache_behavior {
    allowed_methods = ["HEAD", "GET"]
    cached_methods = ["HEAD", "GET"]
    "forwarded_values" {
      "cookies" {
        forward = "none"
      }
      query_string = false
    }
    default_ttl = 31536000
    max_ttl = 31536000
    min_ttl = 31536000
    path_pattern = "assets/*"
    target_origin_id = "website"
    viewer_protocol_policy = "redirect-to-https"
    compress = true
  }

  "restrictions" {
    "geo_restriction" {
      restriction_type = "none"
    }
  }
  viewer_certificate {
    acm_certificate_arn = "${var.certificate}"
    ssl_support_method = "sni-only"
    minimum_protocol_version = "TLSv1"
  }

  // We don't want cloudfront to cache 404's because it would mean the order we upload items in can cause 5 minutes
  // of linked-to assets being unavailable.
  custom_error_response {
    error_caching_min_ttl = 0
    error_code = 404
  }

  // It's frustrating to get locked out for 5 minutes when uploading something with the wrong ACL.
  custom_error_response {
    error_caching_min_ttl = 0
    error_code = 403
  }
}

resource "aws_route53_record" "record" {
  zone_id = "${data.aws_route53_zone.zone.zone_id}"
  name = "${var.domain}"
  type = "A"
  alias {
    name = "${aws_cloudfront_distribution.distribution.domain_name}"
    zone_id = "${aws_cloudfront_distribution.distribution.hosted_zone_id}"
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "ipv6" {
  zone_id = "${data.aws_route53_zone.zone.zone_id}"
  name = "${var.domain}"
  type = "AAAA"
  alias {
    name = "${aws_cloudfront_distribution.distribution.domain_name}"
    zone_id = "${aws_cloudfront_distribution.distribution.hosted_zone_id}"
    evaluate_target_health = false
  }
}
