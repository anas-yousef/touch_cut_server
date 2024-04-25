import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_auth/dart_frog_auth.dart';
import 'package:supabase/supabase.dart';
import 'package:touch_cut_server/src/auth/auth_repo.dart';

Handler middleware(Handler handler) {
  return handler.use(requestLogger()).use(
    bearerAuthentication<User>(
      authenticator: (context, accessToken) async {
        final authenticator = context.read<AuthRepo>();
        return authenticator.verifyAccessToken(
          accessToken: accessToken,
        );
      },
    ),
  );
}
