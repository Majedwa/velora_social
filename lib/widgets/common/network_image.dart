// Modificación de lib/widgets/common/network_image.dart

import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:provider/provider.dart';
import '../../api/api_service.dart';

class NetworkImageWithPlaceholder extends StatelessWidget {
  final String imageUrl;
  final double width;
  final double height;
  final BoxFit fit;
  final double borderRadius;
  final Color placeholderColor;
  final IconData errorIcon;

  const NetworkImageWithPlaceholder({
    Key? key,
    required this.imageUrl,
    this.width = double.infinity,
    this.height = 200,
    this.fit = BoxFit.cover,
    this.borderRadius = 0,
    this.placeholderColor = const Color(0xFFEEEEEE),
    this.errorIcon = Icons.image_not_supported_outlined,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final apiService = Provider.of<ApiService>(context, listen: false);
    
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: imageUrl.isEmpty
          ? _buildPlaceholder()
          : _buildNetworkImage(apiService),
    );
  }

  Widget _buildNetworkImage(ApiService apiService) {
    // Obtener URL completa y válida
    String finalUrl = imageUrl;
    
    // Si no es una URL completa, usar el método getFullImageUrl
    if (!imageUrl.startsWith('http')) {
      finalUrl = apiService.getFullImageUrl(imageUrl);
    }
    
    // Añadir parámetro para evitar caché cuando sea necesario
    String uniqueUrl = finalUrl;
    if (!uniqueUrl.contains('?')) {
      uniqueUrl = '$finalUrl?t=${DateTime.now().millisecondsSinceEpoch}';
    }
    
    return Image.network(
      uniqueUrl,
      width: width,
      height: height,
      fit: fit,
      // Obtener un cache diferenciado para cada imagen
      cacheWidth: (width * MediaQuery.of(context as BuildContext).devicePixelRatio).toInt(),
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        
        return Container(
          width: width,
          height: height,
          color: placeholderColor,
          child: Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                  : null,
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        print('Error loading image: $finalUrl - $error');
        
        // Intentar cargar imagen de placeholer si hay error
        return _buildPlaceholder();
      },
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: width,
      height: height,
      color: placeholderColor,
      child: Center(
        child: Icon(
          errorIcon,
          size: width > 100 ? 40 : 24,
          color: Colors.grey[600],
        ),
      ),
    );
  }
}