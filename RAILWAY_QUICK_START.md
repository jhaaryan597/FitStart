# 🚀 Quick Start: Deploy FitStart Backend to Railway

Your FitStart backend is now ready for Railway deployment! Follow these simple steps to get a permanent URL that works on all devices.

## ⏱️ Total Time: ~15 minutes

## 📋 What You'll Need

1. **GitHub Account** - [Sign up free](https://github.com/join)
2. **Railway Account** - [Sign up free](https://railway.app)
3. **MongoDB Atlas Account** - [Sign up free](https://mongodb.com/cloud/atlas)

---

## Step 1: MongoDB Atlas Setup (5 min)

1. Go to https://www.mongodb.com/cloud/atlas/register
2. Sign up and create a **FREE M0 cluster**
3. Create database user:
   - Username: `fitstart`
   - Password: (generate strong password and save it!)
4. Network Access: Allow from anywhere (`0.0.0.0/0`)
5. Get connection string:
   ```
   mongodb+srv://fitstart:YOUR_PASSWORD@cluster0.xxxxx.mongodb.net/fitstart?retryWrites=true&w=majority
   ```
   **Save this - you'll need it!**

## Step 2: Push to GitHub (2 min)

```bash
cd /Users/aryanjha/Desktop/FitStart/backend

# Initialize git (if not already done)
git init
git add .
git commit -m "Ready for Railway deployment"

# Create GitHub repo and push
git remote add origin https://github.com/YOUR_USERNAME/fitstart-backend.git
git branch -M main
git push -u origin main
```

## Step 3: Deploy to Railway (3 min)

1. Go to https://railway.app
2. Click "Start a New Project"
3. Choose "Deploy from GitHub repo"
4. Select your `fitstart-backend` repository
5. Railway starts deploying automatically ⚡

## Step 4: Set Environment Variables (3 min)

In Railway dashboard:
1. Click your service → "Variables" tab
2. Click "RAW Editor"
3. Paste this (replace with YOUR values):

```env
NODE_ENV=production
PORT=5000
API_VERSION=v1
MONGODB_URI=mongodb+srv://fitstart:YOUR_PASSWORD@cluster0.xxxxx.mongodb.net/fitstart?retryWrites=true&w=majority
JWT_SECRET=GENERATE_RANDOM_STRING_HERE
JWT_EXPIRE=7d
JWT_REFRESH_SECRET=GENERATE_ANOTHER_RANDOM_STRING
JWT_REFRESH_EXPIRE=30d
GOOGLE_CLIENT_ID=112923590570-9mtmf3mj0jj0nitt3n2v1hcian1jb458.apps.googleusercontent.com
FRONTEND_URL=*
RATE_LIMIT_WINDOW_MS=900000
RATE_LIMIT_MAX_REQUESTS=100
```

**Generate random secrets with:**
```bash
node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"
```

4. Click "Update Variables"

## Step 5: Get Your URL (1 min)

1. Railway dashboard → "Settings" → "Networking"
2. Click "Generate Domain"
3. Copy your URL: `https://fitstart-backend-production.up.railway.app`
4. Test it: `https://YOUR-URL/health` (should show "FitStart API is running")

## Step 6: Update Flutter App (1 min)

Open **TWO files** and update the production URL:

### File 1: `lib/services/api_service.dart`
```dart
static const String _baseUrlProd = 'https://YOUR-RAILWAY-URL.up.railway.app/api/v1';
```

### File 2: `lib/features/auth/data/datasources/auth_remote_data_source.dart`
```dart
static const String _baseUrlProd = 'https://YOUR-RAILWAY-URL.up.railway.app/api/v1';
```

Replace `YOUR-RAILWAY-URL` with your actual Railway URL!

## Step 7: Rebuild & Test

```bash
cd /Users/aryanjha/Desktop/FitStart
flutter clean
flutter pub get
flutter run
```

## ✅ Done!

Your backend is now:
- 🌍 Live at a permanent URL
- 📱 Works on ALL devices (no more IP changes!)
- 🔄 Auto-deploys when you push to GitHub
- 💰 FREE (within Railway's generous limits)
- 🚀 Running 24/7 (no need to start manually)

## 🎯 Test Google Sign-In

1. Open your Flutter app
2. Click "Sign in with Google"
3. Should now work from ANY device, ANYWHERE!

## 📊 Monitor Your App

Railway Dashboard shows:
- Live logs
- CPU/Memory usage
- Request metrics
- Deployment history

## 🔄 Future Updates

Just push to GitHub:
```bash
git add .
git commit -m "Update backend"
git push
```

Railway automatically deploys! 🎉

---

## 💡 Need More Help?

Full detailed guide: `/Users/aryanjha/Desktop/FitStart/backend/RAILWAY_DEPLOYMENT.md`

Railway Docs: https://docs.railway.app

---

**Happy Coding! 🚀**
