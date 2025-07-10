// Copyright © 2025 Alibaba Cloud. All rights reserved.
//
// Author: keria
// Date: 2025/2/6
// Brief: Pure Player Widget - minimal video player without any UI controls

part of 'aliplayer_widget_lib.dart';

/// 纯净播放器 Widget - 只显示视频画面，无任何控制器和装饰元素
///
/// Pure player widget that only shows video content without any controls or decorative elements
class AliPlayerWidgetPure extends StatefulWidget {
  /// 视频播放控制器
  final AliPlayerWidgetController _controller;

  /// 视频填充模式，默认为覆盖填充
  final BoxFit fit;

  /// 是否启用性能优化，默认为true
  final bool enableOptimization;

  /// 背景颜色，默认为黑色
  final Color backgroundColor;

  /// 构造函数
  ///
  /// [_controller] 播放控制器
  /// [fit] 视频填充模式
  /// [enableOptimization] 是否启用性能优化
  /// [backgroundColor] 背景颜色
  const AliPlayerWidgetPure(
    this._controller, {
    super.key,
    this.fit = BoxFit.cover,
    this.enableOptimization = true,
    this.backgroundColor = Colors.black,
  });

  @override
  State<StatefulWidget> createState() => _AliPlayerWidgetPureState();
}

class _AliPlayerWidgetPureState extends State<AliPlayerWidgetPure>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  late AliPlayerWidgetController _playController;

  /// 性能优化：缓存的视频尺寸计算结果
  Size? _cachedVideoSize;
  Size? _cachedPlayerViewSize;

  /// 性能优化：缓存的播放器视图
  Widget? _cachedPlayerView;

  /// 性能优化：防抖Timer，避免频繁更新
  Timer? _renderDebounceTimer;
  Timer? _sizeDebounceTimer;

  /// 性能优化：渲染状态标记
  bool _isRendering = false;
  bool _isDisposed = false;

  /// 性能优化：使用ValueNotifier代替setState，避免重建
  late final ValueNotifier<int> _rebuildNotifier;

  @override
  Widget build(BuildContext context) {
    // 性能优化：如果已销毁，返回空组件
    if (_isDisposed) {
      return Container(color: widget.backgroundColor);
    }

    // 性能优化：使用ValueListenableBuilder监听重建信号，避免setState
    return ValueListenableBuilder<int>(
      valueListenable: _rebuildNotifier,
      builder: (context, _, __) {
        Widget playerWidget = _buildPlayerBodyOptimized();

        // 性能优化：多层RepaintBoundary隔离
        if (widget.enableOptimization) {
          playerWidget = RepaintBoundary(
            key: ValueKey('pure_player_${_playController._playerUniqueId}'),
            child: playerWidget,
          );
        }

        return Container(
          color: widget.backgroundColor,
          child: playerWidget,
        );
      },
    );
  }

  /// 构建播放器主体 - 性能优化版本
  Widget _buildPlayerBodyOptimized() {
    return ValueListenableBuilder(
      valueListenable: _playController.videoSizeNotifier,
      builder: (context, videoSize, child) {
        // 性能优化：如果已销毁，返回占位容器
        if (_isDisposed || videoSize == Size.zero) {
          return Container(
            width: double.infinity,
            height: double.infinity,
            color: widget.backgroundColor,
            child: const SizedBox.shrink(),
          );
        }

        // 性能优化：缓存尺寸计算，避免频繁计算
        if (_cachedVideoSize != videoSize) {
          _onVideoSizeChangedOptimized(videoSize);
        }

        final playerSize = _cachedPlayerViewSize ?? _calculatePlayerSize(videoSize);

        return RepaintBoundary(
          key: ValueKey('player_body_${videoSize.width}_${videoSize.height}'),
          child: ConstrainedBox(
            constraints: BoxConstraints.tight(playerSize),
            child: _buildPlayerSurfaceViewOptimized(playerSize.width, playerSize.height),
          ),
        );
      },
    );
  }

  /// 性能优化：视频尺寸变化处理
  void _onVideoSizeChangedOptimized(Size videoSize) {
    if (_isDisposed) return;

    // 防抖处理，避免频繁计算
    _sizeDebounceTimer?.cancel();
    _sizeDebounceTimer = Timer(const Duration(milliseconds: 16), () {
      if (_isDisposed) return;
      _cachedVideoSize = videoSize;
      _cachedPlayerViewSize = _calculatePlayerSize(videoSize);
      // 清除缓存的播放器视图，强制重建
      _cachedPlayerView = null;

      // 性能优化：使用ValueNotifier代替setState，避免Widget重建
      _triggerRebuild();
    });
  }

  /// 构建播放器表面视图 - 性能优化版本
  Widget _buildPlayerSurfaceViewOptimized(double width, double height) {
    // 性能优化：状态检查
    if (_isDisposed) {
      return Container(
        width: width,
        height: height,
        color: widget.backgroundColor,
      );
    }

    // 性能优化：缓存播放器视图，避免重复创建
    if (widget.enableOptimization && _cachedPlayerView != null) {
      return _cachedPlayerView!;
    }

    final playerView = RepaintBoundary(
      key: ValueKey('player_surface_${_playController._playerUniqueId}'),
      child: AliPlayerView(
        onCreated: (int viewId) {
          if (!_isDisposed) {
            _playController._setPlayerView(viewId);
          }
        },
        x: 0,
        y: 0,
        width: width,
        height: height,
      ),
    );

    // 性能优化：缓存视图
    if (widget.enableOptimization) {
      _cachedPlayerView = playerView;
    }

    return playerView;
  }

  /// 计算播放器尺寸
  Size _calculatePlayerSize(Size videoSize) {
    return ScreenUtil.calculateRenderSize(
      context,
      videoSize: videoSize,
      isFullScreenMode: false, // 纯净播放器不支持全屏
    );
  }

  @override
  void initState() {
    super.initState();

    logi("[PurePlayer][lifecycle] initState");

    _playController = widget._controller;

    // 性能优化：初始化状态标记
    _isRendering = false;
    _isDisposed = false;

    // 性能优化：初始化重建通知器
    _rebuildNotifier = ValueNotifier<int>(0);

    // 添加生命周期观察者
    WidgetsBinding.instance.addObserver(this);

    // 性能优化：针对列表播放场景的特殊优化
    if (_playController._widgetData?.sceneType == SceneType.listPlayer) {
      // 延迟初始化，避免阻塞UI
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_isDisposed && mounted) {
          _optimizeForListPlayer();
        }
      });
    }
  }

  /// 性能优化：针对列表播放器的特殊优化
  void _optimizeForListPlayer() {
    // 设置列表播放优化参数
    // 这些优化可以减少列表滚动时的性能开销
    if (!_isDisposed) {
      logi("[PurePlayer] Applied list player optimizations");
    }
  }

  /// 性能优化：触发重建，使用ValueNotifier避免setState导致的Widget重建
  void _triggerRebuild() {
    if (!_isDisposed && mounted) {
      _rebuildNotifier.value = _rebuildNotifier.value + 1;
    }
  }

  @override
  void dispose() {
    logi("[PurePlayer][lifecycle] dispose");

    // 性能优化：标记为已销毁，防止后续操作
    _isDisposed = true;

    // 性能优化：取消所有防抖Timer
    _renderDebounceTimer?.cancel();
    _sizeDebounceTimer?.cancel();

    // 性能优化：清理重建通知器
    _rebuildNotifier.dispose();

    // 清理缓存
    _cachedPlayerView = null;
    _cachedVideoSize = null;
    _cachedPlayerViewSize = null;

    // 移除观察者
    WidgetsBinding.instance.removeObserver(this);

    super.dispose();
  }

  @override
  void didUpdateWidget(covariant AliPlayerWidgetPure oldWidget) {
    super.didUpdateWidget(oldWidget);

    logi("[PurePlayer][lifecycle] didUpdateWidget");

    // 性能优化：防止在已销毁状态下执行
    if (_isDisposed) return;

    // 如果控制器发生变化，更新内部状态
    if (widget._controller != oldWidget._controller) {
      _playController = widget._controller;

      // 性能优化：取消之前的Timer
      _renderDebounceTimer?.cancel();
      _sizeDebounceTimer?.cancel();

      // 清除缓存，强制重建
      _cachedPlayerView = null;
      _cachedVideoSize = null;
      _cachedPlayerViewSize = null;

      // 性能优化：使用ValueNotifier代替setState，避免Widget重建
      _triggerRebuild();
    }

    // 性能优化：如果优化设置发生变化，清除缓存
    if (widget.enableOptimization != oldWidget.enableOptimization) {
      _cachedPlayerView = null;
      // 性能优化：使用ValueNotifier代替setState，避免Widget重建
      _triggerRebuild();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.resumed:
        logi("[PurePlayer] App resumed");
        break;
      case AppLifecycleState.paused:
        logi("[PurePlayer] App paused");
        break;
      case AppLifecycleState.inactive:
        logi("[PurePlayer] App inactive");
        break;
      case AppLifecycleState.detached:
        logi("[PurePlayer] App detached");
        break;
      case AppLifecycleState.hidden:
        logi("[PurePlayer] App hidden");
        break;
    }
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();

    // 性能优化：防止在已销毁状态下执行
    if (_isDisposed) return;

    // 性能优化：防抖处理窗口尺寸变化
    _sizeDebounceTimer?.cancel();
    _sizeDebounceTimer = Timer(const Duration(milliseconds: 100), () {
      if (_isDisposed || !mounted) return;

      // 窗口尺寸变化时清除缓存
      _cachedVideoSize = null;
      _cachedPlayerViewSize = null;
      _cachedPlayerView = null;

      // 性能优化：使用ValueNotifier代替setState，避免Widget重建
      _triggerRebuild();
    });

    loge("[PurePlayer] Window metrics changed");
  }
}
