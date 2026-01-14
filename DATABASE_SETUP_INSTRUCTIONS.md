# Инструкция по настройке базы данных Supabase

## Проблема
Ошибка: `PostgrestException: Could not find the table 'public.bookings' (PGRST205)`

## Решение

### Шаг 1: Откройте Supabase SQL Editor

1. Войдите в ваш проект Supabase: https://supabase.com/dashboard
2. Перейдите в **SQL Editor** (в левом меню)
3. Нажмите **New Query**

### Шаг 2: Выполните SQL скрипт

Скопируйте и выполните весь SQL из файла `database_setup.sql` в корне проекта.

Или выполните этот упрощенный вариант:

```sql
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

-- Индексы
CREATE INDEX IF NOT EXISTS idx_bookings_user_id ON public.bookings(user_id);
CREATE INDEX IF NOT EXISTS idx_bookings_date ON public.bookings(date);
CREATE INDEX IF NOT EXISTS idx_bookings_status ON public.bookings(status);

-- Row Level Security
ALTER TABLE public.bookings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own bookings"
  ON public.bookings FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own bookings"
  ON public.bookings FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own bookings"
  ON public.bookings FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);
```

### Шаг 3: Проверьте создание таблицы

Выполните запрос для проверки:

```sql
SELECT table_name, column_name, data_type 
FROM information_schema.columns 
WHERE table_schema = 'public' AND table_name = 'bookings'
ORDER BY ordinal_position;
```

Должны увидеть все колонки таблицы.

### Шаг 4: Перезапустите приложение

После создания таблицы перезапустите Flutter приложение.

## Структура таблицы

| Колонка | Тип | Описание |
|---------|-----|----------|
| id | UUID | Уникальный идентификатор (автоматически) |
| user_id | UUID | ID пользователя (связь с auth.users) |
| tariff_id | TEXT | ID тарифа |
| tariff_name | TEXT | Название тарифа |
| date | DATE | Дата уборки |
| time | TEXT | Время уборки |
| address | TEXT | Адрес |
| phone | TEXT | Телефон |
| area | INTEGER | Площадь (опционально) |
| total_price | DECIMAL | Общая стоимость |
| discount_percentage | INTEGER | Процент скидки (опционально) |
| status | TEXT | Статус заказа (по умолчанию 'pending') |
| additional_options | JSONB | Дополнительные опции (опционально) |
| payment_method | TEXT | Способ оплаты (опционально) |
| created_at | TIMESTAMP | Дата создания (автоматически) |
| updated_at | TIMESTAMP | Дата обновления (автоматически) |

## Безопасность (RLS)

Таблица защищена Row Level Security (RLS):
- Пользователи могут видеть только свои заказы
- Пользователи могут создавать только свои заказы
- Пользователи могут обновлять только свои заказы

## Устранение проблем

### Если таблица все еще не найдена:

1. **Проверьте схему:**
   ```sql
   SELECT table_schema, table_name 
   FROM information_schema.tables 
   WHERE table_name = 'bookings';
   ```
   Должно быть: `public.bookings`

2. **Проверьте права доступа:**
   - Убедитесь, что используете правильный `SUPABASE_ANON_KEY`
   - Проверьте, что RLS политики созданы

3. **Проверьте подключение:**
   - Убедитесь, что `.env` файл содержит правильные `SUPABASE_URL` и `SUPABASE_ANON_KEY`
   - Перезапустите приложение после изменения `.env`

## Дополнительная информация

Полный SQL скрипт с триггерами и дополнительными настройками находится в файле `database_setup.sql`.

