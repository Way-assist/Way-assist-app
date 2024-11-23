import 'package:wayassist/features/main/main.dart';

import 'package:flutter/material.dart';
import 'package:line_icons/line_icons.dart';
import 'package:persistent_bottom_nav_bar/persistent_bottom_nav_bar.dart';

class MainScreen extends StatefulWidget {
  final Widget? child;

  const MainScreen({super.key, this.child});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final PersistentTabController _controller =
      PersistentTabController(initialIndex: 0);

  List<Widget> _buildScreens() {
    return [
      HomeView(),
      FavoriteView(),
      HelpView(),
      SettingsView(),
    ];
  }

  List<PersistentBottomNavBarItem> _navBarsItems() {
    final colors = Theme.of(context).colorScheme;
    return [
      PersistentBottomNavBarItem(
        icon: Icon(LineIcons.home),
        title: "Inicio",
        activeColorPrimary: colors.primary,
        inactiveColorPrimary: Colors.grey,
      ),
      PersistentBottomNavBarItem(
        icon: Icon(LineIcons.star),
        title: "Favoritos",
        activeColorPrimary: colors.primary,
        inactiveColorPrimary: Colors.grey,
      ),
      PersistentBottomNavBarItem(
        icon: Icon(LineIcons.infoCircle),
        title: "Ayuda",
        activeColorPrimary: colors.primary,
        inactiveColorPrimary: Colors.grey,
      ),
      PersistentBottomNavBarItem(
        icon: Icon(LineIcons.user),
        title: "Perfil",
        activeColorPrimary: colors.primary,
        inactiveColorPrimary: Colors.grey,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Stack(
      children: [
        PersistentTabView(
          context,
          controller: _controller,
          screens: _buildScreens(),
          items: _navBarsItems(),
          backgroundColor: colors.surface,
          handleAndroidBackButtonPress: true,
          resizeToAvoidBottomInset: true,
          stateManagement: true,
          hideNavigationBarWhenKeyboardAppears: true,
          navBarStyle: NavBarStyle.style3,
        ),
        if (widget.child != null) widget.child!,
      ],
    );
  }
}
