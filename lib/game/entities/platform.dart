import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:crystal_ball/game/game.dart';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/widgets.dart' show Curve, Curves;

enum PlatformColor {
  green._(
    rarity: 600,
    gradient: [Color(0xFF00FF00), Color(0xFF00FF7F)],
  ),
  blue._(
    rarity: 250,
    gradient: [Color(0xFF00BFFF), Color(0xFF00FFFF)],
  ),
  orange._(
    rarity: 80,
    gradient: [Color(0xFFFD7001), Color(0xFFFDAB42)],
  ),
  red._(
    rarity: 44,
    gradient: [Color(0xFFFF3403), Color(0xFFFD2B9B)],
  ),
  purple._(
    rarity: 25,
    gradient: [Color(0xFF8B00FF), Color(0xFFCD00FF)],
  ),
  golden._(
    rarity: 1,
    gradient: [Color(0xFFFFFFF6), Color(0xFFFFD700)],
  ),
  ;

  const PlatformColor._({
    required this.gradient,
    required this.rarity,
  });

  final List<Color> gradient;
  final int rarity;

  static PlatformColor random(Random random) =>
      values[random.nextInt(values.length)];

  static PlatformColor rarityRandom(Random random) {
    final rarities = values.map((e) => Rarity(e, e.rarity));
    return RarityList(rarities.toList()).getRandom(random);
  }
}

class Platform extends PositionComponent with HasGameRef<CrystalBallGame> {
  Platform({
    required Vector2 super.position,
    required Vector2 super.size,
    required this.color,
    required this.random,
  }) : super(
          anchor: Anchor.center,
          priority: 1000,
          children: [
            RectangleHitbox(),
            RectangleHitbox(
              position: Vector2(0, 10),
              size: size,
            ),
            RectangleHitbox(
              position: Vector2(0, 20),
              size: size,
            ),
            RectangleHitbox(
              position: Vector2(0, 30),
              size: size,
            ),
          ],
        );

  final Random random;

  late final List<Color> gradient = () {
    if (random.nextBool()) {
      return color.gradient.reversed.toList();
    }
    return color.gradient;
  }();

  final PlatformColor color;
  double _distanceToBall = 0;

  double? initialGlowGama;
  double glowGama = 0;

  final effectController = GoodCurvedEffectController(
    0.4,
    Curves.easeInOut,
  )..setToEnd();
  late final glowEffect = PlatformGamaEffect(400, effectController);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    await add(glowEffect);
  }

  @override
  void onMount() {
    super.onMount();
    scheduleMicrotask(() {
      _glowTo(
        to: initialGlowGama ?? _getGlowGama(),
        duration: 0.3,
        curve: Curves.ease,
      );
    });
  }

  void _glowTo({
    required double to,
    Curve curve = Curves.easeInOut,
    double duration = 0.1,
  }) {
    effectController
      ..duration = duration * 4
      ..curve = curve;

    glowEffect._change(to: to);
  }

  @override
  void update(double dt) {
    super.update(dt);

    final ballPs = game.world.theBall.position;
    if (position.y < ballPs.y ||
        ballPs.x > position.x + size.x / 2 ||
        ballPs.x < position.x - size.x / 2) {
      _distanceToBall = kPlatforGlowDistance;
    } else {
      _distanceToBall =
          ballPs.distanceTo(position).clamp(0.0, kPlatforGlowDistance) /
              kPlatforGlowDistance;
    }

    if (!game.gameCubit.isPlaying) return;

    if (y > game.world.reaper.y) {
      removeFromParent();
    }
  }

  double _getGlowGama() {
    return mix(1, 4, smoothStep(0, 1, pow(_distanceToBall, 2).toDouble()));
  }

  @override
  void renderTree(Canvas canvas) {
    if (canvas is SamplerCanvas && canvas.owner is PlatformsSamplerOwner) {
      super.renderTree(canvas);
    }
    if (canvas is! SamplerCanvas) {
      super.renderTree(canvas);
    }
  }

  @override
  void renderDebugMode(Canvas canvas) {
    if (canvas is SamplerCanvas && canvas.owner is PlatformsSamplerOwner) {
      return;
    }
    super.renderDebugMode(canvas);
  }
}

class PlatformGamaEffect extends Effect with EffectTarget<Platform> {
  PlatformGamaEffect(this._to, super.controller);

  @override
  void onMount() {
    super.onMount();
    _from = target.glowGama;
  }

  double _to;
  late double _from;

  @override
  bool get removeOnFinish => false;

  @override
  void apply(double progress) {
    final delta = _to - _from;
    final position = _from + delta * progress;
    target.glowGama = position;
  }

  void _change({required double to}) {
    reset();

    _to = to;
    _from = target.glowGama;
  }
}
