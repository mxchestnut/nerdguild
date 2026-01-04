#!/bin/bash

# Create IAM role for Lambda function
# Run this before aws-setup.sh

set -e

echo "🔐 Creating IAM role for Lambda..."

# Create trust policy
cat > /tmp/lambda-trust-policy.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

# Create the role
aws iam create-role \
  --role-name lambda-execution-role \
  --assume-role-policy-document file:///tmp/lambda-trust-policy.json \
  || echo "Role may already exist"

# Attach basic Lambda execution policy
aws iam attach-role-policy \
  --role-name lambda-execution-role \
  --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole

echo "✅ IAM role created: lambda-execution-role"
echo "⏳ Wait 10 seconds for role to propagate..."
sleep 10
