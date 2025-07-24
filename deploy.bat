@echo off
setlocal enabledelayedexpansion

REM AWS S3 + CloudFront + API Gateway Deployment Script for Windows
REM This script automates the deployment of the redirect system

echo 🚀 AWS S3 + CloudFront + API Gateway Deployment Script
echo ==================================================

REM Check if AWS CLI is installed
where aws >nul 2>nul
if %errorlevel% neq 0 (
    echo [ERROR] AWS CLI is not installed. Please install it first.
    echo Visit: https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html
    pause
    exit /b 1
)
echo [SUCCESS] AWS CLI is installed

REM Check if AWS credentials are configured
aws sts get-caller-identity >nul 2>nul
if %errorlevel% neq 0 (
    echo [ERROR] AWS credentials are not configured. Please run 'aws configure' first.
    pause
    exit /b 1
)
echo [SUCCESS] AWS credentials are configured

REM Get user input
echo.
echo [INFO] Please provide the following information:

set /p BUCKET_NAME="Enter a unique S3 bucket name (must be globally unique): "
if "%BUCKET_NAME%"=="" (
    echo [ERROR] Bucket name cannot be empty
    pause
    exit /b 1
)

set /p AWS_REGION="Enter AWS region (default: us-east-1): "
if "%AWS_REGION%"=="" set AWS_REGION=us-east-1

set /p STACK_NAME="Enter stack name (default: redirect-system): "
if "%STACK_NAME%"=="" set STACK_NAME=redirect-system

REM Deploy CloudFormation stack
echo [INFO] Deploying CloudFormation stack...
aws cloudformation create-stack ^
    --stack-name "%STACK_NAME%" ^
    --template-body file://cloudformation_template.yaml ^
    --parameters ParameterKey=BucketName,ParameterValue="%BUCKET_NAME%" ^
    --capabilities CAPABILITY_NAMED_IAM ^
    --region "%AWS_REGION%"

if %errorlevel% neq 0 (
    echo [ERROR] Failed to create CloudFormation stack
    pause
    exit /b 1
)

echo [INFO] Waiting for stack creation to complete...
aws cloudformation wait stack-create-complete ^
    --stack-name "%STACK_NAME%" ^
    --region "%AWS_REGION%"

if %errorlevel% neq 0 (
    echo [ERROR] Stack creation failed or timed out
    pause
    exit /b 1
)

echo [SUCCESS] CloudFormation stack deployed successfully!

REM Get stack outputs
echo [INFO] Getting stack outputs...

for /f "tokens=*" %%i in ('aws cloudformation describe-stacks --stack-name "%STACK_NAME%" --region "%AWS_REGION%" --query "Stacks[0].Outputs[?OutputKey=='APIEndpoint'].OutputValue" --output text') do set API_URL=%%i

for /f "tokens=*" %%i in ('aws cloudformation describe-stacks --stack-name "%STACK_NAME%" --region "%AWS_REGION%" --query "Stacks[0].Outputs[?OutputKey=='S3WebsiteURL'].OutputValue" --output text') do set S3_URL=%%i

for /f "tokens=*" %%i in ('aws cloudformation describe-stacks --stack-name "%STACK_NAME%" --region "%AWS_REGION%" --query "Stacks[0].Outputs[?OutputKey=='CloudFrontDomain'].OutputValue" --output text') do set CF_DOMAIN=%%i

echo [SUCCESS] Stack outputs retrieved

REM Update CloudFront domain in SSM
if not "%CF_DOMAIN%"=="" if not "%CF_DOMAIN%"=="None" (
    echo [INFO] Updating CloudFront domain in SSM...
    aws ssm put-parameter ^
        --name "/cf/domain" ^
        --value "%CF_DOMAIN%" ^
        --type "String" ^
        --overwrite ^
        --region "%AWS_REGION%"
    echo [SUCCESS] CloudFront domain updated in SSM
) else (
    echo [WARNING] CloudFront domain not found in stack outputs
)

REM Upload sample HTML files
echo [INFO] Uploading sample HTML files to S3...
if exist "sample-html" (
    aws s3 sync sample-html/ "s3://%BUCKET_NAME%/" --region "%AWS_REGION%"
    echo [SUCCESS] Sample HTML files uploaded
) else (
    echo [WARNING] sample-html directory not found, skipping file upload
)

REM Display deployment summary
echo.
echo [SUCCESS] === DEPLOYMENT COMPLETE ===
echo.
echo Stack Name: %STACK_NAME%
echo S3 Bucket: %BUCKET_NAME%
echo AWS Region: %AWS_REGION%
echo.
echo === ENDPOINTS ===
echo API Gateway URL: %API_URL%
echo S3 Website URL: %S3_URL%
if not "%CF_DOMAIN%"=="" if not "%CF_DOMAIN%"=="None" (
    echo CloudFront Domain: %CF_DOMAIN%
)
echo.
echo === TESTING ===
echo Test the API with:
echo curl -X POST %API_URL%page1 ^
echo   -H "Content-Type: application/json" ^
echo   -d "{\"token\": \"demo-token-123\"}"
echo.
echo === NEXT STEPS ===
echo 1. Wait for CloudFront distribution to deploy (5-10 minutes)
echo 2. Test the redirect system using the curl command above
echo 3. Customize the Lambda function if needed
echo 4. Add your own HTML files to the S3 bucket
echo.

pause 