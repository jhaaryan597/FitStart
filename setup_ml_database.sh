#!/bin/bash

# ================================
# FitStart ML Database Setup Script
# ================================
# This script helps you set up the ML database tables in Supabase
# Run this ONCE after integrating the ML system

echo "🚀 FitStart ML Database Setup"
echo "=============================="
echo ""

# Check if supabase is installed
if ! command -v supabase &> /dev/null; then
    echo "❌ Supabase CLI not found!"
    echo ""
    echo "Please install Supabase CLI first:"
    echo "  npm install -g supabase"
    echo ""
    echo "Or use manual method (see below)"
    exit 1
fi

echo "✅ Supabase CLI found"
echo ""

# Check if in correct directory
if [ ! -f "pubspec.yaml" ]; then
    echo "❌ Error: Not in FitStart project directory"
    echo "Please run this script from: /Users/aryanjha/Desktop/FitStart"
    exit 1
fi

echo "✅ In FitStart project directory"
echo ""

# Check if migration file exists
if [ ! -f "supabase/migrations/create_ml_tables.sql" ]; then
    echo "❌ Error: Migration file not found"
    echo "Expected: supabase/migrations/create_ml_tables.sql"
    exit 1
fi

echo "✅ ML migration file found"
echo ""

echo "📋 This will create the following in your Supabase database:"
echo "   - user_interactions table (tracks user behavior)"
echo "   - user_venue_features view (ML feature aggregation)"
echo "   - get_similar_users() function (collaborative filtering)"
echo "   - get_collaborative_recommendations() function (ML recommendations)"
echo ""

read -p "Continue? (y/n) " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Cancelled."
    exit 0
fi

echo ""
echo "🔄 Applying database migration..."
echo ""

# Try to push migration
supabase db push

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ SUCCESS! ML database tables created."
    echo ""
    echo "🎉 What's working now:"
    echo "   ✓ Home screen shows ML recommendations"
    echo "   ✓ Venue views are tracked"
    echo "   ✓ Favorites are tracked"
    echo "   ✓ Bookings are tracked"
    echo "   ✓ ML learns from user behavior"
    echo ""
    echo "🚀 Next steps:"
    echo "   1. Run: flutter run"
    echo "   2. Login to your app"
    echo "   3. View and favorite some venues"
    echo "   4. Watch recommendations personalize!"
    echo ""
else
    echo ""
    echo "❌ Migration failed!"
    echo ""
    echo "📝 Manual setup method:"
    echo "   1. Go to: https://supabase.com/dashboard"
    echo "   2. Select your project"
    echo "   3. Go to 'SQL Editor'"
    echo "   4. Click 'New query'"
    echo "   5. Copy contents of: supabase/migrations/create_ml_tables.sql"
    echo "   6. Paste into SQL Editor"
    echo "   7. Click 'Run'"
    echo ""
fi

echo "📚 Documentation:"
echo "   - ML_IMPLEMENTATION.md - Technical details"
echo "   - ML_INTEGRATION_GUIDE.md - Setup & demo guide"
echo ""
