import 'package:flutter/material.dart';
import '../../../core/theme/tigo_colors.dart';
import '../data/tigo_items.dart';
import '../models/tigo_model.dart';

class TigoAvatar extends StatelessWidget {
  final double size;
  final Map<TigoSlot, String> equipped;
  final bool showBase;

  const TigoAvatar({
    super.key,
    required this.size,
    required this.equipped,
    this.showBase = true,
  });

  @override
  Widget build(BuildContext context) {
    final equippedItems = kTigoItems
        .where((item) => equipped[item.slot] == item.id)
        .toList()
      ..sort((a, b) => a.zIndex.compareTo(b.zIndex));

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          if (showBase)
            _AssetLayer(
              assetPath: 'assets/tigo/base/tigo_base_front.png',
              size: size,
            ),
          for (final item in equippedItems)
            _AssetLayer(assetPath: item.asset, size: size),
        ],
      ),
    );
  }
}

class _AssetLayer extends StatelessWidget {
  final String assetPath;
  final double size;

  const _AssetLayer({required this.assetPath, required this.size});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      assetPath,
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => _PlaceholderLayer(size: size),
    );
  }
}

class _PlaceholderLayer extends StatelessWidget {
  final double size;
  const _PlaceholderLayer({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: TigoColors.cream,
        borderRadius: BorderRadius.circular(size * 0.15),
        border: Border.all(color: TigoColors.orangeSoft, width: 2),
      ),
      child: Center(
        child: Icon(
          Icons.pets,
          size: size * 0.4,
          color: TigoColors.orange,
        ),
      ),
    );
  }
}
