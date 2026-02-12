import 'package:flutter/material.dart';

import '../modules/root/root_view.dart';
import '../theme.dart';

class NoTranscationMessage extends StatelessWidget {
  final String messageTitle;
  final String messageDesc;

  const NoTranscationMessage(
      {Key? key, required this.messageTitle, required this.messageDesc})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              height: 16,
            ),
            Image.asset(
              "assets/images/no_transaction_illustration.png",
              width: 150,
            ),
            const SizedBox(
              height: 8,
            ),
            Text(
              messageTitle,
              style: titleTextStyle.copyWith(color: darkBlue300),
            ),
            const SizedBox(
              height: 8.0,
            ),
            Text(
              messageDesc,
              style: descTextStyle,
              textAlign: TextAlign.center,
            ),
            const SizedBox(
              height: 32.0,
            ),
            TextButton.icon(
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                        builder: (context) => RootView(currentScreen: 0)),
                    (route) => false,
                  );
                },
                icon: const Icon(Icons.search),
                label: Text(
                  "Find a Sport Venue",
                  style: buttonTextStyle.copyWith(color: primaryColor500),
                ))
          ],
        ),
      ),
    );
  }
}
