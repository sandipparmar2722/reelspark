// ignore: avoid_classes_with_only_static_members
abstract class RegExps {
  static final RegExp email = RegExp(
      r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+");
  static final RegExp phoneNumber = RegExp(r'(^[0-9]{6,14}$)');
  static final RegExp password =
      RegExp(r'^(?=.*[a-z])(?=.*\d)[a-zA-Z\d\w\W]{8,}$');
}
