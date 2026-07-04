import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/drive_controller.dart';
import '../models/intervention.dart';
import '../screens/breathing_screen.dart';
import '../theme.dart';

/// KDS mudahalesi tetiklendiginde ustten kayan aksiyon karti.
class InterventionBanner extends StatelessWidget {
  const InterventionBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final drive = context.watch<DriveController>();
    final event = drive.activeIntervention;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      transitionBuilder: (child, anim) => SlideTransition(
        position: Tween(begin: const Offset(0, -0.4), end: Offset.zero)
            .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutBack)),
        child: FadeTransition(opacity: anim, child: child),
      ),
      child: event == null
          ? const SizedBox.shrink()
          : Container(
              key: ValueKey(event.time),
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.card,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: event.type.color.withValues(alpha: 0.6)),
                boxShadow: [
                  BoxShadow(
                    color: event.type.color.withValues(alpha: 0.25),
                    blurRadius: 28,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                          color: event.type.color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child:
                            Icon(event.type.icon, color: event.type.color, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(event.type.labelTr,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(fontWeight: FontWeight.w800)),
                            Text(event.reason,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppTheme.textSecondary, fontSize: 11)),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: drive.dismissIntervention,
                        icon: const Icon(Icons.close_rounded,
                            size: 20, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(event.message,
                      style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (event.type == InterventionType.breathing) ...[
                        Expanded(
                          child: FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: event.type.color,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                            onPressed: () {
                              drive.feedback(true);
                              Navigator.of(context).push(MaterialPageRoute(
                                  builder: (_) => const BreathingScreen()));
                            },
                            icon: const Icon(Icons.self_improvement_rounded, size: 18),
                            label: const Text('Egzersizi Başlat'),
                          ),
                        ),
                      ] else ...[
                        Expanded(
                          child: FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: event.type.color,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                            onPressed: () => drive.feedback(true),
                            icon: const Icon(Icons.thumb_up_alt_rounded, size: 16),
                            label: const Text('Faydalı'),
                          ),
                        ),
                      ],
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          onPressed: () => drive.feedback(false),
                          icon: const Icon(Icons.thumb_down_alt_rounded, size: 16),
                          label: const Text('Gerek Yok'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}
