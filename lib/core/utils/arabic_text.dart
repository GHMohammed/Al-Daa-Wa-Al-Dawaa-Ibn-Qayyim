/// توحيد النص العربي للبحث: حذف التشكيل والتطويل وتوحيد الهمزات والتاء المربوطة
String normalizeArabic(String text) {
  return text
      .replaceAll(RegExp('[ً-ْٰـ]'), '')
      .replaceAll(RegExp('[إأآٱ]'), 'ا')
      .replaceAll('ى', 'ي')
      .replaceAll('ة', 'ه')
      .replaceAll(RegExp(r'\s+'), ' ');
}

/// أرقام عربية مشرقية (للعرض في سياق الكتاب)
String arabicDigits(int n) =>
    n.toString().split('').map((d) => '٠١٢٣٤٥٦٧٨٩'[int.parse(d)]).join();
