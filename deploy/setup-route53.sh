#!/bin/bash

# Set up Route53 alias to point nerdguild.org to CloudFront distribution

set -e

DOMAIN="nerdchurchpartners.org"
DISTRIBUTION_ID=$1

if [ -z "$DISTRIBUTION_ID" ]; then
  echo "❌ Error: CloudFront distribution ID required"
  echo "Usage: ./setup-route53.sh <distribution-id>"
  echo ""
  echo "Get distribution ID from: ./create-cloudfront.sh output"
  echo "Or run: aws cloudfront list-distributions --query 'DistributionList.Items[*].[Id,DomainName]' --output table"
  exit 1
fi

echo "🌐 Setting up Route53 for $DOMAIN..."

# Get CloudFront domain name
CF_DOMAIN=$(aws cloudfront get-distribution \
  --id $DISTRIBUTION_ID \
  --query 'Distribution.DomainName' \
  --output text)

echo "CloudFront domain: $CF_DOMAIN"

# Get hosted zone ID for nerdguild.org
HOSTED_ZONE_ID=$(aws route53 list-hosted-zones-by-name \
  --dns-name $DOMAIN \
  --query "HostedZones[?Name=='${DOMAIN}.'].Id" \
  --output text | cut -d'/' -f3)

if [ -z "$HOSTED_ZONE_ID" ]; then
  echo "❌ Error: Hosted zone for $DOMAIN not found in Route53"
  echo "Make sure you have a hosted zone set up for nerdchurchpartners.org"
  exit 1
fi

echo "Found hosted zone: $HOSTED_ZONE_ID"

# Create/update A record
cat > /tmp/route53-change.json <<EOF
{
  "Changes": [
    {
      "Action": "UPSERT",
      "ResourceRecordSet": {
        "Name": "$DOMAIN",
        "Type": "A",
        "AliasTarget": {
          "HostedZoneId": "Z2FDTNDATAQYW2",
          "DNSName": "$CF_DOMAIN",
          "EvaluateTargetHealth": false
        }
      }
    }
  ]
}
EOF

echo "Creating A record for $DOMAIN -> $CF_DOMAIN..."
aws route53 change-resource-record-sets \
  --hosted-zone-id $HOSTED_ZONE_ID \
  --change-batch file:///tmp/route53-change.json

echo "✅ Route53 configured!"
echo "🌐 Your site will be available at: https://$DOMAIN"
echo "⏳ DNS propagation may take a few minutes"
echo ""
echo "📝 Next: Update GitHub OAuth app callback URL to: https://$DOMAIN/admin"
