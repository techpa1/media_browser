import 'package:flutter/material.dart';
import 'package:media_browser/media_browser.dart';

/// Example showing how to use enhanced permission states
/// to provide better user experience and avoid unnecessary permission dialogs
class EnhancedPermissionExample extends StatefulWidget {
  const EnhancedPermissionExample({super.key});

  @override
  State<EnhancedPermissionExample> createState() =>
      _EnhancedPermissionExampleState();
}

class _EnhancedPermissionExampleState extends State<EnhancedPermissionExample> {
  final MediaBrowser _mediaBrowser = MediaBrowser();
  PermissionResult? _permissionResult;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    setState(() => _isLoading = true);

    try {
      final result = await _mediaBrowser.checkPermissions(MediaType.audio);
      setState(() {
        _permissionResult = result;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Failed to check permissions: $e');
    }
  }

  Future<void> _requestPermissions() async {
    setState(() => _isLoading = true);

    try {
      final result = await _mediaBrowser.requestPermissions(MediaType.audio);
      setState(() {
        _permissionResult = result;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Failed to request permissions: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showPermissionRationale() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permission Required'),
        content: const Text(
          'This app needs access to your music library to play audio files. '
          'Please grant permission to continue.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _requestPermissions();
            },
            child: const Text('Grant Permission'),
          ),
        ],
      ),
    );
  }

  void _openAppSettings() {
    // Note: You would need to use a package like 'app_settings' to open app settings
    _showError('Please go to app settings and enable music library permission');
  }

  Widget _buildPermissionButton() {
    if (_permissionResult == null) return const SizedBox.shrink();

    // Check if we have any missing permissions
    final missingPermissions = _permissionResult!.missingPermissions ?? [];
    if (missingPermissions.isEmpty) {
      return const Card(
        child: ListTile(
          leading: Icon(Icons.check_circle, color: Colors.green),
          title: Text('All permissions granted'),
          subtitle: Text('You can now access your music library'),
        ),
      );
    }

    // Find the first missing permission to determine the action
    final firstPermission = missingPermissions.first;

    return Card(
      child: ListTile(
        leading: Icon(
          _getPermissionIcon(firstPermission.status),
          color: _getPermissionColor(firstPermission.status),
        ),
        title: Text(_getPermissionTitle(firstPermission.status)),
        subtitle: Text(_getPermissionSubtitle(firstPermission)),
        trailing: _buildActionButton(firstPermission),
      ),
    );
  }

  IconData _getPermissionIcon(PermissionStatus status) {
    switch (status) {
      case PermissionStatus.granted:
        return Icons.check_circle;
      case PermissionStatus.denied:
        return Icons.warning;
      case PermissionStatus.permanentlyDenied:
        return Icons.block;
      case PermissionStatus.restricted:
        return Icons.lock;
      default:
        return Icons.help;
    }
  }

  Color _getPermissionColor(PermissionStatus status) {
    switch (status) {
      case PermissionStatus.granted:
        return Colors.green;
      case PermissionStatus.denied:
        return Colors.orange;
      case PermissionStatus.permanentlyDenied:
        return Colors.red;
      case PermissionStatus.restricted:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getPermissionTitle(PermissionStatus status) {
    switch (status) {
      case PermissionStatus.granted:
        return 'Permission Granted';
      case PermissionStatus.denied:
        return 'Permission Required';
      case PermissionStatus.permanentlyDenied:
        return 'Permission Blocked';
      case PermissionStatus.restricted:
        return 'Permission Restricted';
      case PermissionStatus.notDetermined:
        return 'Permission Not Requested';
      default:
        return 'Permission Unknown';
    }
  }

  String _getPermissionSubtitle(MediaPermission permission) {
    switch (permission.status) {
      case PermissionStatus.notDetermined:
        return 'Tap to request permission (iOS will show system dialog)';
      case PermissionStatus.denied:
        if (permission.shouldShowRationale) {
          return 'Tap to see why this permission is needed';
        } else {
          return 'Tap to request permission again';
        }
      case PermissionStatus.permanentlyDenied:
        return 'Go to app settings to enable permission';
      default:
        return 'Permission status: ${permission.status.name}';
    }
  }

  Widget _buildActionButton(MediaPermission permission) {
    // Platform-specific permission logic:
    // Android: Show dialog for denied (can retry) or permanently_denied (go to settings)
    // iOS: Direct request for notDetermined (OS shows dialog), denied goes to settings

    if (permission.status == PermissionStatus.notDetermined) {
      // iOS: Direct request - OS will show permission dialog
      return ElevatedButton(
        onPressed: _requestPermissions,
        child: const Text('Request Permission'),
      );
    } else if (permission.status == PermissionStatus.denied) {
      // Android: Can retry - show dialog
      if (permission.shouldShowRationale) {
        return ElevatedButton(
          onPressed: _showPermissionRationale,
          child: const Text('Why?'),
        );
      } else {
        return ElevatedButton(
          onPressed: _requestPermissions,
          child: const Text('Grant'),
        );
      }
    } else if (permission.status == PermissionStatus.permanentlyDenied) {
      // Both platforms: Go to settings
      return ElevatedButton(
        onPressed: _openAppSettings,
        child: const Text('Settings'),
      );
    }

    // No action needed for granted, restricted, limited, provisional
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Enhanced Permission Example'),
        actions: [
          IconButton(
            onPressed: _checkPermissions,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Permission States Example',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'This example shows how to use enhanced permission states to provide better user experience:',
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  const Text('• Shows rationale when needed (Android)'),
                  const Text('• Requests permission when possible'),
                  const Text('• Guides to settings when permanently denied'),
                  const Text('• iOS: Direct request (OS shows dialog)'),
                  const Text('• Android: App shows dialog for retries'),
                  const SizedBox(height: 24),
                  _buildPermissionButton(),
                  const SizedBox(height: 24),
                  if (_permissionResult != null) ...[
                    const Text(
                      'Permission Details:',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ...(_permissionResult!.missingPermissions ?? []).map(
                      (permission) => Card(
                        child: ListTile(
                          title: Text(permission.name),
                          subtitle: Text(permission.description),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('Status: ${permission.status.name}'),
                              Text('Can Request: ${permission.canRequest}'),
                              Text(
                                  'Show Rationale: ${permission.shouldShowRationale}'),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}
