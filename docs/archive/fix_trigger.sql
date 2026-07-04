-- ============================================
-- FIXED TRIGGER WITH BETTER ERROR HANDLING
-- ============================================
-- Run this if you're getting registration errors
-- ============================================

-- Drop existing trigger and function
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP FUNCTION IF EXISTS public.handle_new_user();

-- Create improved trigger function with error handling
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
  INSERT INTO public.profiles (id, email, username, full_name)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'username', 'user_' || substr(NEW.id::text, 1, 8)),
    COALESCE(NEW.raw_user_meta_data->>'full_name', '')
  )
  ON CONFLICT (id) DO NOTHING; -- Don't fail if profile already exists
  RETURN NEW;
EXCEPTION
  WHEN unique_violation THEN
    -- Username already exists, generate a new one
    INSERT INTO public.profiles (id, email, username, full_name)
    VALUES (
      NEW.id,
      NEW.email,
      'user_' || substr(NEW.id::text, 1, 8) || '_' || floor(random() * 1000)::text,
      COALESCE(NEW.raw_user_meta_data->>'full_name', '')
    )
    ON CONFLICT (id) DO NOTHING;
    RETURN NEW;
  WHEN OTHERS THEN
    -- Log error but don't fail user creation
    -- User can create profile manually later if needed
    RAISE WARNING 'Error creating profile for user %: %', NEW.id, SQLERRM;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Recreate the trigger
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ============================================
-- VERIFY THE FIX
-- ============================================
-- Check if trigger exists:
-- SELECT * FROM pg_trigger WHERE tgname = 'on_auth_user_created';
--
-- Test the function manually (replace with a test UUID):
-- SELECT handle_new_user() FROM (SELECT gen_random_uuid()::uuid as id, 'test@test.com' as email, '{}'::jsonb as raw_user_meta_data) as NEW;
-- ============================================

