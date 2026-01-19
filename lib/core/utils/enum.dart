T enumFromString<T>(Iterable<T> values, String value, T defaultValue) {
  return values.firstWhere((type) => type.toString().split('.').last == value,
      orElse: () => defaultValue);
}

enum TextFieldType {
  divider,
  borderBox,
  borderOnly,
}

enum BusinessCategoryFlowFrom {
  addUpdate,
  changeCategory,
  changeSubCategory,
}

enum UserType { business, personal }

extension UserTypeExtension on UserType {
  static UserType enumFromString(String value) {
    if (value.toLowerCase() == 'business user') {
      //return UserType.business;
      return UserType.personal;
    }
    // normal user
    return UserType.personal;
  }

  String get stringFromEnum {
    if (this == UserType.business) {
      return 'business user';
    }
    return 'normal user';
  }
}

enum Gender { male, female, other, none }

extension GenderExtension on Gender {
  static Gender enumFromString(String value) {
    if (value.toLowerCase() == 'male') {
      return Gender.male;
    }
    if (value.toLowerCase() == 'female') {
      return Gender.female;
    }
    return Gender.other;
  }

  String get stringFromEnum {
    if (this == Gender.male) {
      return 'male';
    }
    if (this == Gender.female) {
      return 'female';
    }
    return 'other';
  }
}

enum FrameType {
  // Bussine Frames
  bFrame1,
  bFrame2,
  bFrame3,
  bFrame5,
  bFrame6,
  bFrame7,
  bFrame8,
  bFrame9,
  bFrame10,
  bFrame11,
  bFrame12,
  bFrame13,

  // Personal Frames
  pFrame1,
  pFrame2,
  pFrame3,
  pFrame4,
  pFrame5,
  pFrame6,

  // Personal Poppins Frames
  pePoppins1,
  pePoppins2,
  pePoppins3,
}

extension FrameTypeExtension on FrameType {
  static FrameType enumFromString(String value) {
    if (value.toLowerCase() == 'frame 1') {
      return FrameType.bFrame1;
    }
    if (value.toLowerCase() == 'frame 2') {
      return FrameType.bFrame2;
    }
    if (value.toLowerCase() == 'frame 3') {
      return FrameType.bFrame3;
    }
    if (value.toLowerCase() == 'frame 5') {
      return FrameType.bFrame5;
    }
    if (value.toLowerCase() == 'frame 6') {
      return FrameType.bFrame6;
    }
    if (value.toLowerCase() == 'frame 7') {
      return FrameType.bFrame7;
    }
    if (value.toLowerCase() == 'frame 8') {
      return FrameType.bFrame8;
    }
    if (value.toLowerCase() == 'frame 9') {
      return FrameType.bFrame9;
    }
    if (value.toLowerCase() == 'frame 10') {
      return FrameType.bFrame10;
    }
    if (value.toLowerCase() == 'frame 11') {
      return FrameType.bFrame11;
    }
    if (value.toLowerCase() == 'frame 12') {
      return FrameType.bFrame12;
    }

    if (value.toLowerCase() == 'personal frame 1') {
      return FrameType.pFrame1;
    }
    if (value.toLowerCase() == 'personal frame 2') {
      return FrameType.pFrame2;
    }
    if (value.toLowerCase() == 'personal frame 3') {
      return FrameType.pFrame3;
    }
    if (value.toLowerCase() == 'personal frame 4') {
      return FrameType.pFrame4;
    }
    if (value.toLowerCase() == 'personal frame 5') {
      return FrameType.pFrame5;
    }
    if (value.toLowerCase() == 'personal frame 6') {
      return FrameType.pFrame6;
    }

    if (value.toLowerCase() == 'personal_poppins_1') {
      return FrameType.pePoppins1;
    }
    if (value.toLowerCase() == 'personal_poppins_2') {
      return FrameType.pePoppins2;
    }
    if (value.toLowerCase() == 'personal_poppins_3') {
      return FrameType.pePoppins3;
    }
    return FrameType.bFrame1;
  }
}

enum FeedType { image, video }

extension FeedTypeExtension on FeedType {
  static FeedType enumFromString(String value) {
    if (value.toLowerCase() == 'image') {
      return FeedType.image;
    }
    return FeedType.video;
  }

  String get stringFromEnum {
    if (this == FeedType.image) {
      return 'Image';
    }
    return 'Video';
  }
}

enum PaymentStatus {
  panding,
  // purchased,
  restore,
  none,
}
