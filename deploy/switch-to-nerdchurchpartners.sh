#!/bin/bash

# Update CloudFront to use nerdchurchpartners.org
# Run this after SSL certificate is validated

set -e

CERT_ARN="arn:aws:acm:us-east-1:680363506283:certificate/d5c8aaa3-99c0-4971-8d98-89580c72c36e"
DISTRIBUTION_ID="EYJBB4GHI6WQO"
HOSTED_ZONE_ID="Z0239438155R78W5TB9X3"

echo "🔍 Checking certificate status..."
STATUS=$(aws acm describe-certificate \
  --certificate-arn $CERT_ARN \
  --region us-east-1 \
  --query 'Certificate.Status' \
  --output text)

if [ "$STATUS" != "ISSUED" ]; then
  echo "⏳ Certificate status: $STATUS"
  echo "Waiting for validation to complete..."
  
  for i in {1..20}; do
    sleep 15
    STATUS=$(aws acm describe-certificate \
      --certificate-arn $CERT_ARN \
      --region us-east-1 \
      --query 'Certificate.Status' \
      --output text)
    echo "Attempt $i: $STATUS"
    
    if [ "$STATUS" = "ISSUED" ]; then
      break
    fi
  done
  
  if [ "$STATUS" != "ISSUED" ]; then
    echo "❌ Certificate still not validated after 5 minutes"
    echo "Please wait a bit longer and run this script again"
    exit 1
  fi
fi

echo "✅ Certificate validated!"

echo "📝 Updating CloudFront distribution..."
ETAG=$(aws cloudfront get-distribution-config --id $DISTRIBUTION_ID --query 'ETag' --output text)
aws cloudfront get-distribution-config --id $DISTRIBUTION_ID --query 'DistributionConfig' > /tmp/cf-ncp-final.json

cat /tmp/cf-ncp-final.json | jq '.Aliases = {"Quantity": 1, "Items": ["nerdchurchpartners.org"]} | .ViewerCertificate = {"ACMCertificateArn": "'$CERT_ARN'", "SSLSupportMethod": "sni-only", "MinimumProtocolVersion": "TLSv1.2_2021", "Certificate": "'$CERT_ARN'", "CertificateSource": "acm"}' > /tmp/cf-ncp-final-updated.json

aws cloudfront update-distribution \
  --id $DISTRIBUTION_ID \
  --distribution-config file:///tmp/cf-ncp-final-updated.json \
  --if-match $ETAG \
  --query 'Distribution.Status' \
  --output text

echo "☁️  CloudFront updated! Status: InProgress"

echo "🌐 Updating Route53 A record..."
cat > /tmp/ncp-a-record.json <<EOF
{
  "Changes": [
    {
      "Action": "UPSERT",
      "ResourceRecordSet": {
        "Name": "nerdchurchpartners.org",
        "Type": "A",
        "AliasTarget": {
          "HostedZoneId": "Z2FDTNDATAQYW2",
          "DNSName": "d2i05hxa7gvf6v.cloudfront.net",
          "EvaluateTargetHealth": false
        }
      }
    }
  ]
}
EOF

aws route53 change-resource-record-sets \
  --hosted-zone-id $HOSTED_ZONE_ID \
  --change-batch file:///tmp/ncp-a-record.json

echo ""
echo "✅ All done!"
echo "🌐 Your site will be live at: https://nerdchurchpartners.org"
echo "⏳ CloudFront deployment takes 10-15 minutes"
echo ""
echo "📝 Don't forget to update your GitHub OAuth app:"
echo "   Homepage URL: https://nerdchurchpartners.org"
echo "   Callback URL: https://nerdchurchpartners.org/admin"
