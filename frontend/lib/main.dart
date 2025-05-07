
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:flutter_dotenv/flutter_dotenv.dart';
// import 'package:flutter_localizations/flutter_localizations.dart';

// import 'providers/auth_provider.dart';
// import 'providers/project_provider.dart';
// import 'providers/issue_provider.dart';
// import 'providers/notification_provider.dart';
// import 'screens/splash_screen.dart';
// import 'screens/login_screen.dart';
// import 'screens/register_screen.dart';
// import 'screens/dashboard_screen.dart';
// import 'screens/notifications_screen.dart';
// import 'screens/issue_detail_screen.dart';
// import 'utils/app_theme.dart';

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   await dotenv.load(fileName: ".env");
//   runApp(const MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MultiProvider(
//       providers: [
//         ChangeNotifierProvider(create: (_) => AuthProvider()),
//         ChangeNotifierProxyProvider<AuthProvider, ProjectProvider>(
//           create: (_) => ProjectProvider(null),
//           update: (_, auth, previous) => ProjectProvider(
//             auth.token,
//             previousProjects: previous?.projects ?? [],
//           ),
//         ),
//         ChangeNotifierProxyProvider<AuthProvider, IssueProvider>(
//           create: (_) => IssueProvider(null),
//           update: (_, auth, previous) => IssueProvider(
//             auth.token,
//             previousIssues: previous?.issues ?? [],
//           ),
//         ),
//         ChangeNotifierProxyProvider<AuthProvider, NotificationProvider>(
//           create: (_) => NotificationProvider(null),
//           update: (_, auth, previous) => NotificationProvider(
//             auth.token,
//             previousNotifications: previous?.notifications ?? [],
//           ),
//         ),
//       ],
//       child: Consumer<AuthProvider>(
//         builder: (ctx, auth, _) => MaterialApp(
//           title: 'Project Management App',
//           theme: AppTheme.lightTheme,
//           darkTheme: AppTheme.darkTheme,
//           themeMode: ThemeMode.system,
//           home: auth.isLoading
//               ? const SplashScreen()
//               : auth.isAuth
//                   ? const DashboardScreen()
//                   : const LoginScreen(),
//           routes: {
//             LoginScreen.routeName: (ctx) => const LoginScreen(),
//             RegisterScreen.routeName: (ctx) => const RegisterScreen(),
//             DashboardScreen.routeName: (ctx) => const DashboardScreen(),
//             NotificationsScreen.routeName: (ctx) => const NotificationsScreen(),
//             IssueDetailScreen.routeName: (ctx) {
//               final args = ModalRoute.of(ctx)!.settings.arguments as Map<String, dynamic>;
//               return IssueDetailScreen(
//                 projectId: args['projectId'],
//                 issueId: args['issueId'],
//               );
//             },
//           },
//           supportedLocales: const [Locale('en', ''), Locale('fr', '')],
//           localizationsDelegates: const [
//             GlobalMaterialLocalizations.delegate,
//             GlobalWidgetsLocalizations.delegate,
//             GlobalCupertinoLocalizations.delegate,
//           ],
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'providers/auth_provider.dart';
import 'providers/project_provider.dart';
import 'providers/issue_provider.dart';
import 'providers/notification_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/issue_detail_screen.dart';
import 'utils/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProxyProvider<AuthProvider, ProjectProvider>(
          create: (_) => ProjectProvider(null),
          update: (_, auth, previous) => ProjectProvider(
            auth.token,
            previousProjects: previous?.projects ?? [],
          ),
        ),
        ChangeNotifierProxyProvider2<AuthProvider, ProjectProvider, IssueProvider>(
          create: (_) => IssueProvider(null),
          update: (_, auth, projectProvider, previous) {
            // Create a new IssueProvider but preserve the previous issues
            return IssueProvider(
              auth.token,
              projectProvider: projectProvider,
              previousIssues: previous?.issues ?? [],
            );
          },
        ),
        ChangeNotifierProxyProvider<AuthProvider, NotificationProvider>(
          create: (_) => NotificationProvider(null),
          update: (_, auth, previous) => NotificationProvider(
            auth.token,
            previousNotifications: previous?.notifications ?? [],
          ),
        ),
      ],
      child: Consumer<AuthProvider>(
        builder: (ctx, auth, _) => MaterialApp(
          title: 'Project Management App',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.system,
          home: auth.isLoading
              ? const SplashScreen()
              : auth.isAuth
                  ? const DashboardScreen()
                  : const LoginScreen(),
          routes: {
            LoginScreen.routeName: (ctx) => const LoginScreen(),
            RegisterScreen.routeName: (ctx) => const RegisterScreen(),
            DashboardScreen.routeName: (ctx) => const DashboardScreen(),
            NotificationsScreen.routeName: (ctx) => const NotificationsScreen(),
            IssueDetailScreen.routeName: (ctx) {
              final args = ModalRoute.of(ctx)!.settings.arguments as Map<String, dynamic>;
              return IssueDetailScreen(
                projectId: args['projectId'],
                issueId: args['issueId'],
              );
            },
          },
          supportedLocales: const [Locale('en', ''), Locale('fr', '')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
        ),
      ),
    );
  }
}

// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:flutter_dotenv/flutter_dotenv.dart';
// import 'package:flutter_localizations/flutter_localizations.dart';

// import 'providers/auth_provider.dart';
// import 'providers/project_provider.dart';
// import 'providers/issue_provider.dart';
// import 'providers/notification_provider.dart';
// import 'screens/splash_screen.dart';
// import 'screens/login_screen.dart';
// import 'screens/register_screen.dart';
// import 'screens/dashboard_screen.dart';
// import 'screens/notifications_screen.dart';
// import 'screens/issue_detail_screen.dart';
// import 'utils/app_theme.dart';

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   await dotenv.load(fileName: ".env");
//   runApp(const MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MultiProvider(
//       providers: [
//         ChangeNotifierProvider(create: (_) => AuthProvider()),
//         ChangeNotifierProxyProvider<AuthProvider, ProjectProvider>(
//           create: (_) => ProjectProvider(null),
//           update: (_, auth, previous) => ProjectProvider(
//             auth.token,
//             previousProjects: previous?.projects ?? [],
//           ),
//         ),
//         ChangeNotifierProxyProvider2<AuthProvider, ProjectProvider, IssueProvider>(
//           create: (_) => IssueProvider(null),
//           update: (_, auth, projectProvider, previous) => IssueProvider(
//             auth.token,
//             projectProvider: projectProvider,
//             previousIssues: previous?.issues ?? [],
//           ),
//         ),
//         ChangeNotifierProxyProvider<AuthProvider, NotificationProvider>(
//           create: (_) => NotificationProvider(null),
//           update: (_, auth, previous) => NotificationProvider(
//             auth.token,
//             previousNotifications: previous?.notifications ?? [],
//           ),
//         ),
//       ],
//       child: Consumer<AuthProvider>(
//         builder: (ctx, auth, _) => MaterialApp(
//           title: 'Project Management App',
//           theme: AppTheme.lightTheme,
//           darkTheme: AppTheme.darkTheme,
//           themeMode: ThemeMode.system,
//           home: auth.isLoading
//               ? const SplashScreen()
//               : auth.isAuth
//                   ? const DashboardScreen()
//                   : const LoginScreen(),
//           routes: {
//             LoginScreen.routeName: (ctx) => const LoginScreen(),
//             RegisterScreen.routeName: (ctx) => const RegisterScreen(),
//             DashboardScreen.routeName: (ctx) => const DashboardScreen(),
//             NotificationsScreen.routeName: (ctx) => const NotificationsScreen(),
//             IssueDetailScreen.routeName: (ctx) {
//               final args = ModalRoute.of(ctx)!.settings.arguments as Map<String, dynamic>;
//               return IssueDetailScreen(
//                 projectId: args['projectId'],
//                 issueId: args['issueId'],
//               );
//             },
//           },
//           supportedLocales: const [Locale('en', ''), Locale('fr', '')],
//           localizationsDelegates: const [
//             GlobalMaterialLocalizations.delegate,
//             GlobalWidgetsLocalizations.delegate,
//             GlobalCupertinoLocalizations.delegate,
//           ],
//         ),
//       ),
//     );
//   }
// }