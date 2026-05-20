import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_repository.dart';
import '../utils/eslip_ocr_parser.dart';

enum _DetectionPhase {
  checking,
  detected,
  extracting,
  notDetected,
  extractFailed,
}

/// Post-scan status: e-slip recognized or not, then auto-import on success.
class EslipDetectionScreen extends StatefulWidget {
  const EslipDetectionScreen({
    super.key,
    required this.ocrRaw,
  });

  final String ocrRaw;

  @override
  State<EslipDetectionScreen> createState() => _EslipDetectionScreenState();
}

class _EslipDetectionScreenState extends State<EslipDetectionScreen>
    with SingleTickerProviderStateMixin {
  _DetectionPhase _phase = _DetectionPhase.checking;
  late final AnimationController _fadeCtrl;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fade = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _runDetection();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _runDetection() async {
    final minDisplay = Future<void>.delayed(const Duration(milliseconds: 1500));
    final detected = isEslipDocument(widget.ocrRaw);
    await minDisplay;
    if (!mounted) return;

    if (!detected) {
      setState(() => _phase = _DetectionPhase.notDetected);
      _fadeCtrl.forward();
      return;
    }

    setState(() => _phase = _DetectionPhase.detected);
    _fadeCtrl.forward();

    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;

    setState(() => _phase = _DetectionPhase.extracting);

    final outcome = parseEslipOcrText(widget.ocrRaw);
    if (!mounted) return;

    if (outcome.classes.isEmpty) {
      setState(() => _phase = _DetectionPhase.extractFailed);
      return;
    }

    final repo = context.read<AppRepository>();
    final imported = await repo.confirmEslipImportFromOutcome(outcome);
    if (!mounted) return;

    if (imported == 0) {
      setState(() => _phase = _DetectionPhase.extractFailed);
      return;
    }

    Navigator.of(context).pop({
      'imported': imported,
      'profile': outcome.profile,
      'outcome': outcome,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F5),
      appBar: AppBar(
        title: const Text('Scan result'),
        automaticallyImplyLeading: _phase == _DetectionPhase.notDetected ||
            _phase == _DetectionPhase.extractFailed,
      ),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fade,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: _buildBody(context),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    switch (_phase) {
      case _DetectionPhase.checking:
        return _StatusBlock(
          icon: const SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(strokeWidth: 3),
          ),
          headline: 'Checking image…',
          subtext: 'Looking for your enrollment form',
          tint: const Color(0xFF1B5E20),
        );
      case _DetectionPhase.detected:
      case _DetectionPhase.extracting:
        return _StatusBlock(
          icon: _BadgeIcon(
            color: const Color(0xFF2E7D32),
            child: const Icon(Icons.check_rounded, color: Colors.white, size: 40),
          ),
          headline: 'E-Slip Detected!',
          subtext: _phase == _DetectionPhase.extracting
              ? 'Extracting your schedule automatically…'
              : 'Your enrollment form was recognized successfully.',
          tint: const Color(0xFF2E7D32),
          trailing: _phase == _DetectionPhase.extracting
              ? const Padding(
                  padding: EdgeInsets.only(top: 20),
                  child: SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  ),
                )
              : null,
        );
      case _DetectionPhase.notDetected:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _StatusBlock(
              icon: _BadgeIcon(
                color: Colors.grey.shade500,
                child: Icon(Icons.close_rounded, color: Colors.grey.shade50, size: 40),
              ),
              headline: 'No E-Slip Detected',
              subtext:
                  'Please scan your official university enrollment assessment form.',
              tint: Colors.grey.shade700,
            ),
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                backgroundColor: const Color(0xFF1B5E20),
              ),
            ),
          ],
        );
      case _DetectionPhase.extractFailed:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _StatusBlock(
              icon: _BadgeIcon(
                color: Colors.grey.shade600,
                child: Icon(Icons.warning_amber_rounded,
                    color: Colors.grey.shade50, size: 36),
              ),
              headline: "Hmm, we couldn't read the schedule",
              subtext:
                  'The form was recognized but class rows could not be extracted. '
                  'Try a clearer photo with the full table in frame.',
              tint: Colors.grey.shade700,
            ),
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                backgroundColor: const Color(0xFF1B5E20),
              ),
            ),
          ],
        );
    }
  }
}

class _StatusBlock extends StatelessWidget {
  const _StatusBlock({
    required this.icon,
    required this.headline,
    required this.subtext,
    required this.tint,
    this.trailing,
  });

  final Widget icon;
  final String headline;
  final String subtext;
  final Color tint;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        icon,
        const SizedBox(height: 24),
        Text(
          headline,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: tint,
              ),
        ),
        const SizedBox(height: 12),
        Text(
          subtext,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 15,
            height: 1.45,
            color: Colors.grey.shade700,
          ),
        ),
        ?trailing,
      ],
    );
  }
}

class _BadgeIcon extends StatelessWidget {
  const _BadgeIcon({required this.color, required this.child});

  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 88,
      height: 88,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Center(child: child),
    );
  }
}
