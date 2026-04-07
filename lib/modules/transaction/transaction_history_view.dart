import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:FitStart/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:FitStart/features/auth/presentation/bloc/auth_event.dart';
import 'package:FitStart/features/auth/presentation/bloc/auth_state.dart';
import 'package:FitStart/modules/transaction/tab_history_view.dart';
import 'package:FitStart/modules/transaction/tab_order_view.dart';
import 'package:FitStart/services/guest_mode_service.dart';
import 'package:FitStart/services/google_auth_service.dart';
import 'package:FitStart/theme.dart';

class TransactionHistoryView extends StatefulWidget {
  final int initialTab;

  const TransactionHistoryView({Key? key, this.initialTab = 0})
      : super(key: key);

  @override
  State<TransactionHistoryView> createState() => _TransactionHistoryViewState();
}

class _TransactionHistoryViewState extends State<TransactionHistoryView>
    with TickerProviderStateMixin {
  late TabController _tabController;
  bool _isGuestMode = false;
  bool _isGuestLoading = true;
  bool _isSigningIn = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab,
    );
    _loadGuestMode();
  }

  Future<void> _handleGuestGoogleSignIn() async {
    if (_isSigningIn) return;

    setState(() {
      _isSigningIn = true;
    });

    try {
      final googleResult = await GoogleAuthService.signInWithGoogle();

      if (!mounted) return;

      if (googleResult['success'] == true) {
        context.read<AuthBloc>().add(
              GoogleSignInEvent(idToken: googleResult['idToken']),
            );
      } else {
        setState(() {
          _isSigningIn = false;
        });

        final error = googleResult['error'] as String?;
        if (error != null && error != 'Sign in Cancelled') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error), backgroundColor: Colors.red),
          );
        }
      }
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _isSigningIn = false;
      });
    }
  }

  Future<void> _loadGuestMode() async {
    final isGuest = await GuestModeService.isGuestMode();
    if (!mounted) return;

    setState(() {
      _isGuestMode = isGuest;
      _isGuestLoading = false;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) async {
        if (!_isSigningIn) return;

        if (state is Authenticated || state is AuthSuccess) {
          await GuestModeService.exitGuestMode();
          if (!mounted) return;

          setState(() {
            _isGuestMode = false;
            _isSigningIn = false;
          });
        } else if (state is AuthError) {
          if (!mounted) return;

          setState(() {
            _isSigningIn = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.red),
          );
        }
      },
      child: _isGuestLoading
          ? const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            )
          : _isGuestMode
              ? Scaffold(
                  backgroundColor: backgroundColor,
                  appBar: AppBar(
                    toolbarHeight: kTextTabBarHeight + 20,
                    title: Text(
                      'Transaction',
                      style: titleTextStyle,
                    ),
                    backgroundColor: backgroundColor,
                    elevation: 0.0,
                    centerTitle: true,
                  ),
                  body: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.lock_outline,
                            size: 72,
                            color: primaryColor500,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Sign in required',
                            style: titleTextStyle,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Transactions are not available in guest mode. Continue with Google to view orders and payment history.',
                            textAlign: TextAlign.center,
                            style: descTextStyle,
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton.icon(
                              onPressed: _isSigningIn
                                  ? null
                                  : _handleGuestGoogleSignIn,
                              icon: Image.asset(
                                'assets/icons/google_logo.png',
                                height: 22,
                                width: 22,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(Icons.g_mobiledata,
                                        color: Colors.white),
                              ),
                              label: Text(
                                _isSigningIn
                                    ? 'Signing in...'
                                    : 'Continue with Google',
                                style: buttonTextStyle.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF92C848),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(26),
                                ),
                                elevation: 0,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              : Scaffold(
                  backgroundColor: backgroundColor,
                  appBar: AppBar(
                    toolbarHeight: kTextTabBarHeight + 20,
                    title: Text(
                      "Transaction",
                      style: titleTextStyle,
                    ),
                    backgroundColor: backgroundColor,
                    elevation: 0.0,
                    centerTitle: true,
                    bottom: PreferredSize(
                      preferredSize: const Size.fromHeight(60),
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: colorWhite,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: TabBar(
                          controller: _tabController,
                          indicator: BoxDecoration(
                            color: primaryColor500,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          indicatorSize: TabBarIndicatorSize.tab,
                          dividerColor: Colors.transparent,
                          labelStyle: tabBarTextStyle.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                          unselectedLabelStyle: tabBarTextStyle.copyWith(
                            fontWeight: FontWeight.w500,
                            fontSize: 15,
                          ),
                          labelColor: colorWhite,
                          unselectedLabelColor: textSecondary,
                          tabs: const [
                            Tab(
                              text: "📋 Order",
                              height: 44,
                            ),
                            Tab(
                              text: "📜 History",
                              height: 44,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  body: TabBarView(
                    controller: _tabController,
                    children: const [
                      OrderView(),
                      TabHistoryView(),
                    ],
                  ),
                ),
    );
  }
}
