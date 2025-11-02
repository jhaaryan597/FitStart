DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'favorites'
      AND policyname = 'Users can view own favorites'
  ) THEN
    CREATE POLICY "Users can view own favorites"
      ON public.favorites
      FOR SELECT
      USING (auth.uid() = user_id);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'favorites'
      AND policyname = 'Users can modify own favorites'
  ) THEN
    CREATE POLICY "Users can modify own favorites"
      ON public.favorites
      FOR INSERT
      WITH CHECK (auth.uid() = user_id);
  END IF;
END
$$;
