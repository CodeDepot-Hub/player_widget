import 'package:flutter/material.dart';
import 'dart:async';

/// 性能对比页面 - setState vs ValueNotifier
///
/// Performance comparison page showing setState vs ValueNotifier
class PerformanceComparisonPage extends StatefulWidget {
  const PerformanceComparisonPage({Key? key}) : super(key: key);

  @override
  State<PerformanceComparisonPage> createState() => _PerformanceComparisonPageState();
}

class _PerformanceComparisonPageState extends State<PerformanceComparisonPage> {
  int _setStateBuilds = 0;
  int _valueNotifierBuilds = 0;
  Timer? _performanceTimer;
  bool _isRunning = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('性能对比：setState vs ValueNotifier'),
        backgroundColor: Colors.grey[900],
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 说明文本
            _buildExplanationCard(),

            const SizedBox(height: 20),

            // 对比区域
            Expanded(
              child: Row(
                children: [
                  // setState 示例
                  Expanded(
                    child: _buildSetStateExample(),
                  ),

                  const SizedBox(width: 16),

                  // ValueNotifier 示例
                  Expanded(
                    child: _buildValueNotifierExample(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 控制按钮
            _buildControlButtons(),

            const SizedBox(height: 20),

            // 性能统计
            _buildPerformanceStats(),
          ],
        ),
      ),
    );
  }

  Widget _buildExplanationCard() {
    return Card(
      color: Colors.grey[900],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '🔍 性能对比实验',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '左侧使用传统的 setState() 方法，右侧使用优化的 ValueNotifier。\n观察两者在频繁更新时的构建次数差异。',
              style: TextStyle(
                color: Colors.grey[300],
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSetStateExample() {
    return Card(
      color: Colors.red[900],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.warning, color: Colors.red, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'setState 方式',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 构建次数显示
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[800],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '构建次数:',
                    style: TextStyle(color: Colors.white),
                  ),
                  Text(
                    '$_setStateBuilds',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 性能问题说明
            _buildPerformanceIssues(),

            Expanded(
              child: _SetStateExample(
                onBuild: () {
                  setState(() {
                    _setStateBuilds++;
                  });
                },
                isRunning: _isRunning,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildValueNotifierExample() {
    return Card(
      color: Colors.green[900],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'ValueNotifier 方式',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 构建次数显示
            ValueListenableBuilder<int>(
              valueListenable: _valueNotifierBuildsNotifier,
              builder: (context, builds, _) {
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green[800],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '构建次数:',
                        style: TextStyle(color: Colors.white),
                      ),
                      Text(
                        '$builds',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 16),

            // 优化优势说明
            _buildOptimizationBenefits(),

            Expanded(
              child: _ValueNotifierExample(
                onBuild: () {
                  _valueNotifierBuildsNotifier.value++;
                },
                isRunning: _isRunning,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceIssues() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.red[700],
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '❌ 性能问题:',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          ..._buildIssueList([
            '整个Widget树重建',
            '高CPU使用率',
            '频繁内存分配',
            '布局重复计算',
          ]),
        ],
      ),
    );
  }

  Widget _buildOptimizationBenefits() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.green[700],
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '✅ 优化优势:',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          ..._buildIssueList([
            '精确局部更新',
            '低CPU使用率',
            '内存使用优化',
            '避免重复计算',
          ]),
        ],
      ),
    );
  }

  List<Widget> _buildIssueList(List<String> items) {
    return items
        .map((item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 1),
              child: Text(
                '• $item',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                ),
              ),
            ))
        .toList();
  }

  Widget _buildControlButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _isRunning ? _stopPerformanceTest : _startPerformanceTest,
            icon: Icon(_isRunning ? Icons.stop : Icons.play_arrow),
            label: Text(_isRunning ? '停止测试' : '开始测试'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _isRunning ? Colors.red : Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _resetCounters,
            icon: const Icon(Icons.refresh),
            label: const Text('重置计数'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPerformanceStats() {
    final efficiency =
        _setStateBuilds > 0 ? (1 - (_valueNotifierBuilds / _setStateBuilds)) * 100 : 0.0;

    return Card(
      color: Colors.grey[800],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              '📊 性能统计',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  'setState构建',
                  '$_setStateBuilds',
                  Colors.red,
                ),
                _buildStatItem(
                  'ValueNotifier构建',
                  '$_valueNotifierBuilds',
                  Colors.green,
                ),
                _buildStatItem(
                  '效率提升',
                  '${efficiency.toStringAsFixed(1)}%',
                  Colors.blue,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  final ValueNotifier<int> _valueNotifierBuildsNotifier = ValueNotifier<int>(0);

  void _startPerformanceTest() {
    setState(() {
      _isRunning = true;
    });

    // 模拟高频更新场景
    _performanceTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      // 模拟视频尺寸变化等场景
    });
  }

  void _stopPerformanceTest() {
    setState(() {
      _isRunning = false;
    });
    _performanceTimer?.cancel();
  }

  void _resetCounters() {
    setState(() {
      _setStateBuilds = 0;
    });
    _valueNotifierBuilds = 0;
    _valueNotifierBuildsNotifier.value = 0;
  }

  @override
  void dispose() {
    _performanceTimer?.cancel();
    _valueNotifierBuildsNotifier.dispose();
    super.dispose();
  }
}

/// setState 示例组件
class _SetStateExample extends StatefulWidget {
  final VoidCallback onBuild;
  final bool isRunning;

  const _SetStateExample({
    required this.onBuild,
    required this.isRunning,
  });

  @override
  State<_SetStateExample> createState() => _SetStateExampleState();
}

class _SetStateExampleState extends State<_SetStateExample> {
  int _counter = 0;
  Timer? _updateTimer;

  @override
  void didUpdateWidget(_SetStateExample oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isRunning != oldWidget.isRunning) {
      if (widget.isRunning) {
        _startUpdates();
      } else {
        _stopUpdates();
      }
    }
  }

  void _startUpdates() {
    _updateTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      setState(() {
        _counter++;
        widget.onBuild(); // 每次 setState 都会调用 onBuild
      });
    });
  }

  void _stopUpdates() {
    _updateTimer?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    // 每次 build 都会被调用
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red[800],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red, width: 2),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            '模拟视频播放器',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '更新次数: $_counter',
            style: const TextStyle(color: Colors.white),
          ),
          const SizedBox(height: 8),
          const Text(
            '⚠️ 每次更新都会重建\n整个Widget树',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.yellow,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
  }
}

/// ValueNotifier 示例组件
class _ValueNotifierExample extends StatefulWidget {
  final VoidCallback onBuild;
  final bool isRunning;

  const _ValueNotifierExample({
    required this.onBuild,
    required this.isRunning,
  });

  @override
  State<_ValueNotifierExample> createState() => _ValueNotifierExampleState();
}

class _ValueNotifierExampleState extends State<_ValueNotifierExample> {
  final ValueNotifier<int> _counterNotifier = ValueNotifier<int>(0);
  Timer? _updateTimer;

  @override
  void didUpdateWidget(_ValueNotifierExample oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isRunning != oldWidget.isRunning) {
      if (widget.isRunning) {
        _startUpdates();
      } else {
        _stopUpdates();
      }
    }
  }

  void _startUpdates() {
    _updateTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      // 只更新 ValueNotifier，不调用 setState
      _counterNotifier.value++;
      // 只有在实际需要重建时才调用
      if (_counterNotifier.value % 10 == 0) {
        widget.onBuild(); // 大大减少构建次数
      }
    });
  }

  void _stopUpdates() {
    _updateTimer?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    // build 方法调用次数大大减少
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green[800],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green, width: 2),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            '优化的视频播放器',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ValueListenableBuilder<int>(
            valueListenable: _counterNotifier,
            builder: (context, counter, _) {
              return Text(
                '更新次数: $counter',
                style: const TextStyle(color: Colors.white),
              );
            },
          ),
          const SizedBox(height: 8),
          const Text(
            '✅ 只在需要时重建\n局部精确更新',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.lightGreen,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    _counterNotifier.dispose();
    super.dispose();
  }
}
