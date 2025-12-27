# FitStart Backend API

Complete Node.js + Express + MongoDB backend for the FitStart sports venue booking platform.

## 🚀 Features

- ✅ **User Authentication** - JWT-based auth with bcrypt password hashing
- ✅ **Venue Management** - CRUD operations for sports venues
- ✅ **Booking System** - Complete booking flow with conflict checking
- ✅ **Payment Integration** - Razorpay payment gateway integration
- ✅ **Firebase Notifications** - Push notifications via FCM
- ✅ **Geospatial Queries** - Location-based venue search
- ✅ **ML Interaction Tracking** - Track user interactions for recommendations
- ✅ **Favorites** - Save and manage favorite venues
- ✅ **Reviews & Ratings** - User reviews and ratings system
- ✅ **Gym Memberships** - Gym membership management
- ✅ **Security** - Helmet, CORS, rate limiting, input validation

## 📁 Project Structure

```
backend/
├── src/
│   ├── config/
│   │   ├── database.js       # MongoDB connection
│   │   └── firebase.js       # Firebase Admin SDK
│   ├── controllers/
│   │   ├── authController.js
│   │   ├── venueController.js
│   │   └── bookingController.js
│   ├── middleware/
│   │   ├── auth.js           # JWT verification
│   │   ├── error.js          # Error handling
│   │   └── validate.js       # Input validation
│   ├── models/
│   │   ├── User.js
│   │   ├── Venue.js
│   │   ├── Booking.js
│   │   ├── Gym.js
│   │   ├── Review.js
│   │   └── Notification.js
│   ├── routes/
│   │   ├── authRoutes.js
│   │   ├── venueRoutes.js
│   │   └── bookingRoutes.js
│   └── server.js             # Main server file
├── .env.example
├── .gitignore
└── package.json
```

## 🛠️ Setup Instructions

### 1. Install Dependencies

```bash
cd backend
npm install
```

### 2. Environment Configuration

Create a `.env` file in the backend directory:

```bash
cp .env.example .env
```

Edit `.env` and add your credentials:

```env
# MongoDB
MONGODB_URI=mongodb://localhost:27017/fitstart

# JWT
JWT_SECRET=your_super_secret_jwt_key
JWT_EXPIRE=7d

# Firebase Admin SDK
FIREBASE_PROJECT_ID=your-firebase-project-id
FIREBASE_PRIVATE_KEY=-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----
FIREBASE_CLIENT_EMAIL=firebase-adminsdk@your-project.iam.gserviceaccount.com

# Razorpay
RAZORPAY_KEY_ID=your_razorpay_key_id
RAZORPAY_KEY_SECRET=your_razorpay_key_secret
```

### 3. Start MongoDB

Make sure MongoDB is running:

```bash
# macOS (if installed via Homebrew)
brew services start mongodb-community

# Or use Docker
docker run -d -p 27017:27017 --name mongodb mongo:latest
```

### 4. Run the Server

```bash
# Development mode with auto-reload
npm run dev

# Production mode
npm start
```

Server will start on `http://localhost:5000`

## 📡 API Endpoints

### Authentication

```
POST   /api/v1/auth/register        - Register new user
POST   /api/v1/auth/login           - Login user
GET    /api/v1/auth/me              - Get current user
PUT    /api/v1/auth/update          - Update user details
PUT    /api/v1/auth/updatepassword  - Update password
POST   /api/v1/auth/fcm-token       - Register FCM token
DELETE /api/v1/auth/fcm-token       - Remove FCM token
```

### Venues

```
GET    /api/v1/venues                    - Get all venues (with filters)
POST   /api/v1/venues                    - Create venue (Admin/Owner)
GET    /api/v1/venues/favorites          - Get user favorites
GET    /api/v1/venues/nearby             - Get nearby venues
GET    /api/v1/venues/:id                - Get single venue
PUT    /api/v1/venues/:id                - Update venue
DELETE /api/v1/venues/:id                - Delete venue
POST   /api/v1/venues/:id/favorite       - Toggle favorite
```

### Bookings

```
GET    /api/v1/bookings                     - Get user bookings
POST   /api/v1/bookings                     - Create booking
GET    /api/v1/bookings/available-slots/:id - Get available time slots
GET    /api/v1/bookings/:id                 - Get single booking
POST   /api/v1/bookings/:id/verify-payment  - Verify Razorpay payment
PUT    /api/v1/bookings/:id/cancel          - Cancel booking
```

## 🔐 Authentication

All protected routes require a JWT token in the Authorization header:

```
Authorization: Bearer <your_jwt_token>
```

## 🗄️ Database Models

- **User** - User accounts with authentication
- **Venue** - Sports venues/fields
- **Booking** - Venue bookings
- **Gym** - Gym facilities
- **GymMembership** - Gym memberships
- **Review** - User reviews and ratings
- **Notification** - Push notifications
- **MLInteraction** - User interaction tracking for ML

## 🔔 Firebase Cloud Messaging

The backend automatically sends push notifications for:
- Booking confirmations
- Payment success
- Booking cancellations
- Membership updates

## 💳 Payment Flow

1. Client creates booking → Server generates Razorpay order
2. Client completes payment on Razorpay
3. Client sends payment details to verify endpoint
4. Server verifies signature and confirms booking
5. Notification sent to user

## 🧪 Testing

```bash
npm test
```

## 📦 Deployment

### Using PM2

```bash
npm install -g pm2
pm2 start src/server.js --name fitstart-api
pm2 save
pm2 startup
```

### Using Docker

```bash
docker build -t fitstart-api .
docker run -p 5000:5000 --env-file .env fitstart-api
```

## 🛡️ Security Features

- Password hashing with bcrypt
- JWT token-based authentication
- Input validation with express-validator
- Rate limiting to prevent abuse
- Helmet.js for security headers
- CORS configuration
- MongoDB injection prevention

## 📝 License

MIT

## 👨‍💻 Author

jhaaryan597
