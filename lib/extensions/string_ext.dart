// ignore_for_file: prefer_asset_extension
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

extension AssetExt on String {
  SvgPicture toSvg({
    Key? key,
    double? size,
    Color? color,
    BoxFit fit = .contain,
  }) => SvgPicture.asset(
    key: key,
    this,
    height: size,
    width: size,
    color: color,
    fit: fit,
  );

  Image toImage({
    Key? key,
    double? width,
    double? height,
    BoxFit fit = .contain,
  }) => Image.asset(key: key, this, height: height, width: width, fit: fit);

  Widget toCachedImg({double? width, double? height, BoxFit fit = .contain}) {
    if (isEmpty) {
      return _errorPlaceholder(width, height, fit);
    }
    return CachedNetworkImage(
      imageUrl: this,
      width: width,
      height: height,
      fit: fit,
      filterQuality: .medium,
      progressIndicatorBuilder: (context, url, downloadProgress) {
        final progress = (downloadProgress.progress ?? 0) * 100;
        return Container(
          color: const Color(0xFF818181).withOpacity(0.2),
          width: width,
          height: height,
          alignment: .center,
          child: Stack(
            alignment: .center,
            children: [
              CircularProgressIndicator(
                value: downloadProgress.progress,
                strokeWidth: 2,
              ),
              Positioned(child: Text("${progress.toStringAsFixed(0)}%")),
            ],
          ),
        );
      },

      errorWidget: (_, _, _) => _errorPlaceholder(width, height, fit),
    );
  }

  Widget _errorPlaceholder(double? width, double? height, BoxFit fit) {
    return Container(
      color: const Color(0xFF818181).withOpacity(0.2),
      width: width,
      height: height,
      child: Text('data'),
    );
  }
}
