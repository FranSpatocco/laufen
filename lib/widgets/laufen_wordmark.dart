import 'package:flutter/material.dart';

/// Wordmark de la marca: "laufen" en minúscula, tipografía Outfit bold, con
/// los dos detalles que la hacen reconocible (ver CLAUDE.md > Diseño): un
/// punto sobre la "u" y un remate que se levanta al final de la línea de
/// base. No hay un asset vectorial del logo en el repo (se definió en un
/// Artifact de Claude), así que se reconstruye acá con texto medido en vez
/// de una imagen — misma tipografía y color en cualquier pantalla.
class LaufenWordmark extends StatelessWidget {
  final double fontSize;
  final Color color;

  const LaufenWordmark({super.key, this.fontSize = 40, required this.color});

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontFamily: 'Outfit',
      fontWeight: FontWeight.w700,
      fontSize: fontSize,
      color: color,
      height: 1,
    );

    double widthOf(String text) {
      final painter = TextPainter(
        text: TextSpan(text: text, style: style),
        textDirection: TextDirection.ltr,
      )..layout();
      return painter.width;
    }

    final beforeU = widthOf('la');
    final uWidth = widthOf('lau') - beforeU;
    final fullWidth = widthOf('laufen');
    final dotSize = fontSize * 0.11;

    return SizedBox(
      width: fullWidth + fontSize * 0.18,
      height: fontSize * 1.3,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            top: fontSize * 0.28,
            child: Text('laufen', style: style),
          ),
          Positioned(
            left: beforeU + uWidth / 2 - dotSize / 2,
            top: 0,
            child: Container(
              width: dotSize,
              height: dotSize,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
          ),
          Positioned(
            left: fullWidth + fontSize * 0.02,
            bottom: fontSize * 0.24,
            child: Transform.rotate(
              angle: -0.5,
              child: Container(
                width: fontSize * 0.16,
                height: fontSize * 0.045,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(fontSize * 0.02),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
