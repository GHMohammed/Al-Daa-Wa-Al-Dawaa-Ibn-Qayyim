import 'dart:convert';
import 'dart:io';

import 'package:al_daa_wal_dawaa/core/constants/app_constants.dart';

/// بيانات التحديث المُعاد من الخادم
class UpdateInfo {
  const UpdateInfo({
    required this.version,
    required this.apkUrl,
    required this.notes,
  });

  final String version;
  final String apkUrl;
  final String notes;
}

/// خدمة التحقق من وجود تحديث جديد
class UpdateService {
  UpdateService._();

  /// يجلب version.json من الرابط الثابت ويقارنه بالإصدار الحالي.
  /// يُعيد [UpdateInfo] إذا كان الإصدار البعيد أحدث، وإلا يُعيد null.
  /// يبتلع أي خطأ (شبكة، تحليل JSON، ...) حتى لا يُعطّل التطبيق.
  static Future<UpdateInfo?> checkForUpdate() async {
    try {
      final url = AppConstants.updateCheckUrl;
      if (url.isEmpty || url.contains('YOUR_VERSION')) return null;

      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 10);

      final request = await client.getUrl(Uri.parse(url));
      final response = await request.close();

      if (response.statusCode != 200) return null;

      final body = await response.transform(utf8.decoder).join();
      client.close();

      final map = json.decode(body) as Map<String, dynamic>;
      final remoteVersion = (map['version'] as String?)?.trim() ?? '';
      final apkUrl       = (map['apk_url']  as String?)?.trim() ?? '';
      final notes        = (map['notes']    as String?)?.trim() ?? '';

      if (remoteVersion.isEmpty) return null;
      if (!_isNewer(remoteVersion, AppConstants.appVersion)) return null;

      return UpdateInfo(
        version: remoteVersion,
        apkUrl: apkUrl,
        notes: notes,
      );
    } catch (_) {
      // تجاهل أي خطأ بهدوء (لا إنترنت، رابط خاطئ، JSON غير صالح...)
      return null;
    }
  }

  /// يُعيد true إذا كان [remote] أحدث من [current] (مقارنة semver بسيطة)
  static bool _isNewer(String remote, String current) {
    final r = _parts(remote);
    final c = _parts(current);
    for (var i = 0; i < 3; i++) {
      final rv = i < r.length ? r[i] : 0;
      final cv = i < c.length ? c[i] : 0;
      if (rv > cv) return true;
      if (rv < cv) return false;
    }
    return false;
  }

  static List<int> _parts(String v) =>
      v.split('.').map((s) => int.tryParse(s) ?? 0).toList();
}
