import 'package:flutter/material.dart';
import 'package:FitStart/theme.dart';
import 'package:FitStart/utils/responsive_utils.dart';

/// Reusable loading indicator with responsive design
class LoadingIndicator extends StatelessWidget {
  final String? message;
  final Color? color;
  final double? size;

  const LoadingIndicator({
    Key? key,
    this.message,
    this.color,
    this.size,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: size ?? ResponsiveUtils.spacing(context, 40),
            height: size ?? ResponsiveUtils.spacing(context, 40),
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(
                color ?? primaryColor500,
              ),
            ),
          ),
          if (message != null) ...[
            SizedBox(height: ResponsiveUtils.spacing(context, 16)),
            Text(
              message!,
              style: descTextStyle.copyWith(
                fontSize: ResponsiveUtils.fontSize(context, 14),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

/// Full screen loading overlay
class LoadingOverlay extends StatelessWidget {
  final String? message;

  const LoadingOverlay({
    Key? key,
    this.message,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black54,
      child: LoadingIndicator(message: message),
    );
  }
}
