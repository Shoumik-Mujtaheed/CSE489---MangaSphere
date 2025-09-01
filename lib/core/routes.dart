import 'package:flutter/material.dart';
import '../pages/auth/login_page.dart';
import '../pages/auth/signup_page.dart';
import '../pages/home/home_page.dart';
import '../pages/profile/profile_page.dart';

class AppRoutes {
static const login = '/login';
static const signup = '/signup';
static const home = '/home';
static const reader = '/reader';
static const profile = '/profile';

static Map<String, WidgetBuilder> map = {
login: (context) => const LoginPage(),
signup: (context) => const SignupPage(),
home: (context) => const HomePage(),
profile: (context) => const ProfilePage(),
};
}