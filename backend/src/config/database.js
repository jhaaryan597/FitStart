const mongoose = require('mongoose');

const MAX_RETRIES = 5;
const RETRY_DELAY_MS = 5000;

const getMongoUri = () => {
  const uri =
    process.env.MONGODB_URI ||
    process.env.MONGO_URI ||
    process.env.DATABASE_URL ||
    process.env.MONGO_URL;

  if (typeof uri !== 'string' || !uri.trim()) {
    return null;
  }

  return uri.trim();
};

const connectDB = async (retryCount = 0) => {
  try {
    const mongoUri = getMongoUri();

    if (!mongoUri) {
      throw new Error(
        'MongoDB URI is missing. Set one of: MONGODB_URI, MONGO_URI, DATABASE_URL, or MONGO_URL'
      );
    }

    const conn = await mongoose.connect(mongoUri, {
      // Modern mongoose options
      serverSelectionTimeoutMS: 5000,
      socketTimeoutMS: 45000,
    });

    console.log(`✅ MongoDB Connected: ${conn.connection.host}`);
    
    // Handle connection events
    mongoose.connection.on('error', (err) => {
      console.error(`❌ MongoDB connection error: ${err}`);
    });

    mongoose.connection.on('disconnected', () => {
      console.log('⚠️  MongoDB disconnected. Attempting to reconnect...');
      // Attempt to reconnect
      setTimeout(() => connectDB(0), RETRY_DELAY_MS);
    });

    // Graceful shutdown
    process.on('SIGINT', async () => {
      await mongoose.connection.close();
      console.log('MongoDB connection closed due to app termination');
      process.exit(0);
    });

  } catch (error) {
    console.error(`❌ Error connecting to MongoDB: ${error.message}`);
    
    if (retryCount < MAX_RETRIES) {
      console.log(`🔄 Retrying connection (${retryCount + 1}/${MAX_RETRIES}) in ${RETRY_DELAY_MS / 1000}s...`);
      await new Promise(resolve => setTimeout(resolve, RETRY_DELAY_MS));
      return connectDB(retryCount + 1);
    }
    
    console.error(`❌ Max retries (${MAX_RETRIES}) reached. Exiting...`);
    process.exit(1);
  }
};

module.exports = connectDB;
