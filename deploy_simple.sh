#!/bin/bash

# Simple S3 Bucket Deployment Script
# This script deploys just an S3 bucket for testing

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check AWS CLI
if ! command -v aws &> /dev/null; then
    print_error "AWS CLI is not installed"
    exit 1
fi

# Check AWS credentials
if ! aws sts get-caller-identity &> /dev/null; then
    print_error "AWS credentials not configured"
    exit 1
fi

print_success "AWS CLI and credentials verified"

# Configuration
BUCKET_NAME="aws-upwork-certificate"
AWS_REGION="ap-southeast-1"
STACK_NAME="simple-s3-bucket"

print_status "Deploying simple S3 bucket..."
print_status "Bucket: $BUCKET_NAME"
print_status "Region: $AWS_REGION"
print_status "Stack: $STACK_NAME"

# Delete existing stack if it exists
if aws cloudformation describe-stacks --stack-name "$STACK_NAME" --region "$AWS_REGION" &> /dev/null; then
    print_status "Deleting existing stack..."
    aws cloudformation delete-stack --stack-name "$STACK_NAME" --region "$AWS_REGION"
    aws cloudformation wait stack-delete-complete --stack-name "$STACK_NAME" --region "$AWS_REGION"
fi

# Create new stack
print_status "Creating new stack..."
aws cloudformation create-stack \
    --stack-name "$STACK_NAME" \
    --template-body file://simple_cloudformation_template.yaml \
    --parameters ParameterKey=BucketName,ParameterValue="$BUCKET_NAME" \
    --region "$AWS_REGION"

print_status "Waiting for stack creation..."
aws cloudformation wait stack-create-complete --stack-name "$STACK_NAME" --region "$AWS_REGION"

# Get outputs
S3_URL=$(aws cloudformation describe-stacks \
    --stack-name "$STACK_NAME" \
    --region "$AWS_REGION" \
    --query 'Stacks[0].Outputs[?OutputKey==`S3WebsiteURL`].OutputValue' \
    --output text)

# Upload sample files
print_status "Uploading sample HTML files..."
if [ -d "sample-html" ]; then
    aws s3 sync sample-html/ "s3://$BUCKET_NAME/" --region "$AWS_REGION"
    print_success "Sample files uploaded"
else
    print_error "sample-html directory not found"
fi

print_success "=== DEPLOYMENT COMPLETE ==="
echo
echo "S3 Bucket: $BUCKET_NAME"
echo "S3 Website URL: $S3_URL"
echo
echo "Test URLs:"
echo "- Main page: $S3_URL"
echo "- Jamal page: $S3_URL/jamal/"
echo "- Page 1: $S3_URL/page1/"
echo "- Page 2: $S3_URL/page2/"
echo
echo "Note: This is just an S3 bucket. For full API Gateway + Lambda functionality,"
echo "you'll need to contact AWS Support for CloudFront verification first." 