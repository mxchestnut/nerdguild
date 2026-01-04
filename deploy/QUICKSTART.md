# Quick Start: Deploy Nerd Guild Blog to AWS

## 🎯 Goal
Get your blog live on AWS with GitHub OAuth so you and your team can log in and post.

## 📝 Step-by-Step

### 1️⃣ Create GitHub OAuth App (5 minutes)

1. Visit: https://github.com/settings/developers
2. Click **"New OAuth App"**
3. Fill in:
   ```
   Application name: Nerd Guild CMS
   Homepage URL: https://nerdchurchpartners.org
   Callback URL: https://nerdchurchpartners.org/admin
   ```
4. Click **"Register application"**
5. Copy the **Client ID**
6. Click **"Generate a new client secret"** and copy it

### 2️⃣ Export OAuth Credentials

In your terminal:

```bash
export GITHUB_CLIENT_ID="paste_your_client_id_here"
export GITHUB_CLIENT_SECRET="paste_your_secret_here"
```

### 3️⃣ Run AWS Setup (5 minutes)

```bash
cd /Users/kit/Downloads/primapersona_2026/deploy
chmod +x *.sh
./create-lambda-role.sh
./aws-setup.sh
```

**Important**: The script will output a Lambda URL like:
```
OAuth endpoint created: https://abc123xyz.lambda-url.us-east-1.on.aws/
```

**Copy this URL!**

### 4️⃣ Update CMS Config

Open `src/pages/admin.astro` and replace:

```javascript
base_url: 'https://YOUR_LAMBDA_URL.lambda-url.us-east-1.on.aws',
```

With your actual Lambda URL (from step 3).

### 5️⃣ Build and Deploy

```bash
cd /Users/kit/Downloads/primapersona_2026
npm run build
cd deploy
./deploy-to-s3.sh
```

Your site is now live! The script will show you the URL.

### 6️⃣ Add Team Members to CMS

Only GitHub repo collaborators can log into the CMS.

1. Go to: https://github.com/mxchestnut/npc/settings/access
2. Click **"Add people"**
3. Enter their GitHub username
4. Give them **Write** access
5. Click **"Add to repository"**

They can now:
- Visit `nerdchurchpartners.org/admin`
- Click "Login with GitHub"
- Create and publish blog posts!

## 🔄 How to Update the Site

After making code changes:

```bash
npm run build
cd deploy
./deploy-to-s3.sh
```

## 💡 Next Steps

- Optional: Run `./create-cloudfront.sh` for HTTPS and faster global access
- Set up your Discord bot to share new posts automatically!

## 💰 Costs

With AWS free tier, this should cost **under $1/month** for moderate traffic:
- S3: ~$0.02/month
- Lambda: Free (1M requests/month)
- CloudFront: Free tier covers most small sites

---

Need help? Check the full guide: `deploy/README.md`
