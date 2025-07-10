import 'package:flutter/material.dart';
import 'package:aliplayer_widget/aliplayer_widget_lib.dart';
import 'pure_list_performance_page.dart';
import 'performance_comparison_page.dart';

/// 纯净播放器示例页面
///
/// Example page demonstrating pure player widget
class PurePlayerPage extends StatefulWidget {
  const PurePlayerPage({Key? key}) : super(key: key);

  @override
  State<PurePlayerPage> createState() => _PurePlayerPageState();
}

class _PurePlayerPageState extends State<PurePlayerPage> {
  late AliPlayerWidgetController _controller;

  // 示例视频URL - 请替换为实际视频地址
  final String _videoUrl = "https://example.com/sample_video.mp4";

  @override
  void initState() {
    super.initState();
    _initializeController();
  }

  void _initializeController() {
    _controller = AliPlayerWidgetController(context);
    _controller.configure(
      AliPlayerWidgetData.fromUrl(
        videoUrl: _videoUrl,
        videoTitle: "纯净播放器示例",
        sceneType: SceneType.vod,
        autoPlay: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('纯净播放器'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          // 外部控制按钮
          IconButton(
            onPressed: _togglePlayPause,
            icon: const Icon(Icons.play_arrow),
            tooltip: '播放/暂停',
          ),
          IconButton(
            onPressed: _restart,
            icon: const Icon(Icons.replay),
            tooltip: '重新播放',
          ),
        ],
      ),
      body: Column(
        children: [
          // 纯净播放器展示区域
          Expanded(
            flex: 3,
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: AliPlayerWidgetPure(
                  _controller,
                  fit: BoxFit.cover,
                  enableOptimization: true,
                  backgroundColor: Colors.black,
                ),
              ),
            ),
          ),

          // 功能说明和控制区域
          Expanded(
            flex: 2,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '纯净播放器特点：',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  _buildFeatureItem('✨ 无任何UI控制器'),
                  _buildFeatureItem('🎯 只显示视频画面'),
                  _buildFeatureItem('🚫 无手势交互'),
                  _buildFeatureItem('⚡ 性能优化'),
                  _buildFeatureItem('🔧 通过代码控制播放'),
                  _buildFeatureItem('🚀 极简纯净设计'),

                  const SizedBox(height: 16),

                  // 外部控制按钮
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: _togglePlayPause,
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('播放/暂停'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: _restart,
                        icon: const Icon(Icons.replay),
                        label: const Text('重播'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // 播放状态监听示例
                  ValueListenableBuilder(
                    valueListenable: _controller.playStateNotifier,
                    builder: (context, playState, _) {
                      String stateText = _getPlayStateText(playState);
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[800],
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '播放状态: $stateText',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 16),

                  // 导航按钮组
                  Column(
                    children: [
                      // 性能优化列表示例
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const PureListPerformancePage(),
                            ),
                          ),
                          icon: const Icon(Icons.speed),
                          label: const Text('性能优化列表示例'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),

                      // setState vs ValueNotifier 对比
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const PerformanceComparisonPage(),
                            ),
                          ),
                          icon: const Icon(Icons.analytics),
                          label: const Text('setState vs ValueNotifier 对比'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.grey[300],
          fontSize: 14,
        ),
      ),
    );
  }

  String _getPlayStateText(int playState) {
    switch (playState) {
      case FlutterAvpdef.started:
        return '播放中';
      case FlutterAvpdef.paused:
        return '已暂停';
      case FlutterAvpdef.stopped:
        return '已停止';
      case FlutterAvpdef.completion:
        return '播放完成';
      case FlutterAvpdef.error:
        return '播放错误';
      case FlutterAvpdef.prepared:
        return '准备完成';
      default:
        return '未知状态';
    }
  }

  void _togglePlayPause() {
    _controller.togglePlayState();
  }

  void _restart() {
    _controller.replay();
  }

  @override
  void dispose() {
    _controller.destroy();
    super.dispose();
  }
}
