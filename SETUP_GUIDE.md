# AWS S3 + CloudFront + API Gateway Setup Guide

This guide will walk you through setting up the minimal-cost infrastructure using the CloudFormation template.

## Prerequisites

1. **AWS CLI** installed and configured
2. **AWS Account** with appropriate permissions
3. **S3 bucket name** (must be globally unique)

## Step 1: Prepare Your Environment

### Install AWS CLI (if not already installed)
```bash
# Windows (using Chocolatey)
choco install awscli

# macOS (using Homebrew)
brew install awscli

# Linux
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
```

### Configure AWS CLI
```bash
aws configure
```
Enter your:
- AWS Access Key ID
- AWS Secret Access Key
- Default region (e.g., us-east-1)
- Default output format (json)

## Step 2: Deploy the CloudFormation Stack

### Option A: Using AWS CLI
```bash
# Replace 'your-unique-bucket-name' with a globally unique S3 bucket name
aws cloudformation create-stack \
  --stack-name redirect-system \
  --template-body file://cloudformation_template.yaml \
  --parameters ParameterKey=BucketName,ParameterValue=your-unique-bucket-name \
  --capabilities CAPABILITY_NAMED_IAM
```

### Option B: Using AWS Console
1. Go to AWS CloudFormation console
2. Click "Create stack" → "With new resources"
3. Choose "Upload a template file"
4. Upload the `cloudformation_template.yaml` file
5. Click "Next"
6. Enter stack name: `redirect-system`
7. Enter bucket name parameter (must be globally unique)
8. Click "Next" → "Next" → "Create stack"

## Step 3: Monitor Deployment

### Check Stack Status
```bash
aws cloudformation describe-stacks --stack-name redirect-system --query 'Stacks[0].StackStatus'
```

### View Stack Outputs
```bash
aws cloudformation describe-stacks --stack-name redirect-system --query 'Stacks[0].Outputs'
```

## Step 4: Update CloudFront Domain in Lambda

After deployment, you need to update the CloudFront domain in the Lambda function:

### Get CloudFront Domain
```bash
aws cloudformation describe-stacks --stack-name redirect-system --query 'Stacks[0].Outputs[?OutputKey==`CloudFrontDomain`].OutputValue' --output text
```

### Update SSM Parameter
```bash
# Replace 'your-cloudfront-domain' with the actual CloudFront domain
aws ssm put-parameter \
  --name "/cf/domain" \
  --value "your-cloudfront-domain" \
  --type "String" \
  --overwrite
```

## Step 5: Upload HTML Files to S3

### Create Sample HTML Files
Create a directory structure like this:
```
your-html-files/
├── page1/
│   └── index.html
├── page2/
│   └── index.html
└── index.html
```

### Upload to S3
```bash
# Replace 'your-bucket-name' with your actual bucket name
aws s3 sync your-html-files/ s3://your-bucket-name/
```

## Step 6: Test the System

### Test API Gateway Endpoint
```bash
# Replace with your actual API Gateway URL
curl -X POST https://your-api-id.execute-api.region.amazonaws.com/prod/page1 \
  -H "Content-Type: application/json" \
  -d '{"token": "your-token-here"}'
```

This should return a 302 redirect to your CloudFront URL.

## Step 7: Customize the Lambda Function (Optional)

The Lambda function currently redirects to `index.html` files. You can modify it by:

1. Go to AWS Lambda console
2. Find the `RedirectHandler` function
3. Edit the code to match your specific requirements

## Architecture Overview

```
Client → API Gateway → Lambda → CloudFront → S3
```

1. **Client** sends POST request with token to API Gateway
2. **API Gateway** forwards request to Lambda
3. **Lambda** processes the token and path, returns redirect
4. **CloudFront** serves the HTML content from S3
5. **S3** stores the static HTML files

## Cost Optimization

This setup is designed to be cost-effective:
- **S3**: Pay only for storage and requests
- **CloudFront**: Free tier includes 1TB data transfer
- **Lambda**: Free tier includes 1M requests/month
- **API Gateway**: Pay per request (very low cost)

## Troubleshooting

### Common Issues

1. **Bucket name already exists**: Choose a globally unique name
2. **IAM permissions**: Ensure your AWS user has CloudFormation permissions
3. **Lambda timeout**: Default timeout is 3 seconds, increase if needed
4. **CORS issues**: Add CORS headers to Lambda response if needed

### Useful Commands

```bash
# Delete the stack if needed
aws cloudformation delete-stack --stack-name redirect-system

# View stack events
aws cloudformation describe-stack-events --stack-name redirect-system

# Update stack
aws cloudformation update-stack \
  --stack-name redirect-system \
  --template-body file://cloudformation_template.yaml \
  --parameters ParameterKey=BucketName,ParameterValue=your-bucket-name
```

## Security Considerations

1. **S3 Bucket**: Currently public for demo - add authentication for production
2. **API Gateway**: Consider adding API keys or JWT validation
3. **Lambda**: Review IAM permissions and add least-privilege access
4. **CloudFront**: Enable HTTPS and configure security headers

## Next Steps

1. Add authentication to the API Gateway
2. Implement token validation in Lambda
3. Set up monitoring and logging
4. Configure CloudFront caching rules
5. Add custom domain names 