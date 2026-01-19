class CommonResponse {
  final String message;

  CommonResponse({
    required this.message,
  });

  factory CommonResponse.fromJson(Map<String, dynamic> json) {
    return CommonResponse(
      message: json['message'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'message': message};
  }
}
