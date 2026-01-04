# AWS Deployment Guide

Cost-effective AWS deployment for Nerd Guild blog with GitHub OAuth authentication.

## 💰 Cost Estimate

With this setup, monthly costs should be **less than $1** for small/medium traffic:

- **S3 Storage**: ~$0.02/month (for a typical static site)
- **S3 Requests**: ~$0.05/month (first 2,000 PUT requests free, then pennies)
- **CloudFront**: Free tier covers 1TB/month data transfer + 10M requests
- **Lambda**: Free tier covers 1M requests/month + 400,000 GB-seconds compute
- **Lambda Function URL**: Free

## 📋 Prerequisites

1. AWS CLI installed and configured with IAM credentials
2. GitHub account with repo: `mxchestnut/nerdguild`
3. GitHub OAuth app created

## 🚀 Deployment Steps

### Step 1: Create GitHub OAuth App

1. Go to https://github.com/settings/developers
2. Click "New OAuth App"
3. Fill in:
   - **Application name**: Nerd Guild CMS
   - **Homepage URL**: `https://nerdchurchpartners.org`
   - **Authorization callback URL**: `https://nerdchurchpartners.org/admin`
4. Click "Register application"
5. Copy **Client ID** and generate **Client Secret**
6. Export them as environment variables:
   ```bash
   export GITHUB_CLIENT_ID="your_client_id"
   export GITHUB_CLIENT_SECRET="your_client_secret"
   ```

### Step 2: Create IAM Role for Lambda

```bash
cd deploy
chmod +x *.sh
./create-lambda-role.sh
```

### Step 3: Run AWS Setup

```bash
./aws-setup.sh
```

This script will:
- Create S3 bucket for static hosting
- Deploy Lambda function for OAuth proxy
- Create Lambda Function URL for the OAuth endpoint
- Output the OAuth endpoint URL

**Important**: Copy the OAuth endpoint URL (it will look like: `https://xxxxx.lambda-url.us-east-1.on.aws/`)

### Step 4: Update Decap CMS Config

Edit `src/pages/admin.astro` and update the backend configuration:

```javascript
backend: {
  name: 'github',
  repo: 'mxchestnut/nerdguild',
  branch: 'main',
  base_url: 'https://xxxxx.lambda-url.us-east-1.on.aws',  // Your Lambda URL
  auth_endpoint: '/'
}
```

**Remove** the `local_backend: true` line.

### Step 5: Build and Deploy

```bash
cd ..
npm run build
cd deploy
./deploy-to-s3.sh
```

Your site is now live at: `http://nerdguild-blog.s3-website-us-east-1.amazonaws.com`

### Step 6: Set up CloudFront + Route53 for Custom Domain

```bash
./create-cloudfront.sh
```

This creates a CloudFront distribution (takes 15-20 minutes). Once complete:

1. Create an A record in Route53 pointing nerdchurchpartners.org to the CloudFront distribution
2. Your site will be live at https://nerdchurchpartners.org

## 👥 Adding CMS Users

Only GitHub users who are **collaborators** on the `mxchestnut/nerdguild` repo can log into the CMS.

To add users:

1. Go to https://github.com/mxchestnut/npc/settings/access
2. Click "Add people"
3. Enter their GitHub username
4. Select role: **Write** (allows creating/editing content)
5. Click "Add to repository"

They can now:
1. Visit `nerdchurchpartners.org/admin`
2. Click "Login with GitHub"
3. Authorize the OAuth app
4. Access the CMS and create/edit posts

## 🔄 Updating the Site

After making code changes:

```bash
npm run build
cd deploy
./deploy-to-s3.sh
```

## 🧹 Cleanup (if needed)

To remove all AWS resources and avoid any charges:

```bash
# Delete S3 bucket contents
aws s3 rm s3://nerdguild-blog --recursive

# Delete S3 bucket
aws s3 rb s3://nerdguild-blog

# Delete Lambda function
aws lambda delete-function --function-name nerdguild-oauth-proxy

# Delete CloudFront distribution (if created)
# First disable it, then delete after it's disabled
```

## 🆘 Troubleshooting

**CMS login fails**: 
- Check Lambda function logs: `aws logs tail /aws/lambda/nerdguild-oauth-proxy --follow`
- Verify GitHub OAuth app callback URL matches your site URL
- Ensure user is a collaborator on the GitHub repo

**Content not updating**: 
- Clear browser cache
- CloudFront cache may need invalidation: `aws cloudfront create-invalidation --distribution-id XXX --paths "/*"`

**Build fails**: 
- Check Astro config and dependencies
- Run `npm run build` locally to see detailed errors
