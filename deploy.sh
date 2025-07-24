#!/bin/bash

# AWS S3 + CloudFront + API Gateway Deployment Script
# This script automates the deployment of the redirect system

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if AWS CLI is installed
check_aws_cli() {
    if ! command -v aws &> /dev/null; then
        print_error "AWS CLI is not installed. Please install it first."
        echo "Visit: https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html"
        exit 1
    fi
    print_success "AWS CLI is installed"
}

# Check if AWS credentials are configured
check_aws_credentials() {
    if ! aws sts get-caller-identity &> /dev/null; then
        print_error "AWS credentials are not configured. Please run 'aws configure' first."
        exit 1
    fi
    print_success "AWS credentials are configured"
}

# Get user input
get_user_input() {
    echo
    print_status "Please provide the following information:"
    
    read -p "Enter a unique S3 bucket name (must be globally unique): " BUCKET_NAME
    if [ -z "$BUCKET_NAME" ]; then
        print_error "Bucket name cannot be empty"
        exit 1
    fi
    
    read -p "Enter AWS region (default: us-east-1): " AWS_REGION
    AWS_REGION=${AWS_REGION:-us-east-1}
    
    read -p "Enter stack name (default: redirect-system): " STACK_NAME
    STACK_NAME=${STACK_NAME:-redirect-system}
}

# Deploy CloudFormation stack
deploy_stack() {
    print_status "Deploying CloudFormation stack..."
    
    aws cloudformation create-stack \
        --stack-name "$STACK_NAME" \
        --template-body file://cloudformation_template.yaml \
        --parameters ParameterKey=BucketName,ParameterValue="$BUCKET_NAME" \
        --capabilities CAPABILITY_NAMED_IAM \
        --region "$AWS_REGION"
    
    print_status "Waiting for stack creation to complete..."
    aws cloudformation wait stack-create-complete \
        --stack-name "$STACK_NAME" \
        --region "$AWS_REGION"
    
    print_success "CloudFormation stack deployed successfully!"
}

# Get stack outputs
get_stack_outputs() {
    print_status "Getting stack outputs..."
    
    # Get API Gateway URL
    API_URL=$(aws cloudformation describe-stacks \
        --stack-name "$STACK_NAME" \
        --region "$AWS_REGION" \
        --query 'Stacks[0].Outputs[?OutputKey==`APIEndpoint`].OutputValue' \
        --output text)
    
    # Get S3 Website URL
    S3_URL=$(aws cloudformation describe-stacks \
        --stack-name "$STACK_NAME" \
        --region "$AWS_REGION" \
        --query 'Stacks[0].Outputs[?OutputKey==`S3WebsiteURL`].OutputValue' \
        --output text)
    
    # Get CloudFront domain
    CF_DOMAIN=$(aws cloudformation describe-stacks \
        --stack-name "$STACK_NAME" \
        --region "$AWS_REGION" \
        --query 'Stacks[0].Outputs[?OutputKey==`CloudFrontDomain`].OutputValue' \
        --output text)
    
    print_success "Stack outputs retrieved"
}

# Update CloudFront domain in SSM
update_cloudfront_domain() {
    if [ -n "$CF_DOMAIN" ] && [ "$CF_DOMAIN" != "None" ]; then
        print_status "Updating CloudFront domain in SSM..."
        aws ssm put-parameter \
            --name "/cf/domain" \
            --value "$CF_DOMAIN" \
            --type "String" \
            --overwrite \
            --region "$AWS_REGION"
        print_success "CloudFront domain updated in SSM"
    else
        print_warning "CloudFront domain not found in stack outputs"
    fi
}

# Upload sample HTML files
upload_sample_files() {
    print_status "Uploading sample HTML files to S3..."
    
    if [ -d "sample-html" ]; then
        aws s3 sync sample-html/ "s3://$BUCKET_NAME/" --region "$AWS_REGION"
        print_success "Sample HTML files uploaded"
    else
        print_warning "sample-html directory not found, skipping file upload"
    fi
}

# Display deployment summary
show_summary() {
    echo
    print_success "=== DEPLOYMENT COMPLETE ==="
    echo
    echo "Stack Name: $STACK_NAME"
    echo "S3 Bucket: $BUCKET_NAME"
    echo "AWS Region: $AWS_REGION"
    echo
    echo "=== ENDPOINTS ==="
    echo "API Gateway URL: $API_URL"
    echo "S3 Website URL: $S3_URL"
    if [ -n "$CF_DOMAIN" ] && [ "$CF_DOMAIN" != "None" ]; then
        echo "CloudFront Domain: $CF_DOMAIN"
    fi
    echo
    echo "=== TESTING ==="
    echo "Test the API with:"
    echo "curl -X POST $API_URL/page1 \\"
    echo "  -H \"Content-Type: application/json\" \\"
    echo "  -d '{\"token\": \"demo-token-123\"}'"
    echo
    echo "=== NEXT STEPS ==="
    echo "1. Wait for CloudFront distribution to deploy (5-10 minutes)"
    echo "2. Test the redirect system using the curl command above"
    echo "3. Customize the Lambda function if needed"
    echo "4. Add your own HTML files to the S3 bucket"
    echo
}

# Main deployment function
main() {
    echo "🚀 AWS S3 + CloudFront + API Gateway Deployment Script"
    echo "=================================================="
    
    # Pre-deployment checks
    check_aws_cli
    check_aws_credentials
    
    # Get user input
    get_user_input
    
    # Deploy the stack
    deploy_stack
    
    # Post-deployment setup
    get_stack_outputs
    update_cloudfront_domain
    upload_sample_files
    
    # Show summary
    show_summary
}

# Run the script
main "$@" 