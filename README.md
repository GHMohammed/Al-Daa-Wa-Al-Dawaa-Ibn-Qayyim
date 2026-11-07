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
بصوت الشيخ **عبد الرزاق بن عبد المحسن البدر**، مع **نص الكتاب كاملاً** مربوطاً بالدروس.

يدعم التطبيق التشغيل المباشر أو التحميل للاستماع دون إنترنت، مع تتبع التقدم والاستمرار من حيث توقفت،
وحفظ العلامات والملاحظات المكتوبة والصوتية أثناء الاستماع، وقراءة الكتاب في شاشة قراءة مريحة.

</div>

---

## 📸 Screenshots

<div dir="rtl">

<!-- TODO: أضف لقطات الشاشة هنا -->
| الدروس | المشغّل | الكتاب | القراءة | علاماتي |
|:---:|:---:|:---:|:---:|:---:|
| _قريباً_ | _قريباً_ | _قريباً_ | _قريباً_ | _قريباً_ |

</div>

---

## ✨ المميزات | Features

<div dir="rtl">

### الاستماع

| # | الميزة |
|---|--------|
| 🎧 | **استماع مباشر أو تحميل** — استمع فوراً أو احفظ الدرس للاستماع دون إنترنت |
| ▶️ | **أكمل الاستماع** — بطاقة في الرئيسية تعيدك لآخر درس من حيث توقفت |
| ⏩ | **التحكم بالسرعة** — من 0.75× إلى 2×، وتبقى السرعة محفوظة لكل الدروس |
| 🔔 | **التشغيل في الخلفية** — مع التحكم من الإشعار وشاشة القفل (التالي، السابق، ±30 ثانية) |

### العلامات والملاحظات

| # | الميزة |
|---|--------|
| 🔖 | **علامات مرجعية** — احفظ أي موضع في الدرس بضغطة، وسمّه إن شئت |
| 📝 | **ملاحظات مكتوبة** — مرتبطة بالدقيقة التي كنت فيها |
| 🎙️ | **ملاحظات صوتية** — سجّل فائدتك بصوتك واستمع إليها لاحقاً |
| 📍 | **نقاط على شريط التقدم** — ترى مواضع علاماتك وملاحظاتك داخل الدرس |
| 🗂️ | **شاشة «علاماتي»** — كل ما حفظته من كل الدروس، مع التصفية والحذف والتراجع |

### الكتاب

| # | الميزة |
|---|--------|
| 📖 | **نص الكتاب كاملاً** — مع فهرس بعناوين المحقق وأرقام صفحات الطبعة المطبوعة |
| 🔗 | **ربط النص بالدروس** — «استمع لشرح هذا الموضع» في الكتاب، و«اقرأ هذا الموضع» في المشغّل |
| 🔍 | **بحث في الكتاب** — لا يتأثر بالتشكيل ولا بأشكال الهمزة |
| 🎨 | **إعدادات القراءة** — حجم الخط، تباعد الأسطر، وثلاثة ألوان للصفحة: فاتح، ورقي، داكن |
| 💾 | **أكمل القراءة** — يحفظ موضعك في الكتاب ونسبة ما قرأته |

### عام

| # | الميزة |
|---|--------|
| 📊 | **تتبع التقدم** — نسبة إنجازك في كل درس وفي الكتاب، وتصفية الدروس حسب حالتها |
| 🌙 | **وضع فاتح وداكن** — يتبع إعداد الهاتف تلقائياً |
| 🕌 | **هوية بصرية إسلامية** — أخضر وذهبي مع زخرفة هندسية بنجوم ثمانية، وخط ثمانية |
| 🔤 | **واجهة عربية RTL** — مبنية بالكامل للمحتوى العربي |
| 🔄 | **تحديث تلقائي** — يتحقق من الإصدارات الجديدة عند كل تشغيل |

</div>

---

## 🛠️ Tech Stack

| Technology | Usage |
|---|---|
| **Flutter & Dart** | UI framework |
| **Riverpod** | State management |
| **just_audio + audio_service** | Audio playback & background service |
| **SQLite (sqflite)** | Progress, downloads, bookmarks & notes (schema v2 with migrations) |
| **shared_preferences** | Playback speed, reading position & reader settings |
| **record** | Voice notes (AAC) |
| **scrollable_positioned_list** | Book reader: jump to any paragraph and track position |
| **go_router** | Navigation |
| **Thmanyah Sans** | Bundled font (not in git — see `docs/fonts.md`) |
| **Google Drive** | Audio file & APK hosting |
| **flutter_cache_manager** | Network asset caching |

---

## 📁 Project Structure

```
lib/
├── core/
│   ├── constants/app_constants.dart     # ثوابت التطبيق (URLs, strings, helpers)
│   ├── database/database_init.dart      # تهيئة SQLite
│   ├── router/app_router.dart           # GoRouter routes + navigatorKey
│   ├── theme/
│   │   ├── app_colors.dart              # اللوحة + الألوان الدلالية (context.colors)
│   │   ├── app_typography.dart          # المقياس الطباعي بخط ثمانية
│   │   ├── app_spacing.dart             # المسافات والزوايا
│   │   └── app_theme.dart               # الثيم الفاتح والداكن
│   └── utils/arabic_text.dart           # توحيد النص العربي للبحث
│
├── data/
│   ├── local/
│   │   ├── database_helper.dart         # SQLite: التقدم، التحميلات، العلامات، الملاحظات
│   │   ├── download_manager.dart        # تحميل وإدارة ملفات الدروس
│   │   └── voice_note_storage.dart      # ملفات الملاحظات الصوتية
│   ├── models/                          # الدرس، التقدم، العلامات والملاحظات، الكتاب
│   ├── remote/
│   │   ├── archive_service.dart         # قائمة الدروس
│   │   └── update_service.dart          # التحقق من التحديثات
│   └── services/app_audio_handler.dart  # AudioService handler (الخلفية والإشعار)
│
├── domain/providers/
│   ├── player_provider.dart             # المشغّل + حفظ السرعة
│   ├── progress_provider.dart           # التقدم الحي والإحصاءات
│   ├── home_provider.dart               # تصفية الدروس + «أكمل الاستماع»
│   ├── annotations_provider.dart        # العلامات والملاحظات
│   ├── voice_note_player_provider.dart  # تشغيل الملاحظات الصوتية
│   ├── book_provider.dart               # الكتاب، فهرس القارئ، البحث، إعدادات القراءة
│   ├── download_provider.dart           # حالة التحميلات
│   └── lessons_provider.dart            # قائمة الدروس
│
├── ui/
│   ├── screens/
│   │   ├── home_screen.dart             # الدروس
│   │   ├── player_screen.dart           # المشغّل
│   │   ├── book_screen.dart             # الكتاب: أكمل القراءة + الفهرس + البحث
│   │   ├── reader_screen.dart           # شاشة القراءة
│   │   ├── bookmarks_screen.dart        # علاماتي
│   │   ├── progress_screen.dart         # التقدم
│   │   └── settings_screen.dart         # الإعدادات
│   └── widgets/                         # الزخرفة، رأس الصفحات، المشغّل المصغّر، المسجّل، ...
│
└── main.dart                            # نقطة البداية + منطق التحديث التلقائي

assets/
├── data/
│   ├── lessons.json                     # بيانات الدروس (83 درساً)
│   ├── book.json                        # نص الكتاب + مواضع الدروس فيه
│   └── version.json                     # رقم الإصدار المحلي
├── fonts/                               # خط ثمانية — غير مرفوع (انظر docs/fonts.md)
└── images/                              # الأيقونة والغلاف

docs/
├── development-plan.md                  # خطة التطوير بالمراحل
└── fonts.md                             # تجهيز خط ثمانية
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
git clone https://github.com/GHMohammed/Al-Daa-Wa-Al-Dawaa-Ibn-Qayyim.git
cd Al-Daa-Wa-Al-Dawaa-Ibn-Qayyim

# 2. ضع ملفات خط ثمانية (OTF) في assets/fonts/ — الخطوات في docs/fonts.md
#    (الترخيص يمنع رفعها إلى المستودع، ولن يُبنى التطبيق بدونها)

# 3. ثبّت الاعتماديات
flutter pub get

# 4. شغّل على جهاز أو محاكي متصل
flutter run

# الاختبارات
flutter test
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

## 📚 Sources & Credits | المصادر

<div dir="rtl">

- **الشرح الصوتي:** الشيخ عبد الرزاق بن عبد المحسن البدر.
- **نص الكتاب:** طبعة دار عطاءات العلم – دار ابن حزم (الطبعة الرابعة، 1440 هـ)، بتحقيق محمد أجمل الإصلاحي،
  من [المكتبة الشاملة](https://shamela.ws/book/98093) حيث أهدتها مؤسسة عطاءات العلم.
  أُثبت المتن دون الحواشي ومقدمة التحقيق، والعناوين من وضع المحقق.
- **الخط:** [خط ثمانية](https://font.thmanyah.com) — مضمّن في التطبيق وفق ترخيصه، وغير مرفوع إلى المستودع.

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
