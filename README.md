# FitStart 🏃‍♂️

FitStart is a comprehensive Flutter application that allows users to discover, book, and manage sports venues and gym memberships from anywhere at anytime. The app features AI-powered recommendations, real-time notifications, and seamless booking management.

## ✨ Features

### 🏠 Core Features
- **Venue Discovery**: Browse sports fields and gym facilities with detailed information
- **Smart Search**: Real-time search with optimized performance
- **AI Recommendations**: Machine learning-powered venue suggestions based on user preferences
- **Booking Management**: Complete booking workflow with order tracking
- **Favorites**: Save and manage favorite venues
- **User Profiles**: Customizable user profiles with image upload

### 🔔 Notification System
- **Push Notifications**: Firebase Cloud Messaging (V1 API) integration
- **Notification Inbox**: Persistent notification storage with local caching
- **Badge Indicators**: Visual indicators for unread notifications
- **Campaign Notifications**: Admin panel for sending broadcast messages
- **Multiple States**: Foreground, background, and terminated state handling

### 🤖 AI & ML Integration
- **Gemini AI Chatbot**: Interactive chatbot for venue recommendations and queries
- **ML Recommendations**: Personalized venue suggestions based on user behavior
- **Smart Caching**: Intelligent caching system for improved performance

### 💳 Payment Integration
- **Razorpay**: Secure payment processing for bookings and memberships
- **Transaction History**: Complete transaction tracking and management

### 🎨 User Experience
- **Modern UI**: Clean, intuitive design with smooth animations
- **Dark Mode**: Full dark mode support
- **Responsive Design**: Optimized for various screen sizes
- **Performance Optimized**: State preservation and intelligent caching

## 🛠️ Tech Stack

### Frontend
- **Flutter**: Cross-platform mobile development
- **Provider**: State management
- **Hive**: Local storage for caching

### Backend
- **Supabase**: Backend as a Service (BaaS)
  - Authentication
  - PostgreSQL Database
  - Edge Functions
  - Storage

### Services & APIs
- **Firebase Cloud Messaging**: Push notifications (V1 API)
- **Google Gemini AI**: AI chatbot and recommendations
- **Razorpay**: Payment processing
- **Google Maps**: Location services

### Key Packages
```yaml
firebase_messaging: ^15.2.10
flutter_local_notifications: ^17.2.4
google_generative_ai: ^0.4.3
supabase_flutter: ^2.9.5
razorpay_flutter: ^1.3.7
cached_network_image: ^3.3.1
shared_preferences: ^2.3.0
hive: ^2.2.3
provider: ^6.1.1
```

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (3.0.0 or higher)
- Dart SDK (3.0.0 or higher)
- Android Studio / VS Code
- Firebase account
- Supabase account
- Razorpay account

### Installation

1. **Clone the repository**
```bash
git clone https://github.com/jhaaryan597/FitStart.git
cd FitStart
```

2. **Install dependencies**
```bash
flutter pub get
```

3. **Configure Secrets and API Keys**
   
   ⚠️ **IMPORTANT**: Never commit API keys to git!
   
   See [SECRETS_SETUP.md](SECRETS_SETUP.md) for detailed instructions.
   
   Quick setup:
   - Download `google-services.json` from Firebase Console → place in `android/app/`
   - Generate Gemini AI API key from Google AI Studio
   - Configure Supabase Edge Function secrets (Firebase service account)
   - Set up Razorpay API keys
   
   All sensitive files are already in `.gitignore`.

4. **Configure Supabase**
   - Create a Supabase project
   - Update Supabase credentials in the app
   - Run database migrations from `supabase/migrations/`
   - Deploy edge functions from `supabase/functions/`

5. **Run the app**
```bash
flutter run
```

## 📁 Project Structure

```
lib/
├── main.dart                      # App entry point
├── theme.dart                     # App theming
├── components/                    # Reusable UI components
│   ├── category_card.dart
│   ├── gym_card.dart
│   ├── sport_field_card.dart
│   └── reusable/                  # Generic reusable widgets
├── model/                         # Data models
│   ├── user.dart
│   ├── sport_field.dart
│   ├── gym.dart
│   ├── field_order.dart
│   └── notification_item.dart
├── modules/                       # Feature modules
│   ├── auth/                      # Authentication
│   ├── home/                      # Home screen
│   ├── booking/                   # Booking management
│   ├── notification/              # Notification inbox
│   ├── profile/                   # User profile
│   ├── favorites/                 # Favorites management
│   ├── transaction/               # Transaction history
│   └── gym/                       # Gym features
├── services/                      # Business logic services
│   ├── notification_service.dart  # FCM integration
│   ├── cache_service.dart         # Caching system
│   ├── gemini_chatbot_service.dart # AI chatbot
│   ├── ml_recommendation_service.dart # ML recommendations
│   └── profile_image_service.dart # Image handling
├── utils/                         # Utility functions
│   ├── hive_storage.dart
│   ├── location_service.dart
│   ├── razorpay_service.dart
│   └── theme_manager.dart
└── viewmodels/                    # View models
    └── auth_viewmodel.dart
```

## 🗄️ Database Schema

The app uses Supabase PostgreSQL with the following main tables:
- `profiles`: User profiles and settings
- `fcm_tokens`: Firebase Cloud Messaging tokens
- `favorites`: User's favorite venues
- `orders`: Booking orders
- `ml_user_preferences`: ML recommendation data
- `ml_venue_features`: Venue feature vectors
- `ml_user_interactions`: User interaction tracking

## 🔐 Security

- Service account authentication for Firebase V1 API
- Row Level Security (RLS) policies on Supabase
- Secure token management
- Environment variables for sensitive data

## 📱 Features in Detail

### Notification System
- **Topic-based messaging**: Subscribe to `/topics/all` for broadcasts
- **Local persistence**: Notifications stored in SharedPreferences
- **Swipe to delete**: Intuitive gesture controls
- **Mark as read/unread**: Manage notification status
- **Badge indicators**: Visual cues for new notifications

### Caching System
- **User data caching**: 60-minute expiry
- **ML recommendations**: 30-minute expiry
- **Location caching**: Persistent storage
- **State preservation**: AutomaticKeepAliveClientMixin

### AI Features
- **Contextual chatbot**: Venue recommendations and queries
- **Preference learning**: Adapts to user behavior
- **Personalized suggestions**: ML-based recommendations

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📄 License

This project is licensed under the MIT License.

## 👨‍💻 Author

**Aryan Jha**
- GitHub: [@jhaaryan597](https://github.com/jhaaryan597)
- Email: jhaaryan597@gmail.com

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- Supabase for the backend infrastructure
- Firebase for cloud messaging
- Google for Gemini AI integration
