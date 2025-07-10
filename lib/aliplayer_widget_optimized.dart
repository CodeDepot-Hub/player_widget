// Copyright © 2025 Alibaba Cloud. All rights reserved.
//
// Author: keria
// Date: 2025/2/6
// Brief: Optimized Player Widget for better performance

part of 'aliplayer_widget_lib.dart';

/// 性能优化版本的播放器 Widget
///
/// Optimized version of AliPlayerWidget for better performance
class AliPlayerWidgetOptimized extends StatefulWidget {
  /// 视频播放控制器，用于控制视频的播放、暂停等操作。
  final AliPlayerWidgetController _controller;

  /// 自定义覆盖层，允许在视频上方显示额外的 UI 元素。
  final List<Widget> overlays;

  const AliPlayerWidgetOptimized(
    this._controller, {
    super.key,
    this.overlays = const [],
  });

  @override
  State<StatefulWidget> createState() => _AliPlayerWidgetOptimizedState();
}

class _AliPlayerWidgetOptimizedState extends State<AliPlayerWidgetOptimized>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  late AliPlayerWidgetController _playController;
  late SharedAnimationManager _animationManager;
  late SceneType _sceneType;

  // 性能优化：使用防抖Timer避免频繁更新
  Timer? _seekDebounceTimer;
  Timer? _volumeDebounceTimer;
  Timer? _brightnessDebounceTimer;

  // 性能优化：缓存计算结果
  Size? _cachedVideoSize;
  Size? _cachedPlayerViewSize;

  final SafeValueNotifier<ContentViewType> _contentViewTypeNotifier =
      SafeValueNotifier(ContentViewType.none);

  final SafeValueNotifier<bool> _isShowSettingMenuPanelNotifier = SafeValueNotifier(false);

  final SafeValueNotifier<bool> _isDraggingNotifier = SafeValueNotifier(false);

  final SafeValueNotifier<Duration> _currentSeekTimeNotifier = SafeValueNotifier(Duration.zero);

  // 性能优化：缓存常用的Widget
  Widget? _cachedPlaySurfaceView;
  Widget? _cachedPlayControlView;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvoked: (bool didPop) {
        if (didPop) return;
        _handleBackPress();
      },
      child: RepaintBoundary(
        child: _buildContentBody(),
      ),
    );
  }

  /// 构建主体内容 - 性能优化版本
  Widget _buildContentBody() {
    return ValueListenableBuilder(
      valueListenable: _playController.videoSizeNotifier,
      builder: (context, videoSize, __) {
        if (videoSize == Size.zero) {
          return const SizedBox.shrink();
        }

        // 性能优化：缓存尺寸计算结果
        if (_cachedVideoSize != videoSize) {
          _cachedVideoSize = videoSize;
          _cachedPlayerViewSize = ScreenUtil.calculateRenderSize(
            context,
            videoSize: videoSize,
            isFullScreenMode: FullScreenUtil.isFullScreen(),
          );
        }

        final playerViewSize = _cachedPlayerViewSize!;
        logi("[build]: videoSize: $videoSize, playerViewSize: $playerViewSize");

        return ConstrainedBox(
          constraints: BoxConstraints.tight(playerViewSize),
          child: Stack(
            children: [
              // 性能优化：每个layer用RepaintBoundary包装
              RepaintBoundary(
                child: _buildPlaySurfaceViewOptimized(playerViewSize.width, playerViewSize.height),
              ),
              if (_playController._widgetData?.coverUrl.isNotEmpty ?? false)
                RepaintBoundary(
                  child: _buildPlayCoverViewOptimized(playerViewSize.width, playerViewSize.height),
                ),
              RepaintBoundary(child: _buildPlayControlViewOptimized()),
              RepaintBoundary(child: _buildTopBarWidgetOptimized()),
              RepaintBoundary(child: _buildBottomBarWidgetOptimized()),
              if (isNotScene(_playController._widgetData, SceneType.live))
                RepaintBoundary(child: _buildSeekThumbnailWidgetOptimized()),
              RepaintBoundary(child: _buildCenterDisplayWidgetOptimized()),
              RepaintBoundary(child: _buildPlayStateViewOptimized()),
              // 添加浮层
              ..._buildOverlaysOptimized(),
              RepaintBoundary(child: _buildSettingMenuPanelOptimized()),
            ],
          ),
        );
      },
    );
  }

  /// 优化的播放器视图构建
  Widget _buildPlaySurfaceViewOptimized(double width, double height) {
    // 性能优化：缓存不变的Widget
    _cachedPlaySurfaceView ??= AliPlayerView(
      onCreated: (int viewId) => _playController._setPlayerView(viewId),
      x: 0,
      y: 0,
      width: width,
      height: height,
    );
    return _cachedPlaySurfaceView!;
  }

  /// 优化的封面视图构建
  Widget _buildPlayCoverViewOptimized(double width, double height) {
    return ValueListenableBuilder(
      valueListenable: _playController.isRenderedNotifier,
      builder: (context, isRendered, child) {
        if (isRendered) {
          return const SizedBox.shrink();
        }
        // 性能优化：child参数避免重建
        return child!;
      },
      child: AliPlayerCoverImageWidget(
        imageUrl: _playController._widgetData?.coverUrl ?? "",
        width: width,
        height: height,
        fit: BoxFit.cover,
      ),
    );
  }

  /// 优化的播放控制视图构建
  Widget _buildPlayControlViewOptimized() {
    // 性能优化：缓存不变的Widget
    _cachedPlayControlView ??= AliPlayerPlayControlWidget(
      autoHide: true,
      onVisibilityChanged: (bool isVisible) {
        _togglePlayControlVisibility(forceHide: !isVisible);
      },
      onDoubleTap: _onPlayerViewDoubleTap,
      onLongPressStart: !_isSceneLive() ? _onPlayerViewLongPress : null,
      onLongPressEnd: !_isSceneLive() ? _onPlayerViewLongPressEnd : null,
      onHorizontalDragUpdate: !_isSceneLive() ? _onPlayerViewHorizontalDragUpdateOptimized : null,
      onHorizontalDragEnd: !_isSceneLive() ? _onPlayerViewHorizontalDragEndOptimized : null,
      onLeftVerticalDragUpdate:
          !_isSceneListPlayer() ? _onPlayerViewLeftVerticalDragUpdateOptimized : null,
      onLeftVerticalDragEnd: !_isSceneListPlayer() ? _onPlayerViewLeftVerticalDragEnd : null,
      onRightVerticalDragUpdate:
          !_isSceneListPlayer() ? _onPlayerViewRightVerticalDragUpdateOptimized : null,
      onRightVerticalDragEnd: !_isSceneListPlayer() ? _onPlayerViewRightVerticalDragEnd : null,
    );
    return _cachedPlayControlView!;
  }

  /// 优化的顶部栏构建
  Widget _buildTopBarWidgetOptimized() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: AliPlayerTopBarWidget(
        animationManager: _animationManager,
        title: _playController._widgetData?.videoTitle ?? "",
        onBackPressed: _handleBackPress,
        onSettingsPressed: _toggleSettingMenuPanel,
        isDownload: false,
        onDownloadPressed: _isSceneLive() ? null : _onDownloadPressed,
        onSnapshotPressed: _isSceneLive() ? null : _onSnapshotPressed,
        onPIPPressed: _isSceneLive() ? null : _onPIPPressed,
      ),
    );
  }

  /// 优化的底部栏构建 - 减少Listenable.merge的使用
  Widget _buildBottomBarWidgetOptimized() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: _OptimizedBottomBarBuilder(
        playController: _playController,
        animationManager: _animationManager,
        isLive: _isSceneLive(),
        onPlayIconPressed: _onPlayerViewTap,
        onFullScreenPressed: _onFullScreenPressed,
        onDragUpdate: !_isSceneLive() ? _onDragUpdate : null,
        onDragEnd: !_isSceneLive() ? _onDragEnd : null,
        onSeekEnd: !_isSceneLive() ? _onSeekEnd : null,
      ),
    );
  }

  /// 优化的中心显示控件
  Widget _buildCenterDisplayWidgetOptimized() {
    return ValueListenableBuilder(
      valueListenable: _contentViewTypeNotifier,
      builder: (context, contentViewType, child) {
        if (contentViewType == ContentViewType.none) {
          return const SizedBox.shrink();
        }

        return AliPlayerCenterDisplayWidget(
          contentWidget: _buildCenterDisplayContentWidget(contentViewType),
        );
      },
    );
  }

  /// 优化的播放状态视图
  Widget _buildPlayStateViewOptimized() {
    return _OptimizedPlayStateBuilder(
      playController: _playController,
    );
  }

  /// 优化的设置菜单面板
  Widget _buildSettingMenuPanelOptimized() {
    return ValueListenableBuilder(
      valueListenable: _isShowSettingMenuPanelNotifier,
      builder: (context, visible, child) {
        if (!visible) return const SizedBox.shrink();

        return AliPlayerSettingMenuPanel(
          isVisible: visible,
          onVisibilityChanged: (bool isVisible) {
            _isShowSettingMenuPanelNotifier.value = isVisible;
          },
          settingItems: _buildSettingItems(),
        );
      },
    );
  }

  /// 优化的缩略图控件
  Widget _buildSeekThumbnailWidgetOptimized() {
    return _OptimizedSeekThumbnailBuilder(
      playController: _playController,
      isDraggingNotifier: _isDraggingNotifier,
      currentSeekTimeNotifier: _currentSeekTimeNotifier,
    );
  }

  /// 优化的浮层视图
  List<Widget> _buildOverlaysOptimized() {
    return widget.overlays.map((overlay) => RepaintBoundary(child: overlay)).toList();
  }

  // 性能优化：防抖的水平拖动处理
  void _onPlayerViewHorizontalDragUpdateOptimized(double delta) {
    _seekDebounceTimer?.cancel();
    _seekDebounceTimer = Timer(const Duration(milliseconds: 16), () {
      _onPlayerViewHorizontalDragUpdate(delta);
    });
  }

  void _onPlayerViewHorizontalDragEndOptimized(double delta) {
    _seekDebounceTimer?.cancel();
    _onPlayerViewHorizontalDragEnd(delta);
  }

  // 性能优化：防抖的垂直拖动处理
  void _onPlayerViewLeftVerticalDragUpdateOptimized(double delta) {
    _brightnessDebounceTimer?.cancel();
    _brightnessDebounceTimer = Timer(const Duration(milliseconds: 32), () {
      _toggleCenterDisplayContentType(ContentViewType.brightness);
      _playController.setBrightnessWithDelta(delta);
    });
  }

  void _onPlayerViewRightVerticalDragUpdateOptimized(double delta) {
    _volumeDebounceTimer?.cancel();
    _volumeDebounceTimer = Timer(const Duration(milliseconds: 32), () {
      _toggleCenterDisplayContentType(ContentViewType.volume);
      _playController.setVolumeWithDelta(delta);
    });
  }

  // 以下方法保持原有功能不变
  void _togglePlayControlVisibility({bool forceHide = false}) {
    if (forceHide || _animationManager.isVisible) {
      _animationManager.hide();
    } else {
      _animationManager.show();
    }
  }

  bool _handleBackPress() {
    if (FullScreenUtil.isFullScreen()) {
      isFullScreen = false;
      exitFullScreen();
      return false;
    } else {
      Navigator.of(context).pop();
      return true;
    }
  }

  void _onDownloadPressed(bool value) {
    SnackBarUtil.warning(context, "download feature to be implemented");
  }

  void _onSnapshotPressed() {
    SnackBarUtil.warning(context, "snapshot feature to be implemented");
  }

  void _onPIPPressed() {
    SnackBarUtil.warning(context, "PIP feature to be implemented");
  }

  Future<void> _onFullScreenPressed() async {
    if (!isFullScreen) {
      isFullScreen = true;
      _playController.getCurrentPosition().then((position) {
        enterFullScreen(position);
      });
    } else {
      isFullScreen = false;
      await exitFullScreen();
    }
  }

  Future<void> enterFullScreen(int currentPosition) async {
    final data = _playController._widgetData;
    if (data == null) return;
    data.startTime = currentPosition;

    AliPlayerWidgetData result = await Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 100),
        pageBuilder: (context, animation, secondaryAnimation) {
          return AliPlayerFullScreenWidget(_playController, data);
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
      ),
    );
    int fullScreenPosition = await result.startTime ?? 0;
    await _playController._aliPlayer.seekTo(fullScreenPosition, result.seekMode);
    _playController.play();
  }

  Future<void> exitFullScreen() async {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    final data = _fullController._widgetData;
    if (data == null) return;

    _fullController.getCurrentPosition().then((position) {
      data.startTime = position;
      _fullController.stop();
      _fullController.destroy();
      Navigator.pop(context, data);
    });
  }

  void _onDragUpdate(Duration duration) {
    _playController.requestThumbnailBitmap(duration);
    _isDraggingNotifier.value = true;
    _currentSeekTimeNotifier.value = duration;
  }

  void _onDragEnd(Duration duration) {
    _isDraggingNotifier.value = false;
    _currentSeekTimeNotifier.value = Duration.zero;
  }

  void _onSeekEnd(Duration duration) {
    _playController.seek(duration);
  }

  List<SettingItem> _buildSettingItems() {
    return [
      SettingItem(
        type: SettingItemType.slider,
        text: "声音",
        startIcon: Icons.volume_down_rounded,
        endIcon: Icons.volume_up_rounded,
        initialValue: _playController.volumeNotifier.value,
        onChanged: (value) => _playController.setVolume(value),
      ),
      SettingItem(
        type: SettingItemType.slider,
        text: "亮度",
        startIcon: Icons.brightness_low_rounded,
        endIcon: Icons.brightness_high_rounded,
        initialValue: _playController.brightnessNotifier.value,
        onChanged: (value) => _playController.setBrightness(value),
      ),
      if (!_isSceneLive())
        SettingItem(
          type: SettingItemType.selector,
          text: "倍速",
          startIcon: Icons.speed_rounded,
          options: SettingConstants.speedOptions,
          initialValue: _playController.speedNotifier.value,
          onChanged: (value) => _playController.setSpeed(speed: value),
          displayFormatter: (option) => "${option}x",
        ),
      if (!_isSceneLive())
        SettingItem(
          type: SettingItemType.selector,
          text: "清晰度",
          startIcon: Icons.hd_rounded,
          options: _playController.trackInfoListNotifier.value,
          initialValue: _playController.currentTrackInfoNotifier.value,
          onChanged: (value) => _playController.selectTrack(value),
          displayFormatter: (option) => TrackInfoUtil.getQuality(option),
        ),
      if (!_isSceneLive())
        SettingItem(
          type: SettingItemType.switcher,
          text: "循环播放",
          startIcon: Icons.loop_rounded,
          initialValue: _playController.isLoopNotifier.value,
          onChanged: (value) => _playController.setLoop(value),
        ),
      SettingItem(
        type: SettingItemType.switcher,
        text: "静音播放",
        startIcon: _playController.isMuteNotifier.value
            ? Icons.volume_off_rounded
            : Icons.volume_up_rounded,
        initialValue: _playController.isMuteNotifier.value,
        onChanged: (value) => _playController.setMute(value),
      ),
      SettingItem(
        type: SettingItemType.selector,
        text: "镜像模式",
        startIcon: Icons.swap_horiz_rounded,
        options: SettingConstants.mirrorModeOptions,
        initialValue: _playController.mirrorModeNotifier.value,
        onChanged: (value) => _playController.setMirrorMode(value),
        displayFormatter: (option) => FormatUtil.formatMirrorMode(option),
      ),
      SettingItem(
        type: SettingItemType.selector,
        text: "旋转模式",
        startIcon: Icons.crop_rotate_rounded,
        options: SettingConstants.rotateModeOptions,
        initialValue: _playController.rotateModeNotifier.value,
        onChanged: (value) => _playController.setRotateMode(value),
        displayFormatter: (option) => "$option°",
      ),
      SettingItem(
        type: SettingItemType.selector,
        text: "渲染填充",
        startIcon: Icons.crop_rounded,
        options: SettingConstants.scaleModeOptions,
        initialValue: _playController.scaleModeNotifier.value,
        onChanged: (value) => _playController.setScaleMode(value),
        displayFormatter: (option) => FormatUtil.formatScaleMode(option),
      ),
    ];
  }

  void _toggleSettingMenuPanel() {
    _togglePlayControlVisibility(forceHide: true);
    _isShowSettingMenuPanelNotifier.value = true;
  }

  Widget _buildSpeedDisplayView() {
    return ValueListenableBuilder(
      valueListenable: _playController.speedNotifier,
      builder: (context, speed, __) {
        return Padding(
          padding: const EdgeInsets.symmetric(
            vertical: 10.0,
            horizontal: 20.0,
          ),
          child: Text(
            '$speed倍速',
            style: const TextStyle(
              color: Colors.black,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        );
      },
    );
  }

  Widget _buildVolumeSlider() {
    return ValueListenableBuilder(
      valueListenable: _playController.volumeNotifier,
      builder: (builder, volume, __) {
        return AliPlayerCustomSliderWidget(
          text: "声音",
          startIcon: Icons.volume_down_rounded,
          endIcon: Icons.volume_up_rounded,
          initialValue: volume,
          isInteractive: false,
        );
      },
    );
  }

  Widget _buildBrightnessSlider() {
    return ValueListenableBuilder(
      valueListenable: _playController.brightnessNotifier,
      builder: (context, brightness, __) {
        return AliPlayerCustomSliderWidget(
          text: "亮度",
          startIcon: Icons.brightness_low_rounded,
          endIcon: Icons.brightness_high_rounded,
          initialValue: brightness,
          isInteractive: false,
        );
      },
    );
  }

  Widget _buildCenterDisplayContentWidget(ContentViewType contentViewType) {
    switch (contentViewType) {
      case ContentViewType.brightness:
        return _buildBrightnessSlider();
      case ContentViewType.volume:
        return _buildVolumeSlider();
      case ContentViewType.speed:
        return _buildSpeedDisplayView();
      default:
        return const SizedBox.shrink();
    }
  }

  void _toggleCenterDisplayContentType(ContentViewType contentType) {
    _contentViewTypeNotifier.value = contentType;
  }

  void _onPlayerViewTap() {
    _togglePlayControlVisibility(forceHide: true);
    _playController.togglePlayState();
  }

  void _onPlayerViewDoubleTap() {
    _playController.togglePlayState();
  }

  void _onPlayerViewLongPress() {
    VibrationUtil.vibrate(duration: 100);
    _toggleCenterDisplayContentType(ContentViewType.speed);
    _playController.setSpeed(speed: 2.0);
  }

  void _onPlayerViewLongPressEnd() {
    VibrationUtil.vibrate(duration: 50);
    _toggleCenterDisplayContentType(ContentViewType.none);
    _playController.setSpeed();
  }

  void _onPlayerViewHorizontalDragUpdate(double delta) {
    VibrationUtil.vibrate(duration: 50);
    _isDraggingNotifier.value = true;

    final totalDuration = _playController.totalDurationNotifier.value;
    final currentPosition = _playController.currentPositionNotifier.value;
    Duration seekDuration = currentPosition + totalDuration * delta;
    int seekMills = seekDuration.inMilliseconds.clamp(
      0,
      totalDuration.inMilliseconds,
    );

    var seekTimeDuration = Duration(milliseconds: seekMills);
    _currentSeekTimeNotifier.value = seekTimeDuration;
    _playController.requestThumbnailBitmap(seekTimeDuration);
  }

  void _onPlayerViewHorizontalDragEnd(double delta) {
    VibrationUtil.vibrate(duration: 100);
    final currentSeekTime = _currentSeekTimeNotifier.value;
    _playController.seek(currentSeekTime);
    _isDraggingNotifier.value = false;
    _currentSeekTimeNotifier.value = Duration.zero;
  }

  void _onPlayerViewLeftVerticalDragEnd(double delta) {
    VibrationUtil.vibrate(duration: 100);
    _toggleCenterDisplayContentType(ContentViewType.none);
  }

  void _onPlayerViewRightVerticalDragEnd(double delta) {
    VibrationUtil.vibrate(duration: 100);
    _toggleCenterDisplayContentType(ContentViewType.none);
  }

  bool _isSceneLive() {
    return _sceneType == SceneType.live;
  }

  bool _isSceneListPlayer() {
    return _sceneType == SceneType.listPlayer;
  }

  @override
  void initState() {
    super.initState();
    logi("[lifecycle] initState");

    _playController = widget._controller;
    _animationManager = SharedAnimationManager(this);
    _sceneType = _playController._widgetData?.sceneType ?? SceneType.vod;

    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    logi("[lifecycle] dispose");

    // 清理防抖Timer
    _seekDebounceTimer?.cancel();
    _volumeDebounceTimer?.cancel();
    _brightnessDebounceTimer?.cancel();

    _disposeValueNotifiers();
    _animationManager.dispose();
    WidgetsBinding.instance.removeObserver(this);

    super.dispose();
  }

  void _disposeValueNotifiers() {
    _contentViewTypeNotifier.dispose();
    _isShowSettingMenuPanelNotifier.dispose();
    _isDraggingNotifier.dispose();
    _currentSeekTimeNotifier.dispose();
  }

  @override
  void didUpdateWidget(covariant AliPlayerWidgetOptimized oldWidget) {
    super.didUpdateWidget(oldWidget);
    logi("[lifecycle] didUpdateWidget");

    if (widget._controller != oldWidget._controller) {
      _playController = widget._controller;
      // 清除缓存，强制重建
      _cachedPlaySurfaceView = null;
      _cachedPlayControlView = null;
      setState(() {});
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    switch (state) {
      case AppLifecycleState.resumed:
        logi("App resumed");
        break;
      case AppLifecycleState.inactive:
        logi("App inactive");
        break;
      case AppLifecycleState.paused:
        logi("App paused");
        break;
      case AppLifecycleState.detached:
        logi("App detached");
        break;
      case AppLifecycleState.hidden:
        logi("App hidden");
        break;
    }
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    // 清除缓存的尺寸，强制重新计算
    _cachedVideoSize = null;
    _cachedPlayerViewSize = null;
    loge("Window metrics changed");
  }

  @override
  void didChangePlatformBrightness() {
    super.didChangePlatformBrightness();
    var widgetsBinding = WidgetsBinding.instance;
    final brightness = widgetsBinding.platformDispatcher.platformBrightness;
    final themeMode = (brightness == Brightness.light ? 'Light' : 'Dark');
    loge("Theme mode changed to $themeMode");
  }
}

/// 优化的底部栏构建器，减少不必要的重建
class _OptimizedBottomBarBuilder extends StatelessWidget {
  final AliPlayerWidgetController playController;
  final SharedAnimationManager animationManager;
  final bool isLive;
  final VoidCallback onPlayIconPressed;
  final VoidCallback onFullScreenPressed;
  final void Function(Duration)? onDragUpdate;
  final void Function(Duration)? onDragEnd;
  final void Function(Duration)? onSeekEnd;

  const _OptimizedBottomBarBuilder({
    required this.playController,
    required this.animationManager,
    required this.isLive,
    required this.onPlayIconPressed,
    required this.onFullScreenPressed,
    this.onDragUpdate,
    this.onDragEnd,
    this.onSeekEnd,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: ValueListenableBuilder(
        valueListenable: playController.playStateNotifier,
        builder: (context, playState, child) {
          return ValueListenableBuilder(
            valueListenable: playController.currentPositionNotifier,
            builder: (context, currentPosition, child) {
              return ValueListenableBuilder(
                valueListenable: playController.bufferedPositionNotifier,
                builder: (context, bufferedPosition, child) {
                  return ValueListenableBuilder(
                    valueListenable: playController.totalDurationNotifier,
                    builder: (context, totalDuration, child) {
                      return AliPlayerBottomBarWidget(
                        animationManager: animationManager,
                        isPlaying: playState == FlutterAvpdef.started,
                        currentPosition: currentPosition,
                        bufferedPosition: bufferedPosition,
                        totalDuration: totalDuration,
                        onPlayIconPressed: onPlayIconPressed,
                        onFullScreenPressed: onFullScreenPressed,
                        onDragUpdate: onDragUpdate,
                        onDragEnd: onDragEnd,
                        onSeekEnd: onSeekEnd,
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

/// 优化的播放状态构建器
class _OptimizedPlayStateBuilder extends StatelessWidget {
  final AliPlayerWidgetController playController;

  const _OptimizedPlayStateBuilder({
    required this.playController,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: playController.playStateNotifier,
      builder: (context, playState, child) {
        if (!playState.shouldBuildWidget) {
          return const SizedBox.shrink();
        }

        return ValueListenableBuilder(
          valueListenable: playController.playErrorNotifier,
          builder: (context, playError, child) {
            final errorCode = playError?.keys.firstOrNull;
            final errorMsg = playError?.values.firstOrNull;

            return AliPlayerPlayStateWidget(
              errorCode: errorCode,
              errorMsg: errorMsg,
            );
          },
        );
      },
    );
  }
}

/// 优化的缩略图构建器
class _OptimizedSeekThumbnailBuilder extends StatelessWidget {
  final AliPlayerWidgetController playController;
  final SafeValueNotifier<bool> isDraggingNotifier;
  final SafeValueNotifier<Duration> currentSeekTimeNotifier;

  const _OptimizedSeekThumbnailBuilder({
    required this.playController,
    required this.isDraggingNotifier,
    required this.currentSeekTimeNotifier,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 30,
      left: 0,
      right: 0,
      child: ValueListenableBuilder(
        valueListenable: isDraggingNotifier,
        builder: (context, isDragging, child) {
          if (!isDragging) return const SizedBox.shrink();

          return ValueListenableBuilder(
            valueListenable: currentSeekTimeNotifier,
            builder: (context, currentSeekTime, child) {
              return ValueListenableBuilder(
                valueListenable: playController.totalDurationNotifier,
                builder: (context, totalDuration, child) {
                  return ValueListenableBuilder(
                    valueListenable: playController.thumbnailNotifier,
                    builder: (context, thumbnail, child) {
                      return AliPlayerSeekThumbnailWidget(
                        isVisible: true,
                        currentSeekTime: currentSeekTime,
                        totalDuration: totalDuration,
                        thumbnail: thumbnail,
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
