import 'package:flutter/material.dart';

import 'pages/home_page.dart';

class Se4XApp extends StatelessWidget {
  const Se4XApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SE4X Companion',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF1E1E1E),
        colorScheme: const ColorScheme.dark(
          surface: Color(0xFF1E1E1E),
          surfaceContainerHighest: Color(0xFF2A2A2A),
          primary: Color(0xFF8AB4F8),
          secondary: Color(0xFF78909C),
          error: Color(0xFFCF6679),
          onSurface: Color(0xFFDADADA),
          onPrimary: Color(0xFF1E1E1E),
        ),
        dividerColor: const Color(0xFF3A3A3A),
        cardColor: const Color(0xFF252525),
        visualDensity: VisualDensity.compact,
        fontFamily: 'Roboto',
        textTheme: const TextTheme(
          bodyLarge: TextStyle(fontSize: 13, color: Color(0xFFDADADA)),
          bodyMedium: TextStyle(fontSize: 12, color: Color(0xFFDADADA)),
          bodySmall: TextStyle(fontSize: 11, color: Color(0xFFAAAAAA)),
          titleMedium: TextStyle(fontSize: 14, color: Color(0xFFDADADA)),
          labelLarge: TextStyle(fontSize: 12, color: Color(0xFFDADADA)),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF252525),
          foregroundColor: Color(0xFFDADADA),
          elevation: 0,
          titleTextStyle: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFFDADADA),
          ),
          toolbarHeight: 40,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Color(0xFF252525),
          selectedItemColor: Color(0xFF8AB4F8),
          unselectedItemColor: Color(0xFF777777),
          selectedLabelStyle: TextStyle(fontSize: 10),
          unselectedLabelStyle: TextStyle(fontSize: 10),
          type: BottomNavigationBarType.fixed,
        ),
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const Color(0xFF8AB4F8);
            }
            return const Color(0xFF777777);
          }),
          trackColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const Color(0xFF8AB4F8).withValues(alpha: 0.3);
            }
            return const Color(0xFF444444);
          }),
        ),
        inputDecorationTheme: const InputDecorationTheme(
          isDense: true,
          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          border: OutlineInputBorder(),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Color(0xFF3A3A3A)),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Color(0xFF8AB4F8)),
          ),
        ),
        dialogTheme: const DialogThemeData(
          backgroundColor: Color(0xFF2A2A2A),
          titleTextStyle: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Color(0xFFDADADA),
          ),
          contentTextStyle: TextStyle(
            fontSize: 13,
            color: Color(0xFFBBBBBB),
          ),
        ),
        listTileTheme: const ListTileThemeData(
          dense: true,
          visualDensity: VisualDensity.compact,
          contentPadding: EdgeInsets.symmetric(horizontal: 12),
        ),
        chipTheme: const ChipThemeData(
          backgroundColor: Color(0xFF2A2A2A),
          labelStyle: TextStyle(fontSize: 11, color: Color(0xFFDADADA)),
          side: BorderSide(color: Color(0xFF3A3A3A)),
          padding: EdgeInsets.symmetric(horizontal: 4),
        ),
      ),
      home: const HomePage(),
    );
  }
}
