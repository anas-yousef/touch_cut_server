import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:dotenv/dotenv.dart';
import 'package:supabase/supabase.dart';
import 'package:touch_cut_server/src/auth/auth_repo.dart';
import 'package:touch_cut_server/src/file_storage.dart';

late AuthRepo authRepo;

Future<HttpServer> run(Handler handler, InternetAddress ip, int port) {
  final storage = FileStorage('supabase_auth.json');
  final env = DotEnv(includePlatformEnvironment: true)..load();
  final supabaseClient = SupabaseClient(
    env['SUPB_URL']!,
    // ignore: lines_longer_than_80_chars
    env['SUPB_SERVICE_ROLE']!, // This is only used in the server, not on the client side
    authOptions: AuthClientOptions(
      pkceAsyncStorage: storage,
    ),
  );
  authRepo = AuthRepo(supabaseClient: supabaseClient);
  return serve(handler, ip, port);
}
