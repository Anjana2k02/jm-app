import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class BrandedLogo extends StatelessWidget {
  const BrandedLogo({super.key, this.size = 64});

  final double size;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final iconSize = size * 0.5;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: cs.primaryContainer,
            borderRadius: BorderRadius.circular(size * 0.25),
            boxShadow: [
              BoxShadow(
                color: cs.primary.withAlpha(40),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Icon(
            Icons.edit_document,
            size: iconSize,
            color: cs.primary,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'Jammer',
          style: GoogleFonts.inter(
            fontSize: size * 0.43,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.8,
            color: cs.onSurface,
          ),
        ),
        Text(
          'Docs',
          style: GoogleFonts.inter(
            fontSize: size * 0.22,
            fontWeight: FontWeight.w400,
            letterSpacing: 0.5,
            color: cs.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
