import 'package:flutter/material.dart';

import '../../models/user_profile.dart';
import '../catalog/catalog_screen.dart';
import 'sign_up_screen.dart';

/// Where every successful sign-in leads. Accounts without a role (a first
/// Google sign-in, or a sign-up that failed half way) finish role setup
/// first; everyone else goes to the catalogue.
///
/// The log-in and sign-up screens are removed from the stack, but the welcome
/// screen stays underneath so the catalogue's Home tab can still go back.
void openHomeAfterSignIn(BuildContext context, UserProfile profile) {
  final Widget next;
  if (profile.role == null) {
    next = SignUpScreen(signedInProfile: profile);
  } else {
    final name =
        profile.displayName.isNotEmpty ? profile.displayName : profile.email;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Signed in as $name')),
    );
    next = const CatalogScreen();
  }

  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => next),
    (route) => route.isFirst,
  );
}
