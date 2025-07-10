import 'package:flutter/material.dart';
import 'package:aliplayer_widget/aliplayer_widget_lib.dart';

/// 最简纯净播放器示例 - 只显示视频，无任何多余元素
///
/// Minimal pure player example - only video display, no extra elements
class MinimalPurePlayerExample extends StatefulWidget {
  const MinimalPurePlayerExample({Key? key}) : super(key: key);

  @override
  State<MinimalPurePlayerExample> createState() => _MinimalPurePlayerExampleState();
}

class _MinimalPurePlayerExampleState extends State<MinimalPurePlayerExample> {
  late AliPlayerWidgetController _controller;

  @override
  void initState() {
    super.initState();

    // 最简配置
    _controller = AliPlayerWidgetController(context);
    _controller.configure(
      AliPlayerWidgetData.fromUrl(
        videoUrl: "https://your-video-url.mp4",
        autoPlay: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('最简纯净播放器'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.black,
      body: Column(
        children: [
          // 纯净播放器 - 只显示视频
          Expanded(
            child: AliPlayerWidgetPure(_controller),
          ),

          // 简单的外部控制
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: () => _controller.play(),
                  icon: const Icon(Icons.play_arrow, color: Colors.white),
                  iconSize: 32,
                ),
                const SizedBox(width: 20),
                IconButton(
                  onPressed: () => _controller.pause(),
                  icon: const Icon(Icons.pause, color: Colors.white),
                  iconSize: 32,
                ),
                const SizedBox(width: 20),
                IconButton(
                  onPressed: () => _controller.replay(),
                  icon: const Icon(Icons.replay, color: Colors.white),
                  iconSize: 32,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.destroy();
    super.dispose();
  }
}

/// 背景视频示例 - 视频作为页面背景
///
/// Background video example - video as page background
class BackgroundVideoExample extends StatefulWidget {
  const BackgroundVideoExample({Key? key}) : super(key: key);

  @override
  State<BackgroundVideoExample> createState() => _BackgroundVideoExampleState();
}

class _BackgroundVideoExampleState extends State<BackgroundVideoExample> {
  late AliPlayerWidgetController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AliPlayerWidgetController(context);
    _controller.configure(
      AliPlayerWidgetData.fromUrl(
        videoUrl: "https://your-background-video.mp4",
        autoPlay: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 背景视频 - 填满整个屏幕
          Positioned.fill(
            child: AliPlayerWidgetPure(
              _controller,
              fit: BoxFit.cover,
            ),
          ),

          // 前景内容
          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  '欢迎使用',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        blurRadius: 10.0,
                        color: Colors.black,
                        offset: Offset(2.0, 2.0),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  '纯净播放器',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    shadows: [
                      Shadow(
                        blurRadius: 10.0,
                        color: Colors.black,
                        offset: Offset(2.0, 2.0),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed: () {
                    // 可以在这里添加其他页面跳转等逻辑
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.2),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                  child: const Text('开始体验'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.destroy();
    super.dispose();
  }
}

/// 商品展示视频示例
///
/// Product showcase video example
class ProductVideoExample extends StatefulWidget {
  final String videoUrl;
  final String productName;

  const ProductVideoExample({
    Key? key,
    required this.videoUrl,
    required this.productName,
  }) : super(key: key);

  @override
  State<ProductVideoExample> createState() => _ProductVideoExampleState();
}

class _ProductVideoExampleState extends State<ProductVideoExample> {
  late AliPlayerWidgetController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AliPlayerWidgetController(context);
    _controller.configure(
      AliPlayerWidgetData.fromUrl(
        videoUrl: widget.videoUrl,
        autoPlay: false, // 商品展示视频通常不自动播放
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // 视频展示区域
          AspectRatio(
            aspectRatio: 16 / 9,
            child: AliPlayerWidgetPure(_controller),
          ),

          // 商品信息
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.productName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: () => _controller.play(),
                      icon: const Icon(Icons.play_arrow, size: 16),
                      label: const Text('播放'),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(60, 30),
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: () => _controller.pause(),
                      icon: const Icon(Icons.pause, size: 16),
                      label: const Text('暂停'),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(60, 30),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.destroy();
    super.dispose();
  }
}
