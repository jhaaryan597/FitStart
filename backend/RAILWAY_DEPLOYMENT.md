# 🚀 Deploy FitStart Backend to Railway

This guide will help you deploy your FitStart backend to Railway for free, giving you a permanent URL that works on all devices.

## Prerequisites

1. GitHub account
2. Railway account (free - sign up at https://railway.app)
3. MongoDB Atlas account (free - sign up at https://mongodb.com/cloud/atlas)

## Step 1: Set Up MongoDB Atlas (5 minutes)

Since Railway doesn't provide free MongoDB, we'll use MongoDB Atlas (free forever tier):

1. Go to https://www.mongodb.com/cloud/atlas/register
2. Sign up for free account
3. Create a **FREE** M0 cluster:
   - Choose **AWS** as provider
   - Choose closest region to your users
   - Cluster name: `FitStart`
4. Create database user:
   - Click "Database Access" → "Add New Database User"
   - Username: `fitstart`
   - Password: Generate a strong password (save it!)
   - User Privileges: "Read and write to any database"
5. Whitelist all IPs (for Railway):
   - Click "Network Access" → "Add IP Address"
   - Click "Allow Access from Anywhere"
   - IP: `0.0.0.0/0`
   - Click "Confirm"
6. Get connection string:
   - Click "Database" → "Connect" → "Connect your application"
   - Copy the connection string (looks like: `mongodb+srv://fitstart:<password>@cluster0.xxxxx.mongodb.net/?retryWrites=true&w=majority`)
   - Replace `<password>` with your actual password
   - Add database name: `mongodb+srv://fitstart:YOUR_PASSWORD@cluster0.xxxxx.mongodb.net/fitstart?retryWrites=true&w=majority`

**Save this connection string - you'll need it for Railway!**

## Step 2: Push Code to GitHub

Your backend code needs to be on GitHub for Railway to deploy it.

1. Go to https://github.com/new
2. Create a new repository:
   - Name: `fitstart-backend`
   - Visibility: Private (recommended)
   - Don't initialize with README (we already have code)
3. Push your backend code:

```bash
cd /Users/aryanjha/Desktop/FitStart/backend
git init
git add .
git commit -m "Initial commit - FitStart backend"
git branch -M main
git remote add origin https://github.com/YOUR_USERNAME/fitstart-backend.git
git push -u origin main
```

Replace `YOUR_USERNAME` with your GitHub username.

## Step 3: Deploy to Railway (3 minutes)

1. Go to https://railway.app
2. Click "Start a New Project"
3. Click "Deploy from GitHub repo"
4. Authorize Railway to access your GitHub
5. Select your `fitstart-backend` repository
6. Railway will automatically detect it's a Node.js app and start deploying

## Step 4: Configure Environment Variables

After deployment starts, you need to set environment variables:

1. In Railway dashboard, click on your service
2. Go to "Variables" tab
3. Click "RAW Editor" button
4. Paste the following (replace with your actual values):

```env
NODE_ENV=production
PORT=5000
API_VERSION=v1
MONGODB_URI=mongodb+srv://fitstart:YOUR_PASSWORD@cluster0.xxxxx.mongodb.net/fitstart?retryWrites=true&w=majority
JWT_SECRET=super_secret_jwt_key_CHANGE_THIS_TO_RANDOM_STRING
JWT_EXPIRE=7d
JWT_REFRESH_SECRET=super_secret_refresh_jwt_CHANGE_THIS_TO_RANDOM_STRING
JWT_REFRESH_EXPIRE=30d
GOOGLE_CLIENT_ID=112923590570-9mtmf3mj0jj0nitt3n2v1hcian1jb458.apps.googleusercontent.com
FRONTEND_URL=*
RATE_LIMIT_WINDOW_MS=900000
RATE_LIMIT_MAX_REQUESTS=100
```

5. Click "Update Variables"
6. Railway will automatically redeploy with new variables

**Important:** Generate strong random strings for JWT_SECRET and JWT_REFRESH_SECRET. You can use:
```bash
node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"
```

## Step 5: Get Your Railway URL

1. In Railway dashboard, go to "Settings" tab
2. Scroll to "Networking" section
3. Click "Generate Domain"
4. Railway will give you a URL like: `fitstart-backend-production.up.railway.app`
5. **Copy this URL** - you'll update your Flutter app with it!

Your API will be available at:
```
https://fitstart-backend-production.up.railway.app/api/v1
```

Test it:
```
https://fitstart-backend-production.up.railway.app/health
```

You should see: `{"success":true,"message":"FitStart API is running"}`

## Step 6: Update Flutter App

Open `/Users/aryanjha/Desktop/FitStart/lib/services/api_service.dart` and update:

```dart
static const String _baseUrlProd = 'https://YOUR-RAILWAY-APP.up.railway.app/api/v1';
```

Also update `/Users/aryanjha/Desktop/FitStart/lib/features/auth/data/datasources/auth_remote_data_source.dart`:

Add the production URL constant and update the baseUrl getter to use it.

## Step 7: Test Your Deployment

1. Check Railway logs:
   - In Railway dashboard → "Deployments" tab
   - Click latest deployment
   - Check logs for any errors

2. Test endpoints:
   ```bash
   # Health check
   curl https://YOUR-RAILWAY-APP.up.railway.app/health

   # Test Google Sign-In endpoint (should return error since token is invalid)
   curl -X POST https://YOUR-RAILWAY-APP.up.railway.app/api/v1/auth/google \
     -H "Content-Type: application/json" \
     -d '{"idToken":"test"}'
   ```

3. Rebuild your Flutter app:
   ```bash
   cd /Users/aryanjha/Desktop/FitStart
   flutter clean
   flutter pub get
   flutter run
   ```

## 🎉 Done! Your backend is now:

✅ Running 24/7 on Railway
✅ Accessible from anywhere with permanent URL
✅ Auto-deploys when you push to GitHub
✅ Free (within Railway's generous free tier)
✅ Backed by MongoDB Atlas free tier

## Railway Free Tier Limits

- **$5 free credits per month** (enough for small apps)
- **500 hours of usage per month**
- If you exceed limits, Railway will notify you

## Troubleshooting

### Deployment fails
- Check Railway logs for errors
- Ensure all environment variables are set correctly
- Verify MongoDB connection string is correct

### Can't connect from Flutter app
- Make sure you updated the Flutter app with correct Railway URL
- Rebuild Flutter app completely (flutter clean)
- Check CORS settings in backend (FRONTEND_URL=*)

### MongoDB connection error
- Double-check MongoDB Atlas connection string
- Ensure password doesn't have special characters (or URL encode them)
- Verify IP whitelist includes 0.0.0.0/0

## Auto-Deployment

Every time you push to GitHub, Railway automatically deploys:

```bash
git add .
git commit -m "Update API"
git push
```

Railway will detect changes and redeploy automatically!

## Monitoring

Check your app's health in Railway dashboard:
- CPU/Memory usage
- Deployment logs
- Error tracking
- Request metrics

---

**Need help?** Check Railway docs: https://docs.railway.app
