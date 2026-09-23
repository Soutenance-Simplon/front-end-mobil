class OtpModel {
  final String? id;
  final String telephone;
  final String otpType;
  final String? code;
  final DateTime? expiresAt;
  final bool? used;

  OtpModel({
    this.id,
    required this.telephone,
    this.otpType = 'VERIFICATION_TELEPHONE',
    this.code,
    this.expiresAt,
    this.used,
  });

  factory OtpModel.fromJson(Map<String, dynamic> json) {
    return OtpModel(
      id: json['id']?.toString(),
      telephone: json['telephone'] ?? '',
      otpType: json['otp_type'] ?? json['otpType'] ?? 'VERIFICATION_TELEPHONE',
      code: json['code'],
      expiresAt: json['expires_at'] != null ? DateTime.tryParse(json['expires_at']) : null,
      used: json['used'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'telephone': telephone,
      'otp_type': otpType,
      if (code != null) 'code': code,
    };
  }
}
