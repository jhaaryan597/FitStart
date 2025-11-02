#!/bin/bash

# Deploy notification edge function to Supabase

echo "🚀 Deploying send-campaign-notification function to Supabase..."

# Deploy the function
supabase functions deploy send-campaign-notification --no-verify-jwt

echo ""
echo "✅ Function deployed successfully!"
echo ""
echo "📝 Next Steps:"
echo "1. Set your Firebase Server Key as a secret:"
echo "   supabase secrets set FIREBASE_SERVER_KEY=your_firebase_server_key_here"
echo ""
echo "2. Get your Server Key from:"
echo "   Firebase Console → Project Settings → Cloud Messaging → Server Key"
echo ""
echo "3. Test the function from your Flutter app or using curl:"
echo "   curl -X POST https://your-project.supabase.co/functions/v1/send-campaign-notification \\"
echo "     -H 'Content-Type: application/json' \\"
echo "     -d '{\"title\":\"Test\",\"body\":\"Hello World\",\"target_type\":\"all\"}'"
echo ""
