import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme.dart';

// ---------------------------------------------------------------- feedback
void toast(BuildContext context, String message, {IconData? icon}) {
  HapticFeedback.selectionClick();
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        duration: const Duration(milliseconds: 1600),
        content: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 17, color: AppColors.yellow),
              const SizedBox(width: 10),
            ],
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
}

Future<S?> showAppSheet<S>(
  BuildContext context, {
  required String title,
  required Widget child,
  String? subtitle,
}) {
  return showModalBottomSheet<S>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    builder: (ctx) => SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 10),
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: AppColors.hairline, borderRadius: R.pill),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: T.h2),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(subtitle, style: T.label),
                  ],
                ],
              ),
            ),
            Flexible(child: child),
            const SizedBox(height: 12),
          ],
        ),
      ),
    ),
  );
}

// ---------------------------------------------------------------- avatars
class Avatar extends StatelessWidget {
  const Avatar({
    super.key,
    required this.label,
    this.size = 40,
    this.bold = false,
    this.ring,
    this.badge,
    this.square = false,
  });

  final String label;
  final double size;
  final bool bold;
  final Color? ring;
  final Widget? badge;
  final bool square;

  String get _initials {
    final parts = label.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      final w = parts.first;
      return (w.length == 1 ? w : w.substring(0, 2)).toUpperCase();
    }
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final tint = AppColors.tintFor(label);
    final avatar = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(tint, Colors.white, 0.18)!,
            Color.lerp(tint, Colors.black, 0.12)!,
          ],
        ),
        shape: square ? BoxShape.rectangle : BoxShape.circle,
        borderRadius: square ? BorderRadius.circular(size * 0.3) : null,
        border: ring == null ? null : Border.all(color: ring!, width: 2),
      ),
      alignment: Alignment.center,
      child: Text(
        _initials,
        style: TextStyle(
          color: Colors.white,
          fontSize: size * (bold ? 0.34 : 0.36),
          fontWeight: FontWeight.w800,
          letterSpacing: -0.2,
        ),
      ),
    );
    if (badge == null) return avatar;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        avatar,
        Positioned(right: -2, bottom: -2, child: badge!),
      ],
    );
  }
}

class AvatarStack extends StatelessWidget {
  const AvatarStack({super.key, required this.labels, this.size = 26, this.max = 4, this.overlap = 0.68});
  final List<String> labels;
  final double size;
  final int max;
  final double overlap;

  @override
  Widget build(BuildContext context) {
    final shown = labels.take(max).toList();
    final step = size * overlap;
    final extra = labels.length - shown.length;
    final width = shown.isEmpty ? 0.0 : step * (shown.length - 1) + size + (extra > 0 ? step : 0);
    return SizedBox(
      width: width,
      height: size + 4,
      child: Stack(
        children: [
          for (var i = 0; i < shown.length; i++)
            Positioned(
              left: i * step,
              child: Container(
                decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
                padding: const EdgeInsets.all(1.5),
                child: Avatar(label: shown[i], size: size),
              ),
            ),
          if (extra > 0)
            Positioned(
              left: shown.length * step,
              child: Container(
                width: size + 3,
                height: size + 3,
                decoration: BoxDecoration(
                  color: AppColors.chip,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                alignment: Alignment.center,
                child: Text('+$extra',
                    style: TextStyle(fontSize: size * 0.34, fontWeight: FontWeight.w800, color: AppColors.ink70)),
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------- chips
class Tag extends StatelessWidget {
  const Tag(this.text, {super.key, this.color, this.bg, this.icon, this.dense = false});
  final String text;
  final Color? color;
  final Color? bg;
  final IconData? icon;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: dense ? 7 : 9, vertical: dense ? 3 : 5),
      decoration: BoxDecoration(color: bg ?? AppColors.chip, borderRadius: R.sm),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: color ?? AppColors.ink70),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: dense ? 10.5 : 11.5,
              fontWeight: FontWeight.w700,
              color: color ?? AppColors.ink70,
            ),
          ),
        ],
      ),
    );
  }
}

class CapacityBadge extends StatelessWidget {
  const CapacityBadge({super.key, required this.taken, required this.capacity});
  final int taken;
  final int capacity;

  @override
  Widget build(BuildContext context) {
    final full = taken >= capacity;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        gradient: full ? null : AppColors.brandGradient,
        color: full ? AppColors.chip : null,
        borderRadius: R.pill,
      ),
      child: Text(
        full ? 'PENUH' : '$taken/$capacity',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: full ? AppColors.muted : AppColors.ink,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}

class PillSwitch extends StatelessWidget {
  const PillSwitch({super.key, required this.items, required this.index, required this.onChanged, this.scrollable = false});
  final List<String> items;
  final int index;
  final ValueChanged<int> onChanged;
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    final row = Row(
      mainAxisSize: scrollable ? MainAxisSize.min : MainAxisSize.max,
      children: [
        for (var i = 0; i < items.length; i++)
          scrollable
              ? Padding(padding: const EdgeInsets.only(right: 6), child: _pill(i))
              : Expanded(child: Padding(padding: EdgeInsets.only(right: i == items.length - 1 ? 0 : 4), child: _pill(i))),
      ],
    );
    final box = Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: AppColors.chip, borderRadius: R.pill),
      child: row,
    );
    return scrollable ? SingleChildScrollView(scrollDirection: Axis.horizontal, child: box) : box;
  }

  Widget _pill(int i) {
    final on = i == index;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onChanged(i);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: on ? Colors.white : Colors.transparent,
          borderRadius: R.pill,
          boxShadow: on ? Shadows.soft : null,
        ),
        alignment: Alignment.center,
        child: Text(
          items[i],
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: on ? AppColors.ink : AppColors.muted,
          ),
        ),
      ),
    );
  }
}

class UnderlineTabs extends StatelessWidget {
  const UnderlineTabs({
    super.key,
    required this.items,
    required this.index,
    required this.onChanged,
    this.icons,
    this.spread = false,
    this.accent = AppColors.ink,
  });
  final List<String> items;
  final int index;
  final ValueChanged<int> onChanged;
  final List<IconData>? icons;
  final bool spread;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    Widget tab(int i) {
      final on = i == index;
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          HapticFeedback.selectionClick();
          onChanged(i);
        },
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: spread ? 4 : 10, vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icons != null)
                Icon(icons![i], size: 19, color: on ? accent : AppColors.faint)
              else
                Text(
                  items[i],
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                    color: on ? accent : AppColors.faint,
                  ),
                ),
              const SizedBox(height: 8),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 2.5,
                width: on ? 26 : 0,
                decoration: BoxDecoration(color: accent, borderRadius: R.pill),
              ),
            ],
          ),
        ),
      );
    }

    if (spread) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [for (var i = 0; i < items.length; i++) Expanded(child: tab(i))],
      );
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(children: [for (var i = 0; i < items.length; i++) tab(i)]),
    );
  }
}

// ---------------------------------------------------------------- surfaces
class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.color,
    this.border,
    this.radius = R.lg,
    this.shadow = true,
  });
  final Widget child;
  final EdgeInsets padding;
  final EdgeInsets? margin;
  final Color? color;
  final Color? border;
  final BorderRadius radius;
  final bool shadow;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? Colors.white,
        borderRadius: radius,
        border: border == null ? null : Border.all(color: border!),
        boxShadow: shadow ? Shadows.card : null,
      ),
      child: child,
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.action, this.onAction, this.subtitle});
  final String title;
  final String? action;
  final VoidCallback? onAction;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: T.h2),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle!, style: T.small),
                ],
              ],
            ),
          ),
          if (action != null)
            GestureDetector(
              onTap: onAction,
              child: Padding(
                padding: const EdgeInsets.only(left: 8, top: 2),
                child: Text(action!,
                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.blue)),
              ),
            ),
        ],
      ),
    );
  }
}

enum BtnKind { primary, dark, outline, soft, danger }

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    this.onTap,
    this.kind = BtnKind.primary,
    this.icon,
    this.height = 46,
    this.loading = false,
  });
  final String label;
  final VoidCallback? onTap;
  final BtnKind kind;
  final IconData? icon;
  final double height;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null || loading;
    late Color fg;
    Gradient? gradient;
    Color? bg;
    Border? border;
    switch (kind) {
      case BtnKind.primary:
        gradient = AppColors.greenGradient;
        fg = Colors.white;
      case BtnKind.dark:
        gradient = AppColors.inkGradient;
        fg = Colors.white;
      case BtnKind.outline:
        bg = Colors.white;
        border = Border.all(color: AppColors.hairline, width: 1.4);
        fg = AppColors.ink;
      case BtnKind.soft:
        bg = AppColors.greenSoft;
        fg = AppColors.greenDark;
      case BtnKind.danger:
        bg = AppColors.redSoft;
        fg = AppColors.red;
    }
    return Opacity(
      opacity: disabled ? 0.55 : 1,
      child: GestureDetector(
        onTap: disabled
            ? null
            : () {
                HapticFeedback.lightImpact();
                onTap!();
              },
        child: Container(
          height: height,
          decoration: BoxDecoration(
            gradient: gradient,
            color: bg,
            border: border,
            borderRadius: R.md,
            boxShadow: kind == BtnKind.primary && !disabled
                ? [const BoxShadow(color: Color(0x3317C964), blurRadius: 16, offset: Offset(0, 6))]
                : null,
          ),
          alignment: Alignment.center,
          child: loading
              ? SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2.2, color: fg),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: 17, color: fg),
                      const SizedBox(width: 7),
                    ],
                    Flexible(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: fg),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class CircleIconButton extends StatelessWidget {
  const CircleIconButton({
    super.key,
    required this.icon,
    this.onTap,
    this.size = 38,
    this.bg = Colors.white,
    this.fg = AppColors.ink,
    this.badge = false,
    this.border = true,
  });
  final IconData icon;
  final VoidCallback? onTap;
  final double size;
  final Color bg;
  final Color fg;
  final bool badge;
  final bool border;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap == null
          ? null
          : () {
              HapticFeedback.selectionClick();
              onTap!();
            },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: bg,
              shape: BoxShape.circle,
              border: border ? Border.all(color: AppColors.hairline) : null,
            ),
            child: Icon(icon, size: size * 0.47, color: fg),
          ),
          if (badge)
            Positioned(
              right: -1,
              top: -1,
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: AppColors.blue,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------- fields
class AppField extends StatelessWidget {
  const AppField({
    super.key,
    required this.controller,
    required this.hint,
    this.label,
    this.icon,
    this.obscure = false,
    this.keyboard,
    this.suffix,
    this.maxLines = 1,
    this.onChanged,
    this.textInputAction,
    this.onSubmitted,
    this.autofocus = false,
  });
  final TextEditingController controller;
  final String hint;
  final String? label;
  final IconData? icon;
  final bool obscure;
  final TextInputType? keyboard;
  final Widget? suffix;
  final int maxLines;
  final ValueChanged<String>? onChanged;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(label!, style: T.caps.copyWith(color: AppColors.ink70)),
          const SizedBox(height: 7),
        ],
        Container(
          decoration: BoxDecoration(
            color: AppColors.canvas,
            borderRadius: R.md,
            border: Border.all(color: AppColors.hairline),
          ),
          child: TextField(
            controller: controller,
            obscureText: obscure,
            keyboardType: keyboard,
            maxLines: maxLines,
            onChanged: onChanged,
            autofocus: autofocus,
            textInputAction: textInputAction,
            onSubmitted: onSubmitted,
            style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600, color: AppColors.ink),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w500, color: AppColors.faint),
              prefixIcon: icon == null ? null : Icon(icon, size: 19, color: AppColors.muted),
              suffixIcon: suffix,
              border: InputBorder.none,
              focusedBorder: InputBorder.none,
              enabledBorder: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: icon == null ? 14 : 4, vertical: 14),
            ),
          ),
        ),
      ],
    );
  }
}

class ChoiceRow<S> extends StatelessWidget {
  const ChoiceRow({
    super.key,
    required this.options,
    required this.value,
    required this.labelOf,
    required this.onChanged,
  });
  final List<S> options;
  final S value;
  final String Function(S) labelOf;
  final ValueChanged<S> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final o in options)
          GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              onChanged(o);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: o == value ? AppColors.ink : Colors.white,
                borderRadius: R.pill,
                border: Border.all(color: o == value ? AppColors.ink : AppColors.hairline),
              ),
              child: Text(
                labelOf(o),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: o == value ? Colors.white : AppColors.ink70,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------- misc
class ProgressBar extends StatelessWidget {
  const ProgressBar({super.key, required this.value, this.height = 6, this.color});
  final double value;
  final double height;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: R.pill,
      child: LinearProgressIndicator(
        value: value.clamp(0, 1),
        minHeight: height,
        backgroundColor: AppColors.hairline,
        valueColor: AlwaysStoppedAnimation(color ?? AppColors.green),
      ),
    );
  }
}

class StatTile extends StatelessWidget {
  const StatTile({super.key, required this.value, required this.label, this.color});
  final String value;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value, style: T.h1.copyWith(color: color ?? AppColors.ink, fontSize: 22)),
        const SizedBox(height: 2),
        Text(label, style: T.small),
      ],
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 44),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(color: AppColors.chip, shape: BoxShape.circle),
            child: Icon(icon, size: 28, color: AppColors.faint),
          ),
          const SizedBox(height: 16),
          Text(title, style: T.title, textAlign: TextAlign.center),
          const SizedBox(height: 6),
          Text(subtitle, style: T.label, textAlign: TextAlign.center),
          if (actionLabel != null) ...[
            const SizedBox(height: 16),
            SizedBox(width: 190, child: PrimaryButton(label: actionLabel!, onTap: onAction, kind: BtnKind.outline)),
          ],
        ],
      ),
    );
  }
}

class DottedLine extends StatelessWidget {
  const DottedLine({super.key, this.color = AppColors.hairline});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final count = math.max(1, (c.maxWidth / 7).floor());
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(
            count,
            (_) => Container(width: 3, height: 1.5, decoration: BoxDecoration(color: color, borderRadius: R.pill)),
          ),
        );
      },
    );
  }
}

/// Fade + slide used on list items so pages feel alive instead of static.
class Reveal extends StatelessWidget {
  const Reveal({super.key, required this.child, this.delayMs = 0});
  final Widget child;
  final int delayMs;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 320 + delayMs.clamp(0, 400)),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(offset: Offset(0, 14 * (1 - t)), child: child),
      ),
      child: child,
    );
  }
}
