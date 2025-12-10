import 'package:flutter/material.dart';
import 'package:upsglam_mobile/views/auth/login_view.dart';
import 'package:upsglam_mobile/views/auth/register_view.dart';
import 'package:upsglam_mobile/views/auth/splash_screen.dart';
import 'package:upsglam_mobile/views/create_post/filter_selection_view.dart';
import 'package:upsglam_mobile/views/create_post/publish_post_view.dart';
import 'package:upsglam_mobile/views/create_post/select_image_view.dart';
import 'package:upsglam_mobile/views/feed/comments_view.dart';
import 'package:upsglam_mobile/views/feed/feed_view.dart';
import 'package:upsglam_mobile/views/profile/edit_profile_view.dart';
import 'package:upsglam_mobile/views/profile/profile_view.dart';
import 'package:upsglam_mobile/views/settings/settings_view.dart';
import 'package:upsglam_mobile/views/setup/gateway_setup_view.dart';

class AppRouter {
  const AppRouter._();

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case SplashScreen.routeName:
        return _material(const SplashScreen());
      case LoginView.routeName:
        return _material(const LoginView());
      case RegisterView.routeName:
        return _material(const RegisterView());
      case FeedView.routeName:
        return _material(const FeedView());
      case CommentsView.routeName:
        return _material(const CommentsView());
      case SelectImageView.routeName:
        return _material(const SelectImageView());
      case FilterSelectionView.routeName:
        return _material(const FilterSelectionView());
      case PublishPostView.routeName:
        return _material(const PublishPostView());
      case ProfileView.routeName:
        return _material(const ProfileView());
      case EditProfileView.routeName:
        return _material(const EditProfileView());
      case SettingsView.routeName:
        return _material(const SettingsView());
      case GatewaySetupView.routeName:
        return _material(const GatewaySetupView());
      default:
        return _material(const SplashScreen());
    }
  }

  static MaterialPageRoute<dynamic> _material(Widget child) =>
      MaterialPageRoute<dynamic>(builder: (_) => child);
}
