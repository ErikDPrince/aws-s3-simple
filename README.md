Here is a ready-to-deploy AWS CloudFormation template that builds a minimal-cost infrastructure with the following components:

S3 Bucket (public static hosting)

CloudFront distribution (caches and serves S3 content)

API Gateway (HTTP) endpoint

Lambda function to redirect POST requests with token to S3 HTML files

IAM Role and Policy for Lambda