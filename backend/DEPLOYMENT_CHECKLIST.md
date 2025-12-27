# ✅ Railway Deployment Checklist

Use this checklist to ensure you complete all steps correctly.

## Pre-Deployment

- [ ] Read `RAILWAY_QUICK_START.md` in project root
- [ ] Have GitHub account ready
- [ ] Have Railway account ready
- [ ] Have MongoDB Atlas account ready

## MongoDB Atlas Setup

- [ ] Created free M0 cluster
- [ ] Created database user (username: `fitstart`)
- [ ] Saved password securely
- [ ] Added network access: `0.0.0.0/0`
- [ ] Got connection string
- [ ] Replaced `<password>` in connection string
- [ ] Added `/fitstart` database name to connection string
- [ ] **Final string format:** `mongodb+srv://fitstart:PASSWORD@cluster0.xxxxx.mongodb.net/fitstart?retryWrites=true&w=majority`

## GitHub Setup

- [ ] Created new GitHub repository (`fitstart-backend`)
- [ ] Set visibility to Private (recommended)
- [ ] Initialized git in `/Users/aryanjha/Desktop/FitStart/backend`
- [ ] Committed all files
- [ ] Pushed to GitHub successfully
- [ ] Verified files are on GitHub

## Railway Deployment

- [ ] Signed up/logged in to Railway
- [ ] Created new project from GitHub repo
- [ ] Selected `fitstart-backend` repository
- [ ] Deployment started automatically
- [ ] No errors in initial deployment logs

## Environment Variables

- [ ] Opened Variables tab in Railway
- [ ] Clicked "RAW Editor"
- [ ] Set `MONGODB_URI` with actual MongoDB Atlas connection string
- [ ] Generated random string for `JWT_SECRET` (32+ characters)
- [ ] Generated random string for `JWT_REFRESH_SECRET` (32+ characters)
- [ ] Set `GOOGLE_CLIENT_ID` (already in .env file)
- [ ] Set `NODE_ENV=production`
- [ ] Set `FRONTEND_URL=*`
- [ ] Clicked "Update Variables"
- [ ] Service redeployed automatically
- [ ] Check logs for "MongoDB Connected" message

## Domain Setup

- [ ] Went to Settings → Networking
- [ ] Clicked "Generate Domain"
- [ ] Copied Railway URL (e.g., `fitstart-backend-production.up.railway.app`)
- [ ] Tested health endpoint: `https://YOUR-URL/health`
- [ ] Health check returns success

## Flutter App Update

- [ ] Opened `lib/services/api_service.dart`
- [ ] Updated `_baseUrlProd` with Railway URL + `/api/v1`
- [ ] Opened `lib/features/auth/data/datasources/auth_remote_data_source.dart`
- [ ] Updated `_baseUrlProd` with Railway URL + `/api/v1`
- [ ] Saved both files
- [ ] Verified URLs match exactly

## Testing

- [ ] Ran `flutter clean`
- [ ] Ran `flutter pub get`
- [ ] Built and ran app on device
- [ ] Tested Google Sign-In
- [ ] Sign-in works successfully
- [ ] User data is saved
- [ ] No timeout errors

## Verification

- [ ] Checked Railway logs for incoming requests
- [ ] Checked MongoDB Atlas for new user document
- [ ] App works on WiFi
- [ ] App works on mobile data
- [ ] App works from different locations

## Post-Deployment

- [ ] Documented Railway URL in safe place
- [ ] Saved MongoDB connection string securely
- [ ] Saved JWT secrets securely
- [ ] Set up Railway billing alerts (optional)
- [ ] Starred your GitHub repo

## Future Maintenance

- [ ] Know how to check Railway logs
- [ ] Know how to update environment variables
- [ ] Understand auto-deploy process (push to GitHub)
- [ ] Know how to check Railway usage/credits

---

## 🎉 All Done!

Your FitStart backend is now deployed and running 24/7!

**Railway URL:** `https://________________.up.railway.app`

**Status:** ✅ Production Ready

---

## Common Issues

### MongoDB Connection Error
- ✓ Check connection string format
- ✓ Verify password doesn't have special characters
- ✓ Ensure IP whitelist includes `0.0.0.0/0`

### Google Sign-In Not Working
- ✓ Verify `GOOGLE_CLIENT_ID` in Railway matches Google Console
- ✓ Check Flutter app has correct Railway URL
- ✓ Ensure you rebuilt app after URL change

### Can't Access from App
- ✓ Verify Railway domain is generated
- ✓ Check app has been rebuilt (not just hot reload)
- ✓ Test health endpoint in browser first

### Deployment Failed
- ✓ Check Railway logs for specific error
- ✓ Verify all environment variables are set
- ✓ Ensure package.json has correct start script

---

**Need Help?** Check the detailed guide: `RAILWAY_DEPLOYMENT.md`
