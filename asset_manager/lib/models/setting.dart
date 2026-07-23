/// 应用设置模型
class Setting {
  final String key;
  final String value;

  Setting({
    required this.key,
    required this.value,
  });

  factory Setting.fromMap(Map<String, dynamic> map) {
    return Setting(
      key: map['key'] as String,
      value: (map['value'] as String?) ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'key': key,
      'value': value,
    };
  }
}
