#!/bin/bash

echo "🚀 Setting up FitStart Backend..."

# Check if MongoDB is running
if ! pgrep -x "mongod" > /dev/null; then
    echo "⚠️  MongoDB is not running!"
    echo "Starting MongoDB..."
    
    # Try to start MongoDB (macOS with Homebrew)
    if command -v brew &> /dev/null; then
        brew services start mongodb-community
    else
        echo "❌ Please start MongoDB manually"
        echo "   - macOS: brew services start mongodb-community"
        echo "   - Linux: sudo systemctl start mongod"
        echo "   - Docker: docker run -d -p 27017:27017 mongo"
        exit 1
    fi
fi

# Check if .env file exists
if [ ! -f .env ]; then
    echo "📝 Creating .env file..."
    cp .env.example .env
    echo "✅ .env file created. Please update it with your credentials."
    echo ""
    echo "Required environment variables:"
    echo "  - MONGODB_URI"
    echo "  - JWT_SECRET"
    echo "  - FIREBASE credentials"
    echo "  - RAZORPAY credentials"
    echo ""
    exit 1
fi

echo "✅ MongoDB is running"
echo "✅ Environment file exists"
echo ""
echo "🎯 Starting development server..."
npm run dev
