import 'package:flutter/material.dart';
import 'package:FitStart/theme.dart';
import 'package:FitStart/utils/responsive_utils.dart';

/// Reusable user header widget with profile and notification
class UserHeader extends StatelessWidget {
  final String? username;
  final String? profileImageUrl;
  final VoidCallback? onNotificationTap;
  final ImageProvider Function()? getProfileImageProvider;
  final int unreadCount;

  const UserHeader({
    Key? key,
    this.username,
    this.profileImageUrl,
    this.onNotificationTap,
    this.getProfileImageProvider,
    this.unreadCount = 0,
  }) : super(key: key);

  ImageProvider _defaultProfileImageProvider() {
    if (profileImageUrl != null && profileImageUrl!.isNotEmpty) {
      if (profileImageUrl!.startsWith('assets/')) {
        return AssetImage(profileImageUrl!);
      } else {
        return NetworkImage(profileImageUrl!);
      }
    }
    return const AssetImage("assets/images/profile_male.jpg");
  }

  @override
  Widget build(BuildContext context) {
    final avatarSize = ResponsiveUtils.responsive(
      context: context,
      mobile: 55.0,
      tablet: 65.0,
      desktop: 75.0,
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          children: [
            Container(
              width: avatarSize,
              height: avatarSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                image: DecorationImage(
                  fit: BoxFit.cover,
                  image: getProfileImageProvider != null
                      ? getProfileImageProvider!()
                      : _defaultProfileImageProvider(),
                ),
              ),
            ),
            SizedBox(width: ResponsiveUtils.spacing(context, 16)),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Welcome back,",
                  style: descTextStyle.copyWith(
                    fontSize: ResponsiveUtils.fontSize(context, 14),
                  ),
                ),
                SizedBox(height: ResponsiveUtils.spacing(context, 4)),
                Text(
                  username ?? 'No username',
                  style: subTitleTextStyle.copyWith(
                    fontSize: ResponsiveUtils.fontSize(context, 16),
                  ),
                ),
              ],
            ),
          ],
        ),
        // Notification Bell with Badge
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              decoration: BoxDecoration(
                color: primaryColor500,
                borderRadius: BorderRadius.circular(borderRadiusSize),
              ),
              child: IconButton(
                onPressed: onNotificationTap,
                icon: Icon(
                  Icons.notifications_outlined,
                  color: colorWhite,
                  size: ResponsiveUtils.spacing(context, 24),
                ),
              ),
            ),
            if (unreadCount > 0)
              Positioned(
                right: 6,
                top: 6,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: primaryColor500,
                      width: 2,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
