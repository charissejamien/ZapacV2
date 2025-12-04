import 'package:flutter/material.dart';

class FareAccuracyReviewBar extends StatefulWidget {
  final String routeName;
  final String estimatedFareLabel;
  final void Function(bool isAccurate) onAnswer;

  const FareAccuracyReviewBar({
    super.key,
    required this.routeName,
    required this.estimatedFareLabel,
    required this.onAnswer,
  });

  @override
  State<FareAccuracyReviewBar> createState() => _FareAccuracyReviewBarState();
}

class _FareAccuracyReviewBarState extends State<FareAccuracyReviewBar> {
  bool _dismissed = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textColor = colorScheme.onSurface;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, animation) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(animation),
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
      child: _dismissed
          ? const SizedBox.shrink()
          : GestureDetector(
              onVerticalDragUpdate: (details) {
                if (details.primaryDelta != null &&
                    details.primaryDelta! > 4) {
                  setState(() => _dismissed = true);
                }
              },
              child: Container(
                key: const ValueKey('fareReviewBar'),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(30),
                      blurRadius: 8,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // little handle for that "review dialog" vibe (tap to collapse)
                    GestureDetector(
                      onTap: () {
                        setState(() => _dismissed = true);
                      },
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade400,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          color: colorScheme.primary,
                          size: 22,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Was this fare accurate?',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: textColor,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Route: ${widget.routeName}\n'
                                'Was this close to what you actually paid?',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: textColor.withAlpha(200),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () {
                            widget.onAnswer(false);
                            setState(() => _dismissed = true);
                          },
                          child: const Text('Not really'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            widget.onAnswer(true);
                            setState(() => _dismissed = true);
                          },
                          child: const Text('Yes, it was'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}