import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const Color mWhite = Color(0xffffffff);
const Color mGrey = Color(0xff9397a0);
const Color kLightGrey = Color(0xffa7a7a7);
const Color mBlack = Color.fromARGB(255, 0, 0, 0);

const Color mPurple = Color.fromRGBO(185, 80, 255, 1);
const Color mDarkpurple = Color.fromRGBO(140, 0, 255, 1);
const Color mLightPurple = Color.fromRGBO(196, 116, 246, 1);

const double mBorderRadius = 16.0;

final ButtonStyle buttonOutlinedWhite = OutlinedButton.styleFrom(
  foregroundColor: mWhite, minimumSize: const Size(200, 60),
  elevation: 0,
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(mBorderRadius),),
  ),
  side: const BorderSide(width: 3,color: mWhite,)
);

final ButtonStyle buttonOutlinedDarkpurple = OutlinedButton.styleFrom(
  foregroundColor: mWhite, minimumSize: const Size(200, 60),
  elevation: 0,
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(mBorderRadius),),
  ),
  side: const BorderSide(width: 3,color: mDarkpurple,)
);

final ButtonStyle buttonWhite = ElevatedButton.styleFrom(
  minimumSize: const Size(200, 60), 
  backgroundColor: mWhite,
  elevation: 0,
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(mBorderRadius),),
  ),
);

final ButtonStyle buttonDarkpurple = ElevatedButton.styleFrom(
  minimumSize: const Size(200, 60), 
  backgroundColor: mDarkpurple,
  elevation: 0,
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(mBorderRadius),),
  ),
);

final mBorder = OutlineInputBorder(
  borderRadius: BorderRadius.circular(mBorderRadius),
  borderSide: BorderSide.none,
);

final mExtraBold = GoogleFonts.poppins(
  color: Colors.black,
  fontWeight: FontWeight.w800,
);

final mBold = GoogleFonts.poppins(
  color: Colors.black,
  fontWeight: FontWeight.w700,
);

final mSemibold = GoogleFonts.poppins(
  color: Colors.black,
  fontWeight: FontWeight.w600,
);

final mMedium = GoogleFonts.poppins(
  color: Colors.black,
  fontWeight: FontWeight.w500,
);

final mRegular = GoogleFonts.poppins(
  color: Colors.black,
  fontWeight: FontWeight.w400,
);
