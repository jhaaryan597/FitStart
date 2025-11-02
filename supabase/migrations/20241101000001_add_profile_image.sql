-- Add profile_image column to profiles table
-- Run this in your Supabase SQL Editor

-- Add the column if it doesn't exist
ALTER TABLE profiles 
ADD COLUMN IF NOT EXISTS profile_image TEXT;

-- Add index for faster lookups
CREATE INDEX IF NOT EXISTS idx_profiles_profile_image 
ON profiles(profile_image);

-- Add comment for documentation
COMMENT ON COLUMN profiles.profile_image IS 'URL or asset path to user profile image';
