# AWS S3 + CloudFront + API Gateway Redirect System

A ready-to-deploy AWS CloudFormation template that builds a minimal-cost infrastructure with the following components:

- **S3 Bucket** (public static hosting)
- **CloudFront distribution** (caches and serves S3 content)
- **API Gateway** (HTTP) endpoint
- **Lambda function** to redirect POST requests with token to S3 HTML files
- **IAM Role and Policy** for Lambda

## Quick Start

### Option 1: Automated Deployment (Recommended)

**For Windows:**
```cmd
deploy.bat
```

**For Linux/macOS:**
```bash
chmod +x deploy.sh
./deploy.sh
```

### Option 2: Manual Deployment

1. Install and configure AWS CLI
2. Deploy the CloudFormation stack:
   ```bash
   aws cloudformation create-stack \
     --stack-name redirect-system \
     --template-body file://cloudformation_template.yaml \
     --parameters ParameterKey=BucketName,ParameterValue=your-unique-bucket-name \
     --capabilities CAPABILITY_NAMED_IAM
   ```

## Files Included

- `cloudformation_template.yaml` - Main CloudFormation template
- `deploy.sh` - Linux/macOS deployment script
- `deploy.bat` - Windows deployment script
- `SETUP_GUIDE.md` - Detailed setup instructions
- `sample-html/` - Sample HTML files for testing
  - `index.html` - Main page with testing interface
  - `page1/index.html` - Sample page 1
  - `page2/index.html` - Sample page 2

## How It Works

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

## Testing

After deployment, test the system with:

```bash
curl -X POST https://your-api-id.execute-api.region.amazonaws.com/prod/page1 \
  -H "Content-Type: application/json" \
  -d '{"token": "demo-token-123"}'
```

This should return a 302 redirect to your CloudFront URL.

## Documentation

- See `SETUP_GUIDE.md` for detailed setup instructions
- Check the sample HTML files for examples of how to structure your content