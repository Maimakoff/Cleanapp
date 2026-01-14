-- ============================================
-- SQL Схема для таблицы bookings в Supabase
-- ============================================
-- Выполните этот SQL в Supabase SQL Editor
-- (Table Editor -> SQL Editor -> New Query)

-- Создание таблицы bookings
CREATE TABLE IF NOT EXISTS public.bookings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  tariff_id TEXT NOT NULL,
  tariff_name TEXT NOT NULL,
  date DATE NOT NULL,
  time TEXT NOT NULL,
  address TEXT NOT NULL,
  phone TEXT NOT NULL,
  area INTEGER,
  total_price DECIMAL(10, 2) NOT NULL DEFAULT 0,
  discount_percentage INTEGER,
  status TEXT NOT NULL DEFAULT 'pending',
  additional_options JSONB,
  payment_method TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Создание индексов для оптимизации запросов
CREATE INDEX IF NOT EXISTS idx_bookings_user_id ON public.bookings(user_id);
CREATE INDEX IF NOT EXISTS idx_bookings_date ON public.bookings(date);
CREATE INDEX IF NOT EXISTS idx_bookings_status ON public.bookings(status);
CREATE INDEX IF NOT EXISTS idx_bookings_date_time ON public.bookings(date, time);

-- Функция для автоматического обновления updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Триггер для автоматического обновления updated_at
DROP TRIGGER IF EXISTS update_bookings_updated_at ON public.bookings;
CREATE TRIGGER update_bookings_updated_at
  BEFORE UPDATE ON public.bookings
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- Row Level Security (RLS) Policies
-- ============================================

-- Включаем RLS для таблицы
ALTER TABLE public.bookings ENABLE ROW LEVEL SECURITY;

-- Политика: пользователи могут видеть только свои заказы
CREATE POLICY "Users can view their own bookings"
  ON public.bookings
  FOR SELECT
  USING (auth.uid() = user_id);

-- Политика: пользователи могут создавать свои заказы
CREATE POLICY "Users can insert their own bookings"
  ON public.bookings
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Политика: пользователи могут обновлять свои заказы
CREATE POLICY "Users can update their own bookings"
  ON public.bookings
  FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Политика: пользователи могут удалять свои заказы (опционально)
-- CREATE POLICY "Users can delete their own bookings"
--   ON public.bookings
--   FOR DELETE
--   USING (auth.uid() = user_id);

-- ============================================
-- Проверка создания таблицы
-- ============================================
-- Выполните этот запрос, чтобы проверить, что таблица создана:
-- SELECT table_name, column_name, data_type 
-- FROM information_schema.columns 
-- WHERE table_schema = 'public' AND table_name = 'bookings'
-- ORDER BY ordinal_position;

