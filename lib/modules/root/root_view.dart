import 'dart:ui';
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
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.currentScreen;
    // Initialize screens once and reuse them
    _screens = [
      HomeView(),
      GymsView(),
      TransactionHistoryView(),
      ProfileView(),
    ];
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
            IndexedStack(
              index: _currentIndex,
              children: _screens,
            ),
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
    
    final screenWidth = MediaQuery.of(context).size.width - 32; // minus horizontal margin
    final itemWidth = screenWidth / _selectedItemIcon.length;
    final indicatorWidth = 40.0;
    final indicatorLeft = (_selectedIndex * itemWidth) + (itemWidth / 2) - (indicatorWidth / 2);
    
    return SafeArea(
      child: GestureDetector(
        onHorizontalDragEnd: (details) {
          // Get the last known position from the drag
          final RenderBox? box = context.findRenderObject() as RenderBox?;
          if (box == null) return;
          
          // Switch screen only when finger is lifted
          widget.onChange(_selectedIndex);
        },
        onHorizontalDragUpdate: (details) {
          // Calculate which tab is under the finger
          final RenderBox box = context.findRenderObject() as RenderBox;
          final localPosition = box.globalToLocal(details.globalPosition);
          final relativePosX = localPosition.dx - 16; // Account for margin
          
          if (relativePosX >= 0 && relativePosX <= screenWidth) {
            final newIndex = (relativePosX ~/ itemWidth).clamp(0, _selectedItemIcon.length - 1);
            if (newIndex != _selectedIndex) {
              setState(() {
                _selectedIndex = newIndex;
              });
            }
          }
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: neonGreen.withOpacity(0.2),
                blurRadius: 30,
                offset: const Offset(0, 10),
                spreadRadius: -5,
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(25),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      colorBlack.withOpacity(0.85),
                      colorBlack.withOpacity(0.75),
                    ],
                  ),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Stack(
              children: [
                // Animated glow indicator
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  bottom: 0,
                  left: indicatorLeft - 10,
                  child: Container(
                    width: indicatorWidth + 20,
                    height: 4,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          neonGreen.withOpacity(0.8),
                          neonGreen,
                          neonGreen.withOpacity(0.8),
                          Colors.transparent,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(2),
                      boxShadow: [
                        BoxShadow(
                          color: neonGreen.withOpacity(0.5),
                          blurRadius: 15,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ),
                // Nav bar items
                Row(
                  mainAxisSize: MainAxisSize.max,
                  children: _navBarItems,
                ),
              ],
            ),
          ),
        ),
        ),
        ),
      ),
    );
  }

  Widget bottomNavBarItem(String activeIcon, String inactiveIcon, String label, int index) {
    final isSelected = _selectedIndex == index;
    
    return GestureDetector(
      onTap: () {
        if (_selectedIndex == index) return;
        widget.onChange(index);
        setState(() {
          _selectedIndex = index;
        });
      },
      child: Container(
        height: 60,
        color: Colors.transparent,
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSelected
                  ? neonGreen.withOpacity(0.15)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Image.asset(
              isSelected ? activeIcon : inactiveIcon,
              width: 24,
              height: 24,
              color: isSelected ? neonGreen : lightGray,
            ),
          ),
        ),
      ),
    );
  }
}