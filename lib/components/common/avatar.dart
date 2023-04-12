import 'package:flutter/material.dart';
import 'package:flutter_v2ex/utils/utils.dart';
import 'package:cached_network_image/cached_network_image.dart';

class CAvatar extends StatelessWidget {
  final String url;
  final double size;
  final int radius = 50;
  final Duration? fadeOutDuration;
  final Duration? fadeInDuration;
  final String? quality;

  const CAvatar({
    Key? key,
    required this.url,
    required this.size,
    this.fadeOutDuration,
    this.fadeInDuration,
    this.quality,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return url != '' ? ClipOval(
      child: CachedNetworkImage(
        imageUrl: quality == 'origin' ? Utils().avatarLarge(url) : url,
        height: size,
        width: size,
        fit: BoxFit.cover,
        fadeOutDuration: fadeOutDuration ?? const Duration(milliseconds: 800),
        fadeInDuration: fadeInDuration ?? const Duration(milliseconds: 300),
        // progressIndicatorBuilder: (context, url, downloadProgress) =>
        //     CircularProgressIndicator(
        //   value: downloadProgress.progress,
        //   strokeWidth: 3,
        // ),
        errorWidget: (context, url, error) => errAvatar(context),
        placeholder: (context, url) => placeholder(context),
      ),
    ) : errAvatar(context);
  }

  Widget placeholder(context) {
    return
      Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onInverseSurface,
      ),
      clipBehavior: Clip.antiAlias,
      child: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.onInverseSurface,
          backgroundImage: const AssetImage('assets/images/avatar.png')),
    );
  }
  Widget errAvatar(context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(50),
      ),
      clipBehavior: Clip.antiAlias,
      width: size,
      height: size,
      child: Center(
        child: Icon(
          Icons.person_rounded,
          size: size - 10,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
