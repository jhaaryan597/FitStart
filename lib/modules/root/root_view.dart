import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:FitStart/modules/home/home_view.dart';
import 'package:FitStart/modules/profile/profile_view.dart';
import 'package:FitStart/modules/transaction/transaction_history_view.dart';
import 'package:FitStart/modules/gym/gyms_view.dart';
import 'package:FitStart/theme.dart';
import 'package:FitStart/components/floating_chatbot.dart';

class RootView extends StatefulWidget {
  final int currentScreen;

  const RootView({Key? key, required this.currentScreen}) : super(key: key);

  @override
  State<RootView> createState() => _RootViewState();
}

class _RootViewState extends State<RootView> {
  int _currentIndex = 0;
  final screens = [
    HomeView(),
    GymsView(),
    TransactionHistoryView(),
    ProfileView(),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.currentScreen;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => await _onBackPressed(),
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          toolbarHeight: 0,
          systemOverlayStyle: const SystemUiOverlayStyle(
              statusBarColor: backgroundColor,
              statusBarIconBrightness: Brightness.dark),
        ),
        backgroundColor: backgroundColor,
        body: Stack(
          children: [
            screens[_currentIndex],
            // Floating AI Chatbot
            const FloatingChatbot(),
          ],
        ),
        bottomNavigationBar: CustomBottomNavBar(
          defaultSelectedIndex: _currentIndex,
          selectedItemIcon: const [
            "assets/icons/home_fill.png",
            "assets/icons/setup.png",
            "assets/icons/receipt_fill.png",
            "assets/icons/about_fill.png"
          ],
          unselectedItemIcon: const [
            "assets/icons/home_outlined.png",
            "assets/icons/setup.png",
            "assets/icons/receipt_outlined.png",
            "assets/icons/about_outlined.png"
          ],
          label: const ["Home", "Gyms", "Transaction", "Profile"],
          onChange: (val) {
            setState(() {
              _currentIndex = val;
            });
          },
        ),
      ),
    );
  }

  Future<bool> _onBackPressed() async {
    return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Exit the App'),
            content: const Text('Do you want to exit the application?'),
            actions: <Widget>[
              // const SizedBox(height: 16),
              TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('No')),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Yes'),
              ),
            ],
          ),
        ) ??
        false;
  }
}

class CustomBottomNavBar extends StatefulWidget {
  final int defaultSelectedIndex;
  final List<String> selectedItemIcon;
  final List<String> unselectedItemIcon;
  final List<String> label;
  final Function(int) onChange;

  const CustomBottomNavBar(
      {this.defaultSelectedIndex = 0,
      required this.selectedItemIcon,
      required this.unselectedItemIcon,
      required this.label,
      required this.onChange});

  @override
  State<CustomBottomNavBar> createState() => _CustomBottomNavBarState();
}

class _CustomBottomNavBarState extends State<CustomBottomNavBar> {
  int _selectedIndex = 0;
  List<String> _selectedItemIcon = [];
  List<String> _unselectedItemIcon = [];
  List<String> _label = [];

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.defaultSelectedIndex;
    _selectedItemIcon = widget.selectedItemIcon;
    _unselectedItemIcon = widget.unselectedItemIcon;
    _label = widget.label;
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> _navBarItems = [];

    for (int i = 0; i < _selectedItemIcon.length; i++) {
      _navBarItems.add(Expanded(
        child: bottomNavBarItem(
            _selectedItemIcon[i], _unselectedItemIcon[i], _label[i], i),
      ));
    }
    return SafeArea(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: colorBlack,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.max,
          children: _navBarItems,
        ),
      ),
    );
  }

  Widget bottomNavBarItem(String activeIcon, String inactiveIcon, String label, int index) {
    return GestureDetector(
      onTap: () {
        widget.onChange(index);
        setState(() {
          _selectedIndex = index;
        });
      },
      child: Container(
        height: 60,
        decoration: const BoxDecoration(
          color: Colors.transparent,
        ),
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            padding: _selectedIndex == index
                ? const EdgeInsets.symmetric(horizontal: 12, vertical: 8)
                : const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _selectedIndex == index
                  ? neonGreen.withOpacity(0.15)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: _selectedIndex == index
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        activeIcon,
                        width: 22,
                        height: 22,
                        color: neonGreen,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          label,
                          style: bottomNavTextStyle.copyWith(
                            color: neonGreen,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  )
                : Image.asset(
                    inactiveIcon,
                    width: 22,
                    height: 22,
                    color: lightGray,
                  ),
          ),
        ),
      ),
    );
  }
}
