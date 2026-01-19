// ignore_for_file: avoid_classes_with_only_static_members, constant_identifier_names, non_constant_identifier_names
import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
import 'colors.dart';
import 'dimensions.dart';

abstract class FontConstants {
  static const SFProFamily = 'Roboto';
}

abstract class AppFontTextStyles {
  //static TextStyle textBold = GoogleFonts.ibarraRealNova(
  static const TextStyle textBold = TextStyle(
    fontFamily: FontConstants.SFProFamily,
    fontWeight: FontWeight.bold,
    fontSize: Dimens.text_xxlarge,
    color: AppColors.white,
    overflow: TextOverflow.ellipsis,
  );

  static const TextStyle textNormal = TextStyle(
    fontFamily: FontConstants.SFProFamily,
    fontWeight: FontWeight.normal,
    fontSize: 17.0,
    color: AppColors.white,
    overflow: TextOverflow.ellipsis,
  );

  static const TextStyle textSemiBold = TextStyle(
    fontFamily: FontConstants.SFProFamily,
    fontWeight: FontWeight.w700,
    fontSize: 17.0,
    color: AppColors.white,
    overflow: TextOverflow.ellipsis,
  );

  static const TextStyle textPoppinsBold = TextStyle(
    fontFamily: FontConstants.SFProFamily,
    fontWeight: FontWeight.bold,
    fontSize: Dimens.text_xxlarge,
    color: AppColors.white,
    overflow: TextOverflow.ellipsis,
  );
}
/// for new code
class AppTextStyles {
  static const title = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const cardTitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );

  static const label = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
  );
}