#!/bin/bash

# Create CloudFront distribution for HTTPS and global CDN
# This is optional but recommended for production

set -e

BUCKET_NAME="nerdguild-blog"
REGION="us-east-1"

echo "☁️  Creating CloudFront distribution..."

cat > /tmp/cloudfront-config.json <<EOF
{
  "CallerReference": "nerdguild-$(date +%s)",
  "Comment": "Nerd Guild Blog CDN",
  "DefaultRootObject": "index.html",
  "Origins": {
    "Quantity": 1,
    "Items": [
      {
        "Id": "S3-$BUCKET_NAME",
        "DomainName": "$BUCKET_NAME.s3-website-$REGION.amazonaws.com",
        "CustomOriginConfig": {
          "HTTPPort": 80,
          "HTTPSPort": 443,
          "OriginProtocolPolicy": "http-only"
        }
      }
    ]
  },
  "DefaultCacheBehavior": {
    "TargetOriginId": "S3-$BUCKET_NAME",
    "ViewerProtocolPolicy": "redirect-to-https",
    "AllowedMethods": {
      "Quantity": 2,
      "Items": ["GET", "HEAD"],
      "CachedMethods": {
        "Quantity": 2,
        "Items": ["GET", "HEAD"]
      }
    },
    "Compress": true,
    "MinTTL": 0,
    "DefaultTTL": 86400,
    "MaxTTL": 31536000,
    "ForwardedValues": {
      "QueryString": false,
      "Cookies": {
        "Forward": "none"
      }
    }
  },
  "CustomErrorResponses": {
    "Quantity": 1,
    "Items": [
      {
        "ErrorCode": 404,
        "ResponsePagePath": "/404.html",
        "ResponseCode": "404",
        "ErrorCachingMinTTL": 300
      }
    ]
  },
  "Enabled": true,
  "PriceClass": "PriceClass_100"
}
EOF

echo "Creating distribution (this takes 15-20 minutes)..."
DISTRIBUTION_ID=$(aws cloudfront create-distribution \
  --distribution-config file:///tmp/cloudfront-config.json \
  --query 'Distribution.Id' \
  --output text)

DOMAIN=$(aws cloudfront get-distribution \
  --id $DISTRIBUTION_ID \
  --query 'Distribution.DomainName' \
  --output text)

echo "✅ CloudFront distribution created!"
echo "📋 Distribution ID: $DISTRIBUTION_ID"
echo "🌐 CloudFront Domain: https://$DOMAIN"
echo ""
echo "⏳ Distribution is deploying... (15-20 minutes)"
echo "Check status: aws cloudfront get-distribution --id $DISTRIBUTION_ID"
echo ""
echo "📝 Next steps:"
echo "1. Wait for distribution to deploy (check status above)"
echo "2. Run: ./setup-route53.sh $DISTRIBUTION_ID"
echo "3. Your site will be live at: https://nerdguild.org"
