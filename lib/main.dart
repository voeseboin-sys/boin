import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/core.dart';
import 'providers/providers.dart';
import 'screens/screens.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);

    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: auth.isAuthenticated ? const MainNavigationScreen() : const LoginScreen(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/productos': (context) => const ProductosScreen(),
        '/ventas': (context) => const VentasScreen(),
        '/nueva-venta': (context) => const NuevaVentaScreen(),
        '/produccion': (context) => const ProduccionScreen(),
        '/gastos': (context) => const GastosScreen(),
      },
    );
  }
}

class MainNavigationScreen extends ConsumerStatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  ConsumerState<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends ConsumerState<MainNavigationScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    
    // Definir pantallas según el rol
    final screens = <Widget>[
      const DashboardScreen(),
      const VentasScreen(),
      const ProductosScreen(),
      const ProduccionScreen(),
      if (auth.isDueno) const GastosScreen(),
    ];

    final navItems = <BottomNavigationBarItem>[
      const BottomNavigationBarItem(
        icon: Icon(Icons.dashboard_outlined),
        activeIcon: Icon(Icons.dashboard),
        label: 'Inicio',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.receipt_long_outlined),
        activeIcon: Icon(Icons.receipt_long),
        label: 'Ventas',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.inventory_2_outlined),
        activeIcon: Icon(Icons.inventory_2),
        label: 'Stock',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.precision_manufacturing_outlined),
        activeIcon: Icon(Icons.precision_manufacturing),
        label: 'Producción',
      ),
      if (auth.isDueno)
        const BottomNavigationBarItem(
          icon: Icon(Icons.account_balance_wallet_outlined),
          activeIcon: Icon(Icons.account_balance_wallet),
          label: 'Gastos',
        ),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: navItems,
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppTheme.surface,
        selectedItemColor: AppTheme.primaryColor,
        unselectedItemColor: AppTheme.textTertiary,
        selectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 12,
        ),
      ),
    );
  }
}
