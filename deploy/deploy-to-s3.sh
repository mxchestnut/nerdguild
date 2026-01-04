#!/bin/bash

# Deploy built site to S3
# Run this after: npm run build

set -e

BUCKET_NAME="nerdguild-blog"
BASE_DIR="/Users/kit/Downloads/primapersona_2026"

echo "📤 Deploying to S3..."

if [ ! -d "$BASE_DIR/dist" ]; then
  echo "❌ Error: dist folder not found. Run 'npm run build' first"
  exit 1
fi

echo "Syncing files to S3..."
aws s3 sync $BASE_DIR/dist/ s3://$BUCKET_NAME/ \
  --delete \
  --cache-control "public, max-age=31536000, immutable" \
  --exclude "*.html" \
  --exclude "admin/*"

echo "Uploading HTML files with no-cache..."
aws s3 sync $BASE_DIR/dist/ s3://$BUCKET_NAME/ \
  --exclude "*" \
  --include "*.html" \
  --cache-control "public, max-age=0, must-revalidate"

echo "Uploading admin files with no-cache..."
aws s3 sync $BASE_DIR/dist/admin/ s3://$BUCKET_NAME/admin/ \
  --cache-control "public, max-age=0, must-revalidate"

echo "✅ Deployment complete!"
echo "🌐 Website URL: http://$BUCKET_NAME.s3-website-us-east-1.amazonaws.com"
