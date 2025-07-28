# AWS S3 + API Gateway + Lambda Redirect System

A CloudFormation solution that meets your specific requirements:

## 🎯 **Your Requirements Met**

✅ **API Gateway + S3 + CloudFront** with CloudFormation  
✅ **POST request** with path-based routing  
✅ **Lambda** extracts token from request body  
✅ **Token added as query parameter** (`&token=`)  
✅ **Path-based routing** (e.g., `/jamal` → `jamal/index.html`)  
✅ **SSL certificate** support for your organization  

## 🚀 **Quick Start**

### **Option 1: Immediate Testing (No CloudFront)**
```bash
chmod +x deploy_no_cloudfront.sh
./deploy_no_cloudfront.sh --quick
```

### **Option 2: Production (With CloudFront)**
```bash
# After AWS account verification for CloudFront
aws cloudformation create-stack \
  --stack-name aws-upwork-certificate \
  --template-body file://cloudformation_template_with_cloudfront.yaml \
  --parameters ParameterKey=BucketName,ParameterValue=aws-upwork-certificate \
  --capabilities CAPABILITY_NAMED_IAM \
  --region ap-southeast-1
```

## 📁 **Files**

- `cloudformation_template_no_cloudfront.yaml` - Template without CloudFront (immediate use)
- `cloudformation_template_with_cloudfront.yaml` - Template with CloudFront (after verification)
- `deploy_no_cloudfront.sh` - Deployment script for no-CloudFront version
- `sample-html/` - Sample HTML files for testing

## 🧪 **Testing**

```bash
# Test the deployed system
curl -X POST https://your-api-id.execute-api.ap-southeast-1.amazonaws.com/prod/jamal \
  -H "Content-Type: application/json" \
  -d '{"token": "demo-token-123"}'
```

**Expected result:** 302 redirect to `jamal/index.html?token=demo-token-123`

## 🔧 **Configuration**

- **Default Bucket**: `aws-upwork-certificate`
- **Default Region**: `ap-southeast-1`
- **Default Stack**: `aws-upwork-certificate-no-cf`

## 📞 **Support**

If you encounter CloudFront verification issues, contact AWS Support with the error message from your deployment logs. 