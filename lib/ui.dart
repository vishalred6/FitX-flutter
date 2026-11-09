import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'models.dart';

class Palette {
  static const primary = Color(0xFF6554E8);
  static const mint = Color(0xFFBAF1D2);
  static const ink = Color(0xFF222438);
  static const orange = Color(0xFFDF8654);
  static const blue = Color(0xFF4C8EDB);
  static const pink = Color(0xFFD56B9A);
  static Color muted(BuildContext context) => const Color(0xFFA5A6BD);
  static Color border(BuildContext context) => const Color(0xFF303246);
  static Color soft(BuildContext context) => const Color(0xFF252838);
}

ThemeData fitxTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: Palette.primary,
    brightness: Brightness.dark,
    primary: const Color(0xFFB5A9FF),
    surface: const Color(0xFF1C1E2C),
  );
  final theme = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    fontFamily: 'Manrope',
    scaffoldBackgroundColor: const Color(0xFF141520),
  );
  return theme.copyWith(
    textTheme: theme.textTheme.apply(
      bodyColor: const Color(0xFFF0EFF9),
      displayColor: const Color(0xFFF0EFF9),
    ),
    dividerColor: const Color(0xFF303246),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
        backgroundColor: Palette.primary,
        foregroundColor: Colors.white,
        textStyle: const TextStyle(
          fontFamily: 'Manrope',
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 17),
        foregroundColor: scheme.onSurface,
        side: const BorderSide(color: Color(0xFF45455B)),
        textStyle: const TextStyle(
          fontFamily: 'Manrope',
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF252838),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF303246)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Palette.primary),
      ),
      labelStyle: const TextStyle(color: Color(0xFFB3B1C7), fontSize: 13),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: const Color(0xFF323149),
      contentTextStyle: const TextStyle(
        color: Color(0xFFF0EFF9),
        fontFamily: 'Manrope',
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
}

extension ActivityAppearance on ActivityType {
  IconData get icon => switch (this) {
    ActivityType.strength => Icons.fitness_center_rounded,
    ActivityType.running => Icons.directions_run_rounded,
    ActivityType.cycling => Icons.directions_bike_rounded,
    ActivityType.yoga => Icons.self_improvement_rounded,
    ActivityType.walking => Icons.directions_walk_rounded,
    ActivityType.hiit => Icons.bolt_rounded,
  };
  Color get color => switch (this) {
    ActivityType.strength => Palette.primary,
    ActivityType.running => Palette.orange,
    ActivityType.cycling => Palette.blue,
    ActivityType.yoga => const Color(0xFF3F9B79),
    ActivityType.walking => Palette.pink,
    ActivityType.hiit => const Color(0xFFC49B27),
  };
}

class Surface extends StatelessWidget {
  const Surface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(24),
    this.color,
  });
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  @override
  Widget build(BuildContext context) => Material(
    color: color ?? Theme.of(context).colorScheme.surface,
    clipBehavior: Clip.antiAlias,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
      side: BorderSide(color: Palette.border(context)),
    ),
    child: Padding(padding: padding, child: child),
  );
}

class PageTitle extends StatelessWidget {
  const PageTitle({
    super.key,
    required this.title,
    required this.subtitle,
    this.action,
    this.eyebrow,
  });
  final String title, subtitle;
  final String? eyebrow;
  final Widget? action;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final compact = constraints.maxWidth < 600;
      final heading = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (eyebrow != null) ...[
            Text(
              eyebrow!,
              style: TextStyle(
                fontSize: 10,
                letterSpacing: 2,
                color: Palette.muted(context),
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
          ],
          Text(
            title,
            style: TextStyle(
              fontSize: compact ? 27 : 31,
              letterSpacing: -1.2,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 13,
              height: 1.6,
              color: Palette.muted(context),
            ),
          ),
        ],
      );
      if (compact) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            heading,
            if (action != null) ...[const SizedBox(height: 16), action!],
          ],
        );
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(child: heading),
          if (action != null) ...[const SizedBox(width: 18), action!],
        ],
      );
    },
  );
}

class SectionHeading extends StatelessWidget {
  const SectionHeading(this.title, {super.key, this.subtitle, this.action});
  final String title;
  final String? subtitle;
  final Widget? action;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 5),
              Text(
                subtitle!,
                style: TextStyle(fontSize: 11, color: Palette.muted(context)),
              ),
            ],
          ],
        ),
      ),
      ?action,
    ],
  );
}

class Tag extends StatelessWidget {
  const Tag(this.text, {super.key, this.color = Palette.primary, this.icon});
  final String text;
  final Color color;
  final IconData? icon;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(7),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 5),
        ],
        Text(
          text,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w700,
            fontSize: 10,
          ),
        ),
      ],
    ),
  );
}

class IconTile extends StatelessWidget {
  const IconTile(
    this.icon, {
    super.key,
    this.color = Palette.primary,
    this.size = 44,
  });
  final IconData icon;
  final Color color;
  final double size;
  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.11),
      borderRadius: BorderRadius.circular(13),
    ),
    child: Icon(icon, size: size * 0.5, color: color),
  );
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });
  final IconData icon;
  final String title, message;
  final Widget? action;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 12),
    child: Center(
      child: Column(
        children: [
          IconTile(icon, size: 58),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 350),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Palette.muted(context),
                fontSize: 12,
                height: 1.7,
              ),
            ),
          ),
          if (action != null) ...[const SizedBox(height: 20), action!],
        ],
      ),
    ),
  );
}

class MetricCard extends StatelessWidget {
  const MetricCard({
    super.key,
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
    required this.color,
    required this.progress,
    required this.caption,
  });
  final String label, value, unit, caption;
  final IconData icon;
  final Color color;
  final double progress;
  @override
  Widget build(BuildContext context) => Surface(
    padding: const EdgeInsets.all(20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconTile(icon, size: 37, color: color),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Palette.muted(context),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.end,
          spacing: 5,
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                letterSpacing: -1.2,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Text(
                unit,
                style: TextStyle(fontSize: 10, color: Palette.muted(context)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 13),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: progress.clamp(0, 1)),
          duration: const Duration(milliseconds: 850),
          curve: Curves.easeOutCubic,
          builder: (context, value, _) => ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: value,
              color: color,
              backgroundColor: color.withValues(alpha: 0.1),
              minHeight: 4,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          caption,
          style: TextStyle(fontSize: 10, color: Palette.muted(context)),
        ),
      ],
    ),
  );
}

class ResponsiveGrid extends StatelessWidget {
  const ResponsiveGrid({
    super.key,
    required this.children,
    this.minWidth = 230,
    this.gap = 16,
    this.maxColumns = 4,
  });
  final List<Widget> children;
  final double minWidth, gap;
  final int maxColumns;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final capacity = ((constraints.maxWidth + gap) / (minWidth + gap))
          .floor()
          .clamp(1, maxColumns);
      final columns = children.length == 4 && capacity == 3 ? 2 : capacity;
      final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: children
            .map((child) => SizedBox(width: width, child: child))
            .toList(),
      );
    },
  );
}

class TwoColumn extends StatelessWidget {
  const TwoColumn({
    super.key,
    required this.left,
    required this.right,
    this.ratio = 2,
    this.breakpoint = 950,
  });
  final Widget left, right;
  final int ratio;
  final double breakpoint;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => constraints.maxWidth < breakpoint
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [left, const SizedBox(height: 22), right],
          )
        : Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: ratio, child: left),
              const SizedBox(width: 22),
              Expanded(child: right),
            ],
          ),
  );
}

class ActivityChart extends StatefulWidget {
  const ActivityChart({
    super.key,
    required this.values,
    required this.endDate,
    this.goal = 45,
    this.height = 180,
  });
  final List<double> values;
  final DateTime endDate;
  final double goal, height;
  @override
  State<ActivityChart> createState() => _ActivityChartState();
}

class _ActivityChartState extends State<ActivityChart> {
  int? selected;
  @override
  void didUpdateWidget(ActivityChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.values.length != widget.values.length) {
      selected = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final values = widget.values;
    final active = (selected ?? values.length - 1).clamp(0, values.length - 1);
    final top = math.max(widget.goal, values.fold<double>(0, math.max)) * 1.2;
    final date = dateOnly(widget.endDate)
        .subtract(Duration(days: values.length - 1 - active));
    return Column(
      children: [
        Row(
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: const BoxDecoration(
                color: Palette.primary,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 7),
            Text(
              'Active minutes',
              style: TextStyle(color: Palette.muted(context), fontSize: 10),
            ),
            const Spacer(),
            Text(
              '${shortDate(date)} · ${values[active].round()} min',
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: widget.height + 27,
          child: Stack(
            children: [
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: widget.height,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(
                    4,
                    (_) => Divider(color: Palette.border(context), height: 1),
                  ),
                ),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(values.length, (i) {
                  final date = dateOnly(widget.endDate)
                      .subtract(Duration(days: values.length - 1 - i));
                  final label = values.length <= 7
                      ? weekdays[date.weekday - 1]
                      : (i % 5 == 0 || i == values.length - 1
                            ? '${date.day}'
                            : '');
                  return Expanded(
                    child: Tooltip(
                      message:
                          '${shortDate(date)}: ${values[i].round()} active minutes',
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () => setState(() => selected = i),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: values.length <= 7 ? 10 : 3,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 450),
                                curve: Curves.easeOutCubic,
                                height: values[i] == 0
                                    ? 3
                                    : (values[i] / top * widget.height).clamp(
                                        3,
                                        widget.height,
                                      ),
                                width: values.length <= 7 ? 34 : 16,
                                decoration: BoxDecoration(
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(7),
                                  ),
                                  color: values[i] == 0
                                      ? Palette.border(context)
                                      : i == active
                                      ? Palette.primary
                                      : Palette.primary.withValues(alpha: 0.22),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                label,
                                style: TextStyle(
                                  fontSize: 9,
                                  color: i == active
                                      ? Theme.of(context).colorScheme.primary
                                      : Palette.muted(context),
                                  fontWeight: i == active
                                      ? FontWeight.w800
                                      : FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class WeightChart extends StatelessWidget {
  const WeightChart({super.key, required this.entries});
  final List<WeightEntry> entries;
  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return const EmptyState(
        icon: Icons.monitor_weight_outlined,
        title: 'Your story starts here',
        message: 'Log your first weight to start seeing your trend.',
      );
    }
    final sorted = entries;
    return Column(
      children: [
        SizedBox(
          height: 200,
          width: double.infinity,
          child: Semantics(
            label:
                'Weight trend from ${sorted.first.kg} to ${sorted.last.kg} kilograms.',
            child: RepaintBoundary(
              child: CustomPaint(
                painter: _WeightPainter(
                  sorted,
                  Palette.border(context),
                  Palette.muted(context),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              shortDate(sorted.first.date),
              style: TextStyle(fontSize: 10, color: Palette.muted(context)),
            ),
            Text(
              shortDate(sorted.last.date),
              style: TextStyle(fontSize: 10, color: Palette.muted(context)),
            ),
          ],
        ),
      ],
    );
  }
}

class _WeightPainter extends CustomPainter {
  _WeightPainter(this.entries, this.grid, this.text);
  final List<WeightEntry> entries;
  final Color grid, text;
  @override
  void paint(Canvas canvas, Size size) {
    final all = entries.map((e) => e.kg);
    final min = all.reduce(math.min) - 1;
    final max = all.reduce(math.max) + 1;
    final width = size.width - 40;
    double y(double kg) => 12 + (max - kg) / (max - min) * (size.height - 30);
    for (var i = 0; i < 4; i++) {
      final value = min + (max - min) * i / 3;
      canvas.drawLine(
        Offset(0, y(value)),
        Offset(width, y(value)),
        Paint()..color = grid,
      );
      final label = TextPainter(
        text: TextSpan(
          text: value.toStringAsFixed(1),
          style: TextStyle(fontFamily: 'Manrope', fontSize: 9, color: text),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      label.paint(canvas, Offset(width + 8, y(value) - 6));
    }
    final span = math.max(
      1,
      entries.last.date.difference(entries.first.date).inDays,
    );
    final points = entries
        .map(
          (e) => Offset(
            entries.length == 1
                ? width / 2
                : e.date.difference(entries.first.date).inDays / span * width,
            y(e.kg),
          ),
        )
        .toList();
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }
    if (points.length > 1) {
      final area = Path.from(path)
        ..lineTo(points.last.dx, size.height)
        ..lineTo(points.first.dx, size.height)
        ..close();
      canvas.drawPath(
        area,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Palette.primary.withValues(alpha: 0.2),
              Palette.primary.withValues(alpha: 0),
            ],
          ).createShader(Offset.zero & size),
      );
      canvas.drawPath(
        path,
        Paint()
          ..color = Palette.primary
          ..strokeWidth = 3
          ..style = PaintingStyle.stroke
          ..strokeJoin = StrokeJoin.round,
      );
    }
    for (final point in points) {
      canvas.drawCircle(point, 5, Paint()..color = Palette.primary);
      canvas.drawCircle(point, 2, Paint()..color = Colors.white);
    }
  }

  @override
  bool shouldRepaint(covariant _WeightPainter oldDelegate) =>
      oldDelegate.entries != entries ||
      oldDelegate.grid != grid ||
      oldDelegate.text != text;
}

class OrbitArt extends StatelessWidget {
  const OrbitArt({super.key, this.mint = false});
  final bool mint;
  @override
  Widget build(BuildContext context) =>
      CustomPaint(painter: _OrbitPainter(mint));
}

class _OrbitPainter extends CustomPainter {
  const _OrbitPainter(this.mint);
  final bool mint;
  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width * 0.55, size.height * 0.5);
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(-0.48);
    for (var i = 0; i < 4; i++) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset.zero,
          width: size.width * (0.5 + i * 0.17),
          height: size.height * (0.37 + i * 0.18),
        ),
        Paint()
          ..color = (mint ? Palette.primary : Colors.white).withValues(
            alpha: 0.09 + i * 0.025,
          )
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2,
      );
    }
    canvas.restore();
    canvas.drawCircle(
      Offset(size.width * 0.78, size.height * 0.22),
      8,
      Paint()..color = Palette.mint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.2, size.height * 0.78),
      4,
      Paint()..color = Colors.white.withValues(alpha: 0.6),
    );
    final path = Path()
      ..moveTo(size.width * 0.1, size.height * 0.65)
      ..lineTo(size.width * 0.3, size.height * 0.65)
      ..lineTo(size.width * 0.42, size.height * 0.4)
      ..lineTo(size.width * 0.55, size.height * 0.75)
      ..lineTo(size.width * 0.72, size.height * 0.2)
      ..lineTo(size.width * 0.82, size.height * 0.48)
      ..lineTo(size.width, size.height * 0.48);
    canvas.drawPath(
      path,
      Paint()
        ..color = mint ? Palette.primary : Palette.mint
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant _OrbitPainter oldDelegate) =>
      oldDelegate.mint != mint;
}

void toast(BuildContext context, String message) {
  if (!context.mounted) {
    return;
  }
  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

Future<bool> runAction(
  BuildContext context,
  Future<void> Function() action, {
  String? success,
}) async {
  try {
    await action();
    if (success != null && context.mounted) {
      toast(context, success);
    }
    return true;
  } catch (_) {
    if (context.mounted) {
      toast(
        context,
        'Could not save changes. Your changes are in memory; use Retry in the storage banner.',
      );
    }
    return false;
  }
}

Future<bool> confirm(
  BuildContext context, {
  required String title,
  required String message,
  String label = 'Confirm',
  bool destructive = false,
}) async =>
    await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: Text(
            message,
            style: const TextStyle(height: 1.7, fontSize: 13),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: destructive
                ? FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFC14959),
                  )
                : null,
            onPressed: () => Navigator.pop(context, true),
            child: Text(label),
          ),
        ],
      ),
    ) ??
    false;

String? validateNumber(
  String? value,
  double min,
  double max, {
  bool integer = false,
}) {
  final number = double.tryParse(value?.trim() ?? '');
  if (number == null ||
      !number.isFinite ||
      number < min ||
      number > max ||
      (integer && number != number.roundToDouble())) {
    return 'Enter ${integer ? 'a whole number' : 'a number'} from ${min.toStringAsFixed(0)} to ${max.toStringAsFixed(0)}';
  }
  return null;
}
