import 'package:intl/intl.dart';

/// 日期格式化工具类
class DateFormatter {
  static final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');
  static final DateFormat _dateTimeFormat = DateFormat('yyyy-MM-dd HH:mm:ss');
  static final DateFormat _displayFormat = DateFormat('yyyy年MM月dd日');

  /// 日期转字符串 (yyyy-MM-dd)
  static String format(DateTime? date) {
    if (date == null) return '';
    return _dateFormat.format(date);
  }

  /// 日期转显示格式 (yyyy年MM月dd日)
  static String formatDisplay(DateTime? date) {
    if (date == null) return '未设置';
    return _displayFormat.format(date);
  }

  /// 日期时间转字符串 (yyyy-MM-dd HH:mm:ss)
  static String formatDateTime(DateTime dateTime) {
    return _dateTimeFormat.format(dateTime);
  }

  /// 字符串转日期
  static DateTime? parse(String? dateString) {
    if (dateString == null || dateString.isEmpty) return null;
    try {
      return _dateFormat.parse(dateString);
    } catch (e) {
      return null;
    }
  }

  /// 判断是否超期
  static bool isOverdue(DateTime? plannedReturnDate) {
    if (plannedReturnDate == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return plannedReturnDate.isBefore(today);
  }
}
