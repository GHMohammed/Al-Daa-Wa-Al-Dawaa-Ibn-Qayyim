# خط ثمانية (Thmanyah Sans)

يستخدم التطبيق **خط ثمانية الرقمي** بخمسة أوزان. ترخيص الخط يسمح بتضمينه داخل التطبيق المبني (APK)، لكنه **يمنع رفع ملفات الخط على أي موقع أو خادم**، ولذلك المجلد `assets/fonts/` مستثنى من git.

## التجهيز قبل البناء

1. حمّل الخط بصيغة **OTF** من الموقع الرسمي: https://font.thmanyah.com
2. انسخ ملفات المجلد `thmanyah-sans/otf/` إلى `assets/fonts/`:

| الملف | الوزن |
|---|---|
| `thmanyah-sans-Light.otf` | 300 |
| `thmanyah-sans-Regular.otf` | 400 |
| `thmanyah-sans-Medium.otf` | 500 |
| `thmanyah-sans-Bold.otf` | 700 |
| `thmanyah-sans-Black.otf` | 900 |

3. شغّل `flutter pub get` ثم ابنِ التطبيق كالمعتاد.

> لا تستخدم حزمة WOFF2؛ Flutter على أندرويد لا يقرأ هذه الصيغة.
