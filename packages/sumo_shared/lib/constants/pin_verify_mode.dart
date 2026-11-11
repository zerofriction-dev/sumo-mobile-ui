enum PinVerifyMode {
  gate,
  confirm;

  static const String argumentKey = 'pinVerifyMode';

  Map<String, dynamic> get arguments => <String, dynamic>{argumentKey: name};

  static PinVerifyMode fromArguments(dynamic arguments) {
    if (arguments is Map && arguments[argumentKey] == confirm.name) {
      return confirm;
    }
    return gate;
  }
}
