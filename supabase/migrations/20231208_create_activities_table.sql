-- Create activities table
CREATE TABLE IF NOT EXISTS public.activities (
    id TEXT NOT NULL,
    user_id TEXT NOT NULL,
    target_user_id TEXT NOT NULL,
    type TEXT NOT NULL CHECK (type IN ('like', 'comment', 'follow', 'mention')),
    post_id TEXT,
    comment_text TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
    CONSTRAINT activities_pkey PRIMARY KEY (id)
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_activities_target_user_id ON public.activities(target_user_id);
CREATE INDEX IF NOT EXISTS idx_activities_user_id ON public.activities(user_id);
CREATE INDEX IF NOT EXISTS idx_activities_post_id ON public.activities(post_id);
CREATE INDEX IF NOT EXISTS idx_activities_type ON public.activities(type);
CREATE INDEX IF NOT EXISTS idx_activities_created_at ON public.activities(created_at DESC);

-- Add foreign key constraints
ALTER TABLE public.activities 
    ADD CONSTRAINT activities_user_id_fkey 
    FOREIGN KEY (user_id) REFERENCES public.profiles(id) ON DELETE CASCADE;

ALTER TABLE public.activities 
    ADD CONSTRAINT activities_target_user_id_fkey 
    FOREIGN KEY (target_user_id) REFERENCES public.profiles(id) ON DELETE CASCADE;

ALTER TABLE public.activities 
    ADD CONSTRAINT activities_post_id_fkey 
    FOREIGN KEY (post_id) REFERENCES public.posts(id) ON DELETE CASCADE;

-- Enable RLS (Row Level Security)
ALTER TABLE public.activities ENABLE ROW LEVEL SECURITY;

-- Create policies for RLS
-- Users can view activities where they are the target
CREATE POLICY "Users can view activities directed to them" ON public.activities
    FOR SELECT USING (auth.uid() = target_user_id);

-- Users can create activities
CREATE POLICY "Users can create activities" ON public.activities
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Users can update their own activities (if needed)
CREATE POLICY "Users can update their own activities" ON public.activities
    FOR UPDATE USING (auth.uid() = user_id);

-- Users can delete their own activities (if needed)
CREATE POLICY "Users can delete their own activities" ON public.activities
    FOR DELETE USING (auth.uid() = user_id);

-- Create a function to automatically update the updated_at timestamp
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create a trigger to automatically update the updated_at column
CREATE TRIGGER handle_activities_updated_at
    BEFORE UPDATE ON public.activities
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_updated_at();
