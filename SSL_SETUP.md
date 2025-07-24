# SSL Certificate Setup Guide

This guide explains how to integrate your organization's SSL certificate with the CloudFormation template.

## Option 1: Using AWS Certificate Manager (Recommended)

### Step 1: Uncomment SSL Sections
In `cloudformation_template.yaml`, uncomment and modify these sections:

```yaml
CloudFrontDistribution:
  Type: AWS::CloudFront::Distribution
  Properties:
    DistributionConfig:
      # ... existing config ...
      Aliases:
        - your-domain.com
        - www.your-domain.com
      ViewerCertificate:
        AcmCertificateArn: !Ref SSLCertificate
        SslSupportMethod: sni-only
        MinimumProtocolVersion: TLSv1.2_2021

SSLCertificate:
  Type: AWS::CertificateManager::Certificate
  Properties:
    DomainName: your-domain.com
    SubjectAlternativeNames:
      - www.your-domain.com
    ValidationMethod: DNS
```

### Step 2: Replace Domain Names
Replace `your-domain.com` with your actual domain name.

### Step 3: Validate Certificate
After deployment, AWS will send validation emails or provide DNS records to validate your domain ownership.

## Option 2: Using Existing Certificate

If you already have a certificate in ACM:

```yaml
CloudFrontDistribution:
  Type: AWS::CloudFront::Distribution
  Properties:
    DistributionConfig:
      # ... existing config ...
      Aliases:
        - your-domain.com
      ViewerCertificate:
        AcmCertificateArn: arn:aws:acm:us-east-1:123456789012:certificate/your-cert-id
        SslSupportMethod: sni-only
```

## Option 3: Import External Certificate

### Step 1: Import Certificate to ACM
```bash
aws acm import-certificate \
  --certificate fileb://certificate.pem \
  --private-key fileb://private-key.pem \
  --certificate-chain fileb://chain.pem \
  --region us-east-1
```

### Step 2: Use Certificate ARN
Use the returned certificate ARN in your CloudFormation template.

## Important Notes

1. **Region Requirement**: CloudFront certificates must be in `us-east-1` region
2. **Domain Validation**: Certificates must be validated before use
3. **DNS Configuration**: Update your DNS to point to CloudFront distribution
4. **HTTPS Only**: CloudFront will redirect HTTP to HTTPS

## DNS Configuration

After deployment, update your domain's DNS:

```
Type: CNAME
Name: your-domain.com
Value: [CloudFront Distribution Domain]
```

## Testing SSL

```bash
# Test HTTPS redirect
curl -I http://your-domain.com

# Test SSL certificate
openssl s_client -connect your-domain.com:443 -servername your-domain.com
```

## Troubleshooting

- **Certificate not found**: Ensure certificate is in us-east-1 region
- **Domain not validated**: Complete DNS or email validation
- **HTTPS not working**: Check CloudFront distribution status
- **DNS not resolving**: Verify CNAME record points to CloudFront domain 