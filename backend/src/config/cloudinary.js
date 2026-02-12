const cloudinary = require('cloudinary').v2;

// Configure Cloudinary
cloudinary.config({
  cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
  api_key: process.env.CLOUDINARY_API_KEY,
  api_secret: process.env.CLOUDINARY_API_SECRET,
});

// Check if Cloudinary is configured
const isConfigured = () => {
  return process.env.CLOUDINARY_CLOUD_NAME &&
         process.env.CLOUDINARY_API_KEY &&
         process.env.CLOUDINARY_API_SECRET &&
         process.env.CLOUDINARY_CLOUD_NAME !== 'your-cloudinary-cloud-name';
};

// Upload image to Cloudinary
const uploadImage = async (filePath, folder = 'fitstart/profiles') => {
  try {
    if (!isConfigured()) {
      throw new Error('Cloudinary not configured');
    }

    const result = await cloudinary.uploader.upload(filePath, {
      folder,
      resource_type: 'image',
      transformation: [
        { width: 500, height: 500, crop: 'fill' }, // Resize to 500x500
        { quality: 'auto' } // Auto quality optimization
      ]
    });

    return {
      url: result.secure_url,
      publicId: result.public_id,
    };
  } catch (error) {
    console.error('Cloudinary upload error:', error);
    throw error;
  }
};

// Delete image from Cloudinary
const deleteImage = async (publicId) => {
  try {
    if (!isConfigured()) {
      console.log('Cloudinary not configured - skipping delete');
      return;
    }

    await cloudinary.uploader.destroy(publicId);
  } catch (error) {
    console.error('Cloudinary delete error:', error);
    // Don't throw error for delete failures
  }
};

module.exports = {
  cloudinary,
  uploadImage,
  deleteImage,
  isConfigured,
};