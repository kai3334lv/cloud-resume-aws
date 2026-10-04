provider "aws" {
  region = "ap-south-1"
}

# 1. Secure S3 Bucket
resource "aws_s3_bucket" "resume_bucket" {
  # IMPORTANT: S3 Bucket names must be globally unique. 
  # If you get an error that this name exists, add some random numbers at the end!
  bucket = "rahul-resume-website-2026" 
  
  tags = {
    Project     = "CloudResumeChallenge"
    Owner       = "Rahul"
    Environment = "Production"
    ManagedBy   = "Terraform"
  }
}

resource "aws_s3_bucket_public_access_block" "resume_bucket_block" {
  bucket = aws_s3_bucket.resume_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# 2. Origin Access Control (OAC)
resource "aws_cloudfront_origin_access_control" "oac" {
  name                              = "resume-oac"
  description                       = "Allow CloudFront to access private S3 bucket"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# 3. CloudFront Distribution
resource "aws_cloudfront_distribution" "s3_distribution" {
  origin {
    domain_name              = aws_s3_bucket.resume_bucket.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.oac.id
    origin_id                = "resumeS3Origin"
  }

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "resumeS3Origin"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  tags = {
    Project   = "CloudResumeChallenge"
    ManagedBy = "Terraform"
  }
}

# 4. S3 Bucket Policy
data "aws_iam_policy_document" "s3_policy" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.resume_bucket.arn}/*"]
    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.s3_distribution.arn]
    }
  }
}

resource "aws_s3_bucket_policy" "resume_bucket_policy" {
  bucket = aws_s3_bucket.resume_bucket.id
  policy = data.aws_iam_policy_document.s3_policy.json
}