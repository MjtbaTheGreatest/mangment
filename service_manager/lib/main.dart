import 'dart:io';
import 'package:flutter/material.dart';

void main() {
  runApp(const ServiceManagerApp());
}

class ServiceManagerApp extends StatelessWidget {
  const ServiceManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Service Manager',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: const Color(0xFF121212),
        brightness: Brightness.dark,
        useMaterial3: true,
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF2196F3),
          secondary: Color(0xFF00BCD4),
          surface: Color(0xFF1E1E1E),
        ),
      ),
      home: const ServiceManagerHome(),
    );
  }
}

class ServiceManagerHome extends StatefulWidget {
  const ServiceManagerHome({super.key});

  @override
  State<ServiceManagerHome> createState() => _ServiceManagerHomeState();
}

class _ServiceManagerHomeState extends State<ServiceManagerHome> {
  String _apiStatus = 'Unknown';
  String _tunnelStatus = 'Unknown';
  String _apiLogs = 'Loading...';
  String _tunnelLogs = 'Loading...';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _refreshStatus();
  }

  Future<void> _refreshStatus() async {
    setState(() => _isLoading = true);
    
    // Check API status
    final apiStatus = await _checkServiceStatus('TaifManagementAPI');
    if (mounted) setState(() => _apiStatus = apiStatus);
    
    // Check Tunnel status - use correct service name
    final tunnelStatus = await _checkServiceStatus('Cloudflared');
    if (mounted) setState(() => _tunnelStatus = tunnelStatus);
    
    // Load logs
    await _loadApiLogs();
    await _loadTunnelLogs();
    
    if (mounted) setState(() => _isLoading = false);
  }

  Future<String> _checkServiceStatus(String serviceName) async {
    try {
      if (serviceName == 'Cloudflared') {
        // Check if cloudflared process is running
        final result = await Process.run(
          'powershell',
          ['-Command', 'Get-Process cloudflared -ErrorAction SilentlyContinue | Select-Object -First 1'],
        );
        final output = result.stdout.toString().trim();
        return output.isEmpty ? 'Stopped' : 'Running';
      } else {
        final result = await Process.run(
          'powershell',
          ['-Command', 'Get-Service -Name "$serviceName" -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Status'],
        );
        final output = result.stdout.toString().trim();
        if (output.isEmpty) {
          return 'Not Found';
        }
        return output;
      }
    } catch (e) {
      return 'Not Found';
    }
  }

  Future<void> _loadApiLogs() async {
    try {
      final file = File('C:\\code\\my_system\\my_system_api\\logs\\output.log');
      if (await file.exists()) {
        final lines = await file.readAsLines();
        if (mounted) {
          setState(() => _apiLogs = lines.take(20).join('\n'));
        }
      }
    } catch (e) {
      if (mounted) setState(() => _apiLogs = 'No logs available');
    }
  }

  Future<void> _loadTunnelLogs() async {
    setState(() => _tunnelLogs = 'Tunnel running via service');
  }

  Future<void> _startService(String serviceName) async {
    setState(() => _isLoading = true);
    try {
      if (serviceName == 'Cloudflared') {
        // Start Cloudflare Tunnel directly with config
        await Process.run('powershell', [
          '-Command',
          'Start-Process powershell -Verb RunAs -ArgumentList "-NoExit", "-Command", "& \'C:\\Program Files (x86)\\cloudflared\\cloudflared.exe\' tunnel --config \'C:\\Users\\shams\\.cloudflared\\config.yml\' run admin-tunnel"'
        ]);
        _showSnackBar('✅ Tunnel started! Check PowerShell window', Colors.green);
      } else {
        // Start normal service
        await Process.run('powershell', [
          '-Command',
          'Start-Process powershell -Verb RunAs -ArgumentList "-Command", "Start-Service $serviceName -ErrorAction Stop; Write-Output Success; Read-Host \'Press Enter\'"'
        ]);
        _showSnackBar('✅ Service start command sent: $serviceName', Colors.green);
      }
      await Future.delayed(const Duration(seconds: 2));
      await _refreshStatus();
    } catch (e) {
      if (mounted) {
        _showSnackBar('❌ Error: $e', Colors.red);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _stopService(String serviceName) async {
    setState(() => _isLoading = true);
    try {
      if (serviceName == 'Cloudflared') {
        // Kill cloudflared process
        await Process.run('powershell', [
          '-Command',
          'Start-Process powershell -Verb RunAs -ArgumentList "-Command", "Get-Process cloudflared -ErrorAction SilentlyContinue | Stop-Process -Force; Write-Output Done; Read-Host \'Press Enter\'"'
        ]);
        _showSnackBar('⏸️ Tunnel stopped! Close PowerShell window if open', Colors.orange);
      } else {
        await Process.run('powershell', [
          '-Command',
          'Start-Process powershell -Verb RunAs -ArgumentList "-Command", "Stop-Service $serviceName -ErrorAction Stop; Write-Output Success; Read-Host \'Press Enter\'"'
        ]);
        _showSnackBar('⏸️ Service stop command sent: $serviceName', Colors.orange);
      }
      await Future.delayed(const Duration(seconds: 2));
      await _refreshStatus();
    } catch (e) {
      if (mounted) {
        _showSnackBar('❌ Error: $e', Colors.red);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _restartService(String serviceName) async {
    setState(() => _isLoading = true);
    try {
      if (serviceName == 'Cloudflared') {
        // Stop then start tunnel
        await Process.run('powershell', [
          '-Command',
          'Get-Process cloudflared -ErrorAction SilentlyContinue | Stop-Process -Force'
        ]);
        await Future.delayed(const Duration(seconds: 2));
        await Process.run('powershell', [
          '-Command',
          'Start-Process powershell -Verb RunAs -ArgumentList "-NoExit", "-Command", "& \'C:\\Program Files (x86)\\cloudflared\\cloudflared.exe\' tunnel --config \'C:\\Users\\shams\\.cloudflared\\config.yml\' run admin-tunnel"'
        ]);
        _showSnackBar('🔄 Tunnel restarted! Check PowerShell window', Colors.blue);
      } else {
        await Process.run('powershell', [
          '-Command',
          'Start-Process powershell -Verb RunAs -ArgumentList "-Command", "Restart-Service $serviceName -ErrorAction Stop; Write-Output Success; Read-Host \'Press Enter\'"'
        ]);
        _showSnackBar('🔄 Service restart command sent: $serviceName', Colors.blue);
      }
      await Future.delayed(const Duration(seconds: 3));
      await _refreshStatus();
    } catch (e) {
      if (mounted) {
        _showSnackBar('❌ Error: $e', Colors.red);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _testApi() async {
    setState(() => _isLoading = true);
    try {
      final result = await Process.run('powershell', [
        '-Command',
        r'try { $response = Invoke-WebRequest -Uri "http://localhost:53365" -Method GET -TimeoutSec 5 -ErrorAction Stop; Write-Output "Success: $($response.StatusCode)" } catch { Write-Output "Status: $($_.Exception.Message)" }'
      ]);
      if (mounted) {
        final output = result.stdout.toString();
        if (output.contains('404') || output.contains('401') || output.contains('Success')) {
          _showSnackBar('✅ API is responding on port 53365!', Colors.green);
        } else if (output.contains('refused') || output.contains('failed')) {
          _showSnackBar('❌ API not responding - Service may be stopped', Colors.red);
        } else {
          _showSnackBar('⚠️ Unexpected response', Colors.orange);
        }
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('❌ Cannot connect to API', Colors.red);
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _testTunnel() async {
    setState(() => _isLoading = true);
    try {
      final result = await Process.run('powershell', [
        '-Command',
        r'try { $response = Invoke-WebRequest -Uri "https://admin.taif.digital" -Method GET -TimeoutSec 10 -ErrorAction Stop; Write-Output "Success: $($response.StatusCode)" } catch { Write-Output "Status: $($_.Exception.Message)" }'
      ]);
      if (mounted) {
        final output = result.stdout.toString();
        if (output.contains('404') || output.contains('401') || output.contains('Success')) {
          _showSnackBar('✅ Tunnel is working! Domain is accessible', Colors.green);
        } else if (output.contains('530')) {
          _showSnackBar('❌ Tunnel error 530 - Service may be stopped', Colors.red);
        } else if (output.contains('failed') || output.contains('refused')) {
          _showSnackBar('❌ Cannot reach domain - Check tunnel service', Colors.red);
        } else {
          _showSnackBar('⚠️ Unexpected response', Colors.orange);
        }
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('❌ Cannot connect to tunnel', Colors.red);
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Color _getStatusColor(String status) {
    final s = status.toLowerCase();
    if (s.contains('running')) return Colors.cyan;
    if (s.contains('stopped')) return Colors.red.shade400;
    if (s.contains('not found')) return Colors.grey.shade600;
    if (s.contains('stoppending') || s.contains('startpending')) return Colors.orange;
    return Colors.amber;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF1565C0),
                const Color(0xFF0D47A1),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.settings_system_daydream_rounded, size: 26),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Service Manager',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: IconButton(
                  icon: Icon(
                    Icons.refresh_rounded,
                    color: _isLoading ? Colors.white54 : Colors.white,
                  ),
                  onPressed: _isLoading ? null : _refreshStatus,
                  tooltip: 'Refresh Status',
                ),
              ),
            ],
          ),
        ),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        child: _isLoading
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 70,
                      height: 70,
                      child: CircularProgressIndicator(
                        color: Colors.blue,
                        strokeWidth: 5,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Loading...',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              )
            : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildServiceCard(
                    title: '🖥️ Backend API',
                    serviceName: 'TaifManagementAPI',
                    status: _apiStatus,
                    logs: _apiLogs,
                    onStart: () => _startService('TaifManagementAPI'),
                    onStop: () => _stopService('TaifManagementAPI'),
                    onRestart: () => _restartService('TaifManagementAPI'),
                    onTest: _testApi,
                  ),
                  const SizedBox(height: 16),
                  _buildServiceCard(
                    title: '🌐 Cloudflare Tunnel',
                    serviceName: 'Cloudflared',
                    status: _tunnelStatus,
                    logs: _tunnelLogs,
                    onStart: () => _startService('Cloudflared'),
                    onStop: () => _stopService('Cloudflared'),
                    onRestart: () => _restartService('Cloudflared'),
                    onTest: _testTunnel,
                  ),
                  const SizedBox(height: 24),
                  _buildQuickActions(),
                ],
              ),
            ),
      ),
    );
  }

  Widget _buildServiceCard({
    required String title,
    required String serviceName,
    required String status,
    required String logs,
    required VoidCallback onStart,
    required VoidCallback onStop,
    required VoidCallback onRestart,
    required VoidCallback onTest,
  }) {
    final isRunning = status.toLowerCase().contains('running');
    return TweenAnimationBuilder(
      duration: const Duration(milliseconds: 400),
      tween: Tween<double>(begin: 0, end: 1),
      builder: (context, double value, child) {
        return Transform.scale(
          scale: 0.95 + (value * 0.05),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF1E1E1E),
              const Color(0xFF2A2A2A),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: (isRunning ? Colors.green : Colors.red).withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: (isRunning ? Colors.green : Colors.red).withOpacity(0.4),
                width: 1.5,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF2196F3),
                        const Color(0xFF1976D2),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    title.contains('Backend') ? Icons.storage_rounded : Icons.cloud_queue_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        serviceName,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white54,
                        ),
                      ),
                    ],
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _getStatusColor(status),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _getStatusColor(status),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        status,
                        style: TextStyle(
                          color: _getStatusColor(status),
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    label: 'Start',
                    icon: Icons.play_arrow_rounded,
                    color: const Color(0xFF4CAF50),
                    onPressed: onStart,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildActionButton(
                    label: 'Stop',
                    icon: Icons.stop_rounded,
                    color: const Color(0xFFF44336),
                    onPressed: onStop,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    label: 'Restart',
                    icon: Icons.refresh_rounded,
                    color: const Color(0xFF2196F3),
                    onPressed: onRestart,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildActionButton(
                    label: 'Test',
                    icon: Icons.check_circle_rounded,
                    color: const Color(0xFFFF9800),
                    onPressed: onTest,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1976D2).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.article_rounded, color: Color(0xFF64B5F6), size: 16),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Activity Logs',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white70,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A2E),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
              ),
              constraints: const BoxConstraints(maxHeight: 150),
              child: SingleChildScrollView(
                child: Text(
                  logs,
                  style: const TextStyle(
                    fontFamily: 'Consolas',
                    fontSize: 12,
                    color: Color(0xFF81C784),
                    height: 1.6,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        child: ElevatedButton(
          onPressed: _isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            elevation: 4,
            shadowColor: color.withOpacity(0.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 22),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1E88E5).withOpacity(0.1),
            const Color(0xFF1565C0).withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF42A5F5), Color(0xFF1E88E5)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2196F3).withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 14),
              const Text(
                'Quick Actions',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 2.5,
            children: [
              _buildQuickButton(
                'Restart All',
                Icons.restart_alt_rounded,
                const Color(0xFF9C27B0),
                () async {
                  await _restartService('TaifManagementAPI');
                  await _restartService('Cloudflared');
                },
              ),
              _buildQuickButton(
                'Test All',
                Icons.check_circle_outline_rounded,
                const Color(0xFF00897B),
                () async {
                  await _testApi();
                  await Future.delayed(const Duration(seconds: 1));
                  await _testTunnel();
                },
              ),
              _buildQuickButton(
                'Open Logs',
                Icons.folder_open_rounded,
                const Color(0xFFFB8C00),
                () async {
                  await Process.run('explorer', ['C:\\code\\my_system\\my_system_api\\logs']);
                },
              ),
              _buildQuickButton(
                'Open Domain',
                Icons.language_rounded,
                const Color(0xFF1976D2),
                () async {
                  await Process.run('explorer', ['https://admin.taif.digital']);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickButton(String label, IconData icon, Color color, VoidCallback onPressed) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: ElevatedButton(
        onPressed: _isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color.withOpacity(0.15),
          foregroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: color.withOpacity(0.3), width: 1),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 28, color: color),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
