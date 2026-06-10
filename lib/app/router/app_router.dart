import 'package:go_router/go_router.dart';

import '../../features/dictionary/presentation/pages/dictionary_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/translation/presentation/pages/sign_to_text_page.dart';
import '../../features/translation/presentation/pages/text_to_sign_page.dart';
import '../../features/camera/presentation/pages/camera_translate_page.dart';
import '../navigation/app_shell_page.dart';
import 'app_routes.dart';

abstract final class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: AppRoutePaths.home,
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShellPage(navigationShell: navigationShell),
        branches: [
          // Aba 0 — Início
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutePaths.home,
              name: AppRouteNames.home,
              builder: (context, state) => const HomePage(),
            ),
          ]),

          // Aba 1 — Texto → Libras (VLibras)
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutePaths.textToSign,
              name: AppRouteNames.textToSign,
              builder: (context, state) => const TextToSignPage(),
              routes: [
                GoRoute(
                  path: AppRoutePaths.signToText,
                  name: AppRouteNames.signToText,
                  builder: (context, state) => const SignToTextPage(),
                ),
              ],
            ),
          ]),

          // Aba 2 — Câmera → Texto (Claude AI)
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutePaths.camera,
              name: AppRouteNames.camera,
              builder: (context, state) => const CameraTranslatePage(),
            ),
          ]),

          // Aba 3 — Dicionário
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutePaths.dictionary,
              name: AppRouteNames.dictionary,
              builder: (context, state) => const DictionaryPage(),
            ),
          ]),
        ],
      ),
    ],
  );
}
