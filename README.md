<div dir="rtl">

# شرح كتاب الداء والدواء

</div>

<p align="center">
  <img src="assets/images/app_icon.png" width="120" alt="App Icon" />
</p>

<p align="center">
  <a href="https://flutter.dev"><img src="https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white" alt="Flutter"></a>
  <a href="https://www.android.com"><img src="https://img.shields.io/badge/Platform-Android-3DDC84?logo=android&logoColor=white" alt="Android"></a>
  <img src="https://img.shields.io/badge/License-MIT-green.svg" alt="MIT License">
  <img src="https://img.shields.io/badge/Release-v1.0.0-blue.svg" alt="Release v1.0.0">
</p>

<p align="center">
  <a href="https://drive.google.com/uc?export=download&id=1SBSO8cyGeFS9r_u3EONYm5Q4a2hIfiQu">
    <img src="https://img.shields.io/badge/⬇️ تحميل التطبيق-APK-0a3d2e?style=for-the-badge" alt="Download APK">
  </a>
</p>

---

<div dir="rtl">

## عن التطبيق | About

تطبيق أندرويد يتيح الاستماع إلى **83 درساً صوتياً مفهرساً** في شرح كتاب **"الداء والدواء"** لابن القيم الجوزية —
بصوت الشيخ **عبد الرزاق بن عبد المحسن البدر**.

يدعم التطبيق التشغيل المباشر أو التحميل للاستماع دون إنترنت، مع تتبع التقدم والاستمرار من حيث توقفت.

</div>

---

## 📸 Screenshots

<div dir="rtl">

<!-- TODO: أضف لقطات الشاشة هنا -->
| الرئيسية | المشغّل | التقدم | الإعدادات |
|:---:|:---:|:---:|:---:|
| _قريباً_ | _قريباً_ | _قريباً_ | _قريباً_ |

</div>

---

## ✨ المميزات | Features

<div dir="rtl">

| # | الميزة |
|---|--------|
| 🎧 | **استماع مباشر أو تحميل** — استمع فوراً أو حمّل الدرس للاستماع offline |
| 📊 | **تتبع التقدم** — يعرض نسبة إنجازك في كل درس وعبر الكتاب كاملاً |
| ▶️ | **يكمل من حيث توقفت** — يحفظ موضعك تلقائياً ويستأنف عند كل تشغيل |
| 🌙 | **دعم الوضع الداكن** — يتبع إعداد النظام تلقائياً |
| 🔄 | **تحديث تلقائي** — يتحقق من الإصدارات الجديدة عند كل تشغيل |
| 🇸🇦 | **واجهة عربية RTL** — مبنية بالكامل للمحتوى العربي |
| 🔔 | **إشعار الصوت المستمر** — يعمل في الخلفية مع التحكم من شريط الإشعارات |

</div>

---

## 🛠️ Tech Stack

| Technology | Usage |
|---|---|
| **Flutter & Dart** | UI framework |
| **Riverpod** | State management |
| **just_audio + audio_service** | Audio playback & background service |
| **SQLite (sqflite)** | Local progress & downloads database |
| **go_router** | Navigation |
| **Google Drive** | Audio file & APK hosting |
| **flutter_cache_manager** | Network asset caching |

---

## 📁 Project Structure

```
lib/
├── core/
│   ├── constants/
│   │   └── app_constants.dart       # ثوابت التطبيق (URLs, strings, helpers)
│   ├── database/
│   │   └── database_init.dart       # تهيئة SQLite
│   ├── router/
│   │   └── app_router.dart          # GoRouter routes + navigatorKey
│   └── theme/
│       └── app_theme.dart           # Light & Dark themes
│
├── data/
│   ├── local/
│   │   ├── database_helper.dart     # CRUD operations
│   │   └── download_manager.dart    # تحميل وإدارة الملفات
│   ├── models/
│   │   ├── lesson_model.dart        # نموذج بيانات الدرس
│   │   └── progress_model.dart      # نموذج التقدم
│   ├── remote/
│   │   ├── archive_service.dart     # جلب الدروس من الإنترنت
│   │   └── update_service.dart      # التحقق من التحديثات
│   └── services/
│       └── app_audio_handler.dart   # AudioService handler
│
├── domain/
│   └── providers/
│       ├── download_provider.dart   # حالة التحميلات
│       ├── lessons_provider.dart    # قائمة الدروس
│       ├── player_provider.dart     # حالة المشغّل
│       └── progress_provider.dart   # إحصاءات التقدم
│
├── ui/
│   ├── screens/
│   │   ├── home_screen.dart         # الشاشة الرئيسية
│   │   ├── player_screen.dart       # مشغّل الدرس
│   │   ├── progress_screen.dart     # إحصاءات التقدم
│   │   └── settings_screen.dart     # الإعدادات
│   └── widgets/
│       ├── app_bottom_nav.dart      # شريط التنقل السفلي
│       ├── download_button.dart     # زر التحميل
│       ├── lesson_card.dart         # بطاقة الدرس
│       ├── mini_player.dart         # المشغّل المصغّر
│       └── progress_circle.dart     # دائرة التقدم
│
└── main.dart                        # نقطة البداية + منطق التحديث التلقائي

assets/
├── data/
│   ├── lessons.json                 # بيانات الدروس (83 درساً)
│   └── version.json                 # رقم الإصدار المحلي
└── images/
    ├── app_icon.png                 # أيقونة التطبيق
    └── cover.png                    # غلاف الكتاب
```

---

## 🚀 Getting Started | تشغيل المشروع محلياً

### المتطلبات | Prerequisites

- [Flutter SDK](https://flutter.dev/docs/get-started/install) **3.x** or higher
- **Android SDK** (API 21+)
- Dart **3.0+**

### التثبيت | Installation

```bash
# 1. استنسخ المستودع
git clone https://github.com/YOUR_USERNAME/al_daa_wal_dawaa.git
cd al_daa_wal_dawaa

# 2. ثبّت الاعتماديات
flutter pub get

# 3. شغّل على جهاز أو محاكي متصل
flutter run
```

---

## 📦 Build for Production | بناء APK

```bash
# بناء APK للإصدار
flutter build apk --release

# الملف الناتج:
# build/app/outputs/flutter-apk/app-release.apk
```

---

## 🔄 Auto-Update System | نظام التحديث التلقائي

<div dir="rtl">

يتحقق التطبيق بعد **ثانيتين** من كل تشغيل من ملف `version.json` المستضاف على Google Drive.
إذا كان الإصدار البعيد أحدث من الإصدار المحلي، تظهر نافذة تحديث للمستخدم.

</div>

**How it works:**

1. App fetches `version.json` from a fixed Google Drive URL on startup
2. Compares remote `version` field with `AppConstants.appVersion`
3. If newer → shows an `AlertDialog` with release notes and a download link
4. Network errors are silently ignored — the app never crashes due to update checks

**`assets/data/version.json` schema:**

```json
{
  "version": "1.0.1",
  "apk_url": "https://drive.google.com/uc?export=download&id=YOUR_APK_ID",
  "notes": "وصف التحديث هنا"
}
```

<div dir="rtl">

لإصدار تحديث: عدّل الملف على Google Drive فقط — بدون إعادة بناء التطبيق.

</div>

---

## 🤝 Contributing | المساهمة

<div dir="rtl">

الباب مفتوح للاقتراحات وتقارير الأخطاء عبر [GitHub Issues](../../issues).
إذا وجدت خللاً أو لديك فكرة لتحسين التطبيق، افتح Issue وسيُنظر فيها بإذن الله.

</div>

---

## 👨‍💻 Developer | المطور

<div dir="rtl">

**م. محمد نور الدين**

</div>

[![Website](https://img.shields.io/badge/🌐_الموقع-mohammednour.dev-0a3d2e?style=flat-square)](https://www.mohammednour.dev/)

---

<p align="center">
  <sub>بُني بـ ❤️ خدمةً للعلم الشرعي</sub>
</p>
