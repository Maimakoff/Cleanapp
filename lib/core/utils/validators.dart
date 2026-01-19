class Validators {
  // Email validation
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Введите email';
    }
    
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Введите корректный email';
    }
    
    if (value.length > 255) {
      return 'Email слишком длинный';
    }
    
    return null;
  }

  // Phone validation (Russian format)
  static String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Введите телефон';
    }
    
    final cleaned = value.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    final phoneRegex = RegExp(r'^\+?7\d{10}$|^8\d{10}$|^\d{10}$');
    
    if (!phoneRegex.hasMatch(cleaned)) {
      return 'Введите корректный номер телефона';
    }
    
    return null;
  }

  // Address validation
  static String? validateAddress(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Введите адрес';
    }
    
    if (value.trim().length < 5) {
      return 'Адрес слишком короткий';
    }
    
    if (value.length > 500) {
      return 'Адрес слишком длинный';
    }
    
    // Проверка на потенциально опасные символы
    if (value.contains('<') || value.contains('>') || value.contains('script')) {
      return 'Адрес содержит недопустимые символы';
    }
    
    return null;
  }

  // Password validation
  static String? validatePassword(String? value, {int minLength = 6}) {
    if (value == null || value.isEmpty) {
      return 'Введите пароль';
    }
    
    if (value.length < minLength) {
      return 'Пароль должен быть не менее $minLength символов';
    }
    
    if (value.length > 128) {
      return 'Пароль слишком длинный';
    }
    
    return null;
  }

  // UUID validation
  static bool isValidUUID(String? value) {
    if (value == null || value.isEmpty) return false;
    
    final uuidRegex = RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
      caseSensitive: false,
    );
    
    return uuidRegex.hasMatch(value);
  }

  // Booking ID validation
  static String? validateBookingId(String? value) {
    if (value == null || value.isEmpty) {
      return 'ID заказа не указан';
    }
    
    if (!isValidUUID(value)) {
      return 'Некорректный ID заказа';
    }
    
    return null;
  }

  // Sanitize input (remove potentially dangerous characters)
  static String sanitizeInput(String input) {
    return input
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#x27;')
        .trim();
  }

  // Validate date string
  static bool isValidDateString(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return false;
    
    try {
      final date = DateTime.parse(dateStr);
      // Проверяем, что дата не слишком старая и не слишком далекая
      final now = DateTime.now();
      final minDate = DateTime(2020, 1, 1);
      final maxDate = now.add(const Duration(days: 365 * 2));
      
      return date.isAfter(minDate) && date.isBefore(maxDate);
    } catch (e) {
      return false;
    }
  }

  // Validate time string (HH:mm format)
  static bool isValidTimeString(String? timeStr) {
    if (timeStr == null || timeStr.isEmpty) return false;
    
    final timeRegex = RegExp(r'^([0-1]?[0-9]|2[0-3]):[0-5][0-9]$');
    return timeRegex.hasMatch(timeStr);
  }

  // Validate area (must be positive number)
  static String? validateArea(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Введите площадь';
    }
    
    final area = int.tryParse(value.trim());
    if (area == null) {
      return 'Площадь должна быть числом';
    }
    
    if (area <= 0) {
      return 'Площадь должна быть больше 0';
    }
    
    // Максимальная разумная площадь (например, 10000 м²)
    if (area > 10000) {
      return 'Площадь слишком большая';
    }
    
    return null;
  }
}

