#!/bin/bash

# AWS Deployment Setup Script for Nerdchurch Partners Corporation Blog
# This script sets up S3, CloudFront, Lambda, and API Gateway for cost-effective hosting

set -e

echo "🚀 Setting up AWS infrastructure for Nerd Guild blog..."

# Configuration
BUCKET_NAME="nerdguild-blog"
STACK_NAME="nerdguild-blog-stack"
REGION="us-east-1"  # Use us-east-1 for free tier and lowest costs

# Check for required environment variables
if [ -z "$GITHUB_CLIENT_ID" ] || [ -z "$GITHUB_CLIENT_SECRET" ]; then
  echo "❌ Error: Please set GITHUB_CLIENT_ID and GITHUB_CLIENT_SECRET environment variables"
  echo "Create a GitHub OAuth app at: https://github.com/settings/developers"
  echo "Use these values:"
  echo "  Homepage URL: https://your-domain.com (update after CloudFront setup)"
  echo "  Callback URL: https://your-domain.com/admin"
  exit 1
fi

echo "📦 Creating S3 bucket for static hosting..."
aws s3 mb s3://$BUCKET_NAME --region $REGION || echo "Bucket may already exist"

echo "🔧 Configuring S3 bucket for static website hosting..."
aws s3 website s3://$BUCKET_NAME/ \
  --index-document index.html \
  --error-document 404.html

echo "📝 Setting bucket policy for public read access..."
cat > /tmp/bucket-policy.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "PublicReadGetObject",
      "Effect": "Allow",
      "Principal": "*",
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::$BUCKET_NAME/*"
    }
  ]
}
EOF

aws s3api put-bucket-policy \
  --bucket $BUCKET_NAME \
  --policy file:///tmp/bucket-policy.json

echo "⚡ Creating Lambda function for OAuth..."
cd deploy/lambda-oauth
zip -r function.zip index.mjs

aws lambda create-function \
  --function-name nerdguild-oauth-proxy \
  --runtime nodejs20.x \
  --role arn:aws:iam::$(aws sts get-caller-identity --query Account --output text):role/lambda-execution-role \
  --handler index.handler \
  --zip-file fileb://function.zip \
  --environment Variables="{GITHUB_CLIENT_ID=$GITHUB_CLIENT_ID,GITHUB_CLIENT_SECRET=$GITHUB_CLIENT_SECRET}" \
  --region $REGION \
  || echo "Lambda function may already exist, updating..."

aws lambda update-function-code \
  --function-name nerdguild-oauth-proxy \
  --zip-file fileb://function.zip \
  --region $REGION

cd ../..

echo "🌐 Creating API Gateway for OAuth endpoint..."
# API Gateway setup would go here
# For simplicity, we'll use Lambda Function URL (free tier, easier setup)

echo "🔗 Creating Lambda Function URL..."
FUNCTION_URL=$(aws lambda create-function-url-config \
  --function-name nerdguild-oauth-proxy \
  --auth-type NONE \
  --cors '{
    "AllowOrigins": ["*"],
    "AllowMethods": ["POST", "OPTIONS"],
    "AllowHeaders": ["Content-Type"],
    "MaxAge": 300
  }' \
  --region $REGION \
  --query 'FunctionUrl' \
  --output text || \
  aws lambda get-function-url-config \
    --function-name nerdguild-oauth-proxy \
    --region $REGION \
    --query 'FunctionUrl' \
    --output text)

echo "✅ OAuth endpoint created: $FUNCTION_URL"
echo "📝 Save this URL - you'll need it for Decap CMS config"

echo "☁️  Creating CloudFront distribution..."
echo "Note: CloudFront distribution creation takes 15-20 minutes"
echo "Run deploy/create-cloudfront.sh after this completes"

echo ""
echo "✅ AWS infrastructure setup complete!"
echo ""
echo "📋 Next steps:"
echo "1. Update src/pages/admin.astro with:"
echo "   - base_url: '$FUNCTION_URL'"
echo "   - Remove local_backend: true"
echo "2. Add GitHub collaborators to repo (for CMS access)"
echo "3. Run: npm run build"
echo "4. Run: ./deploy/deploy-to-s3.sh"
echo "5. Run: ./deploy/create-cloudfront.sh"
