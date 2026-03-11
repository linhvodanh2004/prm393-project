// Data Models for Vietnam Open API (provinces.open-api.vn)

class Province {
  final int code;
  final String name;

  Province({required this.code, required this.name});

  factory Province.fromJson(Map<String, dynamic> json) {
    return Province(code: json['code'] as int, name: json['name'] as String);
  }
}

class Ward {
  final int code;
  final String name;

  Ward({required this.code, required this.name});

  factory Ward.fromJson(Map<String, dynamic> json) {
    return Ward(code: json['code'] as int, name: json['name'] as String);
  }
}
