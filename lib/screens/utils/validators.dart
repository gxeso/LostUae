class Validators {
  //email regex pattern.
  static final RegExp emailRegExp = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');

  // password regex pattern.
 static final RegExp passwordRegExp =
    RegExp(r'^(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d@$!%*#?&]{8,}$');


  static final RegExp nicknameRegex =
      RegExp(r'^[a-zA-Z0-9]{3,15}$');

  // UAE phone:
  // +9715XXXXXXXX or 05XXXXXXXX
  static final RegExp uaePhoneRegex =
      RegExp(r'^(?:\+971|05)[0-9]{8}$');


}
