# Secret Configuration Guide

This document explains how to set up the required API keys and secrets for the FitStart application.

## ⚠️ IMPORTANT: Never Commit Secrets to Git!

The following files contain sensitive API keys and should NEVER be committed to version control:
- `android/app/google-services.json`
- `test_gemini_models.dart`
- `test_gemini.dart`
- `test_api_direct.dart`
- `.env`

These files are already added to `.gitignore` to prevent accidental commits.

## 🔑 Required API Keys

### 1. Firebase Configuration

**File:** `android/app/google-services.json`

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project or create a new one
3. Go to **Project Settings** → **General**
4. Scroll down to "Your apps" section
5. Download `google-services.json`
6. Place it in `android/app/` directory

**Template available at:** `android/app/google-services.json.template`

### 2. Gemini AI API Key

**Used in:** Test files and chatbot service

1. Go to [Google AI Studio](https://makersuite.google.com/app/apikey)
2. Create a new API key or use existing one
3. Add the key to your test files or environment configuration

### 3. Supabase Secrets (Server-side)

For the notification system to work, configure these secrets in your Supabase project:

1. Go to [Supabase Dashboard](https://supabase.com/dashboard)
2. Navigate to **Project Settings** → **Edge Functions** → **Secrets**
3. Add the following secrets:

```
FIREBASE_PROJECT_ID=your-firebase-project-id
FIREBASE_CLIENT_EMAIL=your-service-account-email
FIREBASE_PRIVATE_KEY=your-service-account-private-key
```

Get these values from your Firebase service account JSON file:
- Firebase Console → Project Settings → Service Accounts → Generate New Private Key

### 4. Razorpay API Keys

**File:** `lib/utils/razorpay_service.dart`

1. Go to [Razorpay Dashboard](https://dashboard.razorpay.com/)
2. Navigate to **Settings** → **API Keys**
3. Generate Test/Live keys
4. Update the keys in `razorpay_service.dart`

## 🛡️ Security Best Practices

1. **Never commit** API keys, tokens, or credentials to version control
2. **Rotate keys** immediately if they are accidentally exposed
3. **Use environment variables** for sensitive data in production
4. **Restrict API key usage** by setting up application restrictions in respective consoles
5. **Monitor API usage** regularly for any suspicious activity

## 📝 Setup Checklist

- [ ] Download and place `google-services.json` in `android/app/`
- [ ] Generate Gemini AI API key
- [ ] Configure Supabase Edge Function secrets
- [ ] Set up Razorpay API keys
- [ ] Verify all keys are working by running the app
- [ ] Confirm sensitive files are listed in `.gitignore`

## 🆘 If Keys Are Exposed

If you accidentally commit secrets to git:

1. **Immediately rotate/regenerate** all exposed keys
2. **Remove from git history** using git filter-branch
3. **Force push** to remote repository
4. **Notify your team** about the exposure
5. **Monitor** for any unauthorized usage

## 📧 Support

If you need help setting up the secrets, refer to the main README.md or contact the development team.
