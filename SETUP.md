# Инструкция по настройке Flutter проекта Cleanapp

## Требования

- Flutter SDK 3.0.0 или выше
- Dart SDK 3.0.0 или выше
- Аккаунт Supabase

## Шаги установки

### 1. Установите зависимости

```bash
flutter pub get
```

### 2. Настройте Supabase

1. Создайте проект на [Supabase](https://supabase.com)
2. Скопируйте URL и Anon Key из настроек проекта
3. Создайте файл `.env` в корне проекта:

```env
SUPABASE_URL=your_supabase_url_here
SUPABASE_ANON_KEY=your_supabase_anon_key_here
```

### 3. Настройте базу данных

Создайте следующие таблицы в Supabase:

#### Таблица `bookings`
```sql
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

-- Индексы для оптимизации
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

**Важно:** Для полной настройки используйте файл `database_setup.sql` в корне проекта, который содержит полную схему с триггерами и политиками безопасности.

#### Таблица `referral_bonuses`
```sql
CREATE TABLE referral_bonuses (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id),
  discount_percentage INTEGER NOT NULL,
  is_used BOOLEAN DEFAULT FALSE,
  expires_at TIMESTAMP NOT NULL,
  created_at TIMESTAMP DEFAULT NOW()
);
```

### 4. Создайте Edge Function для создания заказов

Создайте функцию `create-order` в Supabase Edge Functions для безопасного создания заказов.

### 5. Запустите приложение

```bash
flutter run
```

## Структура проекта

```
lib/
├── main.dart                 # Точка входа
├── models/                   # Модели данных
│   ├── service.dart
│   ├── booking.dart
│   └── tariff.dart
├── services/                 # Сервисы
│   ├── supabase_service.dart
│   └── auth_service.dart
├── screens/                  # Экраны
│   ├── home_screen.dart
│   ├── auth_screen.dart
│   ├── tariffs_screen.dart
│   ├── tariff_detail_screen.dart
│   ├── calendar_screen.dart
│   ├── booking_screen.dart
│   ├── confirmation_screen.dart
│   ├── profile_screen.dart
│   ├── search_screen.dart
│   └── not_found_screen.dart
├── widgets/                  # Виджеты
│   ├── tab_bar.dart
│   └── mobile_layout.dart
├── providers/                # State Management
│   └── auth_provider.dart
├── router/                   # Навигация
│   └── app_router.dart
└── theme/                    # Темы
    └── app_theme.dart
```

## Основные функции

- ✅ Аутентификация через Supabase
- ✅ Главная страница с акциями
- ✅ Поиск услуг
- ✅ Календарь для бронирования
- ✅ Различные тарифы
- ✅ Оформление заказа
- ✅ Профиль пользователя

## Примечания

- Убедитесь, что в Supabase настроены правильные политики безопасности (RLS)
- Для работы с Edge Functions необходимо настроить их в Supabase Dashboard
- Для локализации русского языка убедитесь, что установлен пакет `intl`

