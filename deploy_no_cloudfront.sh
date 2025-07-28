#!/bin/bash

# AWS S3 + API Gateway Deployment Script (No CloudFront)
# This script deploys the system without CloudFront for testing

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
        print_status "To configure AWS credentials, run: aws configure"
        print_status "You'll need:"
        print_status "  - AWS Access Key ID"
        print_status "  - AWS Secret Access Key"
        print_status "  - Default region (e.g., ap-southeast-1)"
        print_status "  - Default output format (json)"
        exit 1
    fi
    print_success "AWS credentials are configured"
}

# Check if required files exist
check_required_files() {
    if [ ! -f "cloudformation_template_no_cloudfront.yaml" ]; then
        print_error "CloudFormation template file 'cloudformation_template_no_cloudfront.yaml' not found."
        print_error "Please ensure you're running this script from the correct directory."
        exit 1
    fi
    
    if [ ! -d "sample-html" ]; then
        print_warning "Sample HTML directory 'sample-html' not found."
        print_warning "No sample files will be uploaded to S3."
    fi
    
    print_success "Required files check completed"
}

# Get user input
get_user_input() {
    echo
    print_status "Please provide the following information:"
    
    # Pre-configured bucket name
    DEFAULT_BUCKET_NAME="aws-upwork-certificate"
    
    read -p "Enter a unique S3 bucket name (default: $DEFAULT_BUCKET_NAME): " BUCKET_NAME
    BUCKET_NAME=${BUCKET_NAME:-$DEFAULT_BUCKET_NAME}
    
    if [ -z "$BUCKET_NAME" ]; then
        print_error "Bucket name cannot be empty"
        exit 1
    fi
    
    read -p "Enter AWS region (default: ap-southeast-1): " AWS_REGION
    AWS_REGION=${AWS_REGION:-ap-southeast-1}
    
    read -p "Enter stack name (default: redirect-system-no-cf): " STACK_NAME
    STACK_NAME=${STACK_NAME:-redirect-system-no-cf}
}

# Quick deployment with pre-configured settings
quick_deploy() {
    print_status "Using quick deployment with pre-configured settings..."
    
    BUCKET_NAME="aws-upwork-certificate"
    AWS_REGION="ap-southeast-1"
    STACK_NAME="aws-upwork-certificate-no-cf"
    
    print_status "Bucket Name: $BUCKET_NAME"
    print_status "AWS Region: $AWS_REGION"
    print_status "Stack Name: $STACK_NAME"
    echo
}

# Deploy CloudFormation stack
deploy_stack() {
    print_status "Deploying CloudFormation stack (without CloudFront)..."
    
    # Check if stack already exists
    if aws cloudformation describe-stacks --stack-name "$STACK_NAME" --region "$AWS_REGION" &> /dev/null; then
        print_warning "Stack '$STACK_NAME' already exists. Do you want to update it? (y/n): "
        read -r response
        if [[ ! "$response" =~ ^[Yy]$ ]]; then
            print_error "Deployment cancelled. Please choose a different stack name."
            exit 1
        fi
        print_status "Updating existing stack..."
        aws cloudformation update-stack \
            --stack-name "$STACK_NAME" \
            --template-body file://cloudformation_template_no_cloudfront.yaml \
            --parameters ParameterKey=BucketName,ParameterValue="$BUCKET_NAME" \
            --capabilities CAPABILITY_NAMED_IAM \
            --region "$AWS_REGION"
    else
        print_status "Creating new stack..."
        aws cloudformation create-stack \
            --stack-name "$STACK_NAME" \
            --template-body file://cloudformation_template_no_cloudfront.yaml \
            --parameters ParameterKey=BucketName,ParameterValue="$BUCKET_NAME" \
            --capabilities CAPABILITY_NAMED_IAM \
            --region "$AWS_REGION"
    fi
    
    print_status "Waiting for stack operation to complete..."
    aws cloudformation wait stack-create-complete \
        --stack-name "$STACK_NAME" \
        --region "$AWS_REGION" || \
    aws cloudformation wait stack-update-complete \
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
    
    print_success "Stack outputs retrieved"
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
    print_success "=== DEPLOYMENT COMPLETE (No CloudFront) ==="
    echo
    echo "Stack Name: $STACK_NAME"
    echo "S3 Bucket: $BUCKET_NAME"
    echo "AWS Region: $AWS_REGION"
    echo
    echo "=== ENDPOINTS ==="
    echo "API Gateway URL: $API_URL"
    echo "S3 Website URL: $S3_URL"
    echo
    echo "=== TESTING ==="
    echo "Test the API with:"
    echo "curl -X POST $API_URL/jamal \\"
    echo "  -H \"Content-Type: application/json\" \\"
    echo "  -d '{\"token\": \"demo-token-123\"}'"
    echo
    echo "Expected result: 302 redirect to"
    echo "$S3_URL/jamal/index.html?token=demo-token-123"
    echo
    echo "=== IMPORTANT NOTES ==="
    echo "⚠️  This deployment does NOT include CloudFront"
    echo "⚠️  S3 website URLs are HTTP only (not HTTPS)"
    echo "⚠️  Performance may be slower without CDN"
    echo
    echo "=== NEXT STEPS ==="
    echo "1. Test the redirect system using the curl command above"
    echo "2. Contact AWS Support to verify your account for CloudFront"
    echo "3. Once verified, deploy the full version with CloudFront"
    echo "4. Add your own HTML files to the S3 bucket"
    echo
    echo "=== TROUBLESHOOTING ==="
    echo "If you encounter issues:"
    echo "- Check CloudWatch logs: aws logs describe-log-groups --log-group-name-prefix /aws/lambda"
    echo "- View stack events: aws cloudformation describe-stack-events --stack-name $STACK_NAME"
    echo "- Delete stack if needed: aws cloudformation delete-stack --stack-name $STACK_NAME"
    echo
}

# Show help
show_help() {
    echo "🚀 AWS S3 + API Gateway Deployment Script (No CloudFront)"
    echo "========================================================"
    echo
    echo "Usage:"
    echo "  ./deploy_no_cloudfront.sh              # Interactive deployment"
    echo "  ./deploy_no_cloudfront.sh --quick      # Quick deployment"
    echo "  ./deploy_no_cloudfront.sh -q           # Quick deployment (short form)"
    echo "  ./deploy_no_cloudfront.sh --help       # Show this help"
    echo
    echo "Quick deployment uses:"
    echo "  - Bucket Name: aws-upwork-certificate"
    echo "  - AWS Region: ap-southeast-1"
    echo "  - Stack Name: aws-upwork-certificate-no-cf"
    echo
    echo "This version works around CloudFront account verification issues."
    echo
}

# Check for help argument
if [ "$1" = "--help" ] || [ "$1" = "-h" ] || [ "$1" = "help" ]; then
    show_help
    exit 0
fi

# Main deployment function
main() {
    echo "🚀 AWS S3 + API Gateway Deployment Script (No CloudFront)"
    echo "========================================================"
    
    # Pre-deployment checks
    check_aws_cli
    check_aws_credentials
    check_required_files
    
    # Check if quick deployment is requested
    if [ "$1" = "--quick" ] || [ "$1" = "-q" ]; then
        quick_deploy
    else
        # Get user input
        get_user_input
    fi
    
    # Deploy the stack
    deploy_stack
    
    # Post-deployment setup
    get_stack_outputs
    upload_sample_files
    
    # Show summary
    show_summary
}

# Run the script
main "$@" 