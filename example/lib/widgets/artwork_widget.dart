import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_browser/media_browser.dart';
import '../services/image_cache_service.dart';

/// Widget for displaying artwork with caching and async loading
class ArtworkWidget extends StatefulWidget {
  final int id;
  final ArtworkType type;
  final ArtworkSize size;
  final double? width;
  final double? height;
  final Widget? placeholder;
  final Widget? errorWidget;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  const ArtworkWidget({
    super.key,
    required this.id,
    required this.type,
    this.size = ArtworkSize.medium,
    this.width,
    this.height,
    this.placeholder,
    this.errorWidget,
    this.fit = BoxFit.cover,
    this.borderRadius,
  });

  @override
  State<ArtworkWidget> createState() => _ArtworkWidgetState();
}

class _ArtworkWidgetState extends State<ArtworkWidget> {
  final ImageCacheService _cacheService = ImageCacheService();
  Uint8List? _imageBytes;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadArtwork();
  }

  @override
  void didUpdateWidget(ArtworkWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.id != widget.id ||
        oldWidget.type != widget.type ||
        oldWidget.size != widget.size) {
      _loadArtwork();
    }
  }

  Future<void> _loadArtwork() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final bytes = await _cacheService.getCachedArtworkBytes(
        widget.id,
        widget.type,
        size: widget.size,
      );

      if (mounted) {
        setState(() {
          _imageBytes = bytes;
          _isLoading = false;
          _hasError = bytes == null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildPlaceholder();
    }

    if (_hasError || _imageBytes == null) {
      return _buildErrorWidget();
    }

    return ClipRRect(
      borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
      child: Image.memory(
        _imageBytes!,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        errorBuilder: (context, error, stackTrace) {
          return _buildErrorWidget();
        },
      ),
    );
  }

  Widget _buildPlaceholder() {
    if (widget.placeholder != null) {
      return widget.placeholder!;
    }

    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
      ),
      child: const Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white54),
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    if (widget.errorWidget != null) {
      return widget.errorWidget!;
    }

    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
      ),
      child: Icon(
        _getDefaultIcon(),
        color: Colors.white54,
        size: (widget.width != null && widget.height != null)
            ? (widget.width! < widget.height!
                ? widget.width! * 0.4
                : widget.height! * 0.4)
            : 40,
      ),
    );
  }

  IconData _getDefaultIcon() {
    switch (widget.type) {
      case ArtworkType.audio:
      case ArtworkType.album:
        return Icons.album;
      case ArtworkType.video:
        return Icons.video_library;
      case ArtworkType.artist:
        return Icons.person;
      case ArtworkType.genre:
        return Icons.category;
      default:
        return Icons.image;
    }
  }
}

/// Circular artwork widget for albums and artists
class CircularArtworkWidget extends StatelessWidget {
  final int id;
  final ArtworkType type;
  final ArtworkSize size;
  final double radius;
  final Widget? placeholder;
  final Widget? errorWidget;

  const CircularArtworkWidget({
    super.key,
    required this.id,
    required this.type,
    this.size = ArtworkSize.medium,
    this.radius = 40,
    this.placeholder,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: ArtworkWidget(
        id: id,
        type: type,
        size: size,
        width: radius * 2,
        height: radius * 2,
        placeholder: placeholder,
        errorWidget: errorWidget,
        fit: BoxFit.cover,
      ),
    );
  }
}
