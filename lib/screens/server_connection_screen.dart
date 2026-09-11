import 'package:flutter/material.dart';

import '../services/api_service.dart';
import 'home_screen.dart';

class ServerConnectionScreen extends StatefulWidget {
  final ApiService apiService;

  const ServerConnectionScreen({
    super.key,
    required this.apiService,
  });

  @override
  State<ServerConnectionScreen> createState() =>
      _ServerConnectionScreenState();
}

class _ServerConnectionScreenState
    extends State<ServerConnectionScreen> {
  final TextEditingController _ipController =
  TextEditingController();

  bool _isConnecting = false;
  String? _errorMessage;

  bool _isValidIp(String value) {
    final String ip = value.trim();

    final RegExp ipv4Pattern = RegExp(
      r'^((25[0-5]|2[0-4][0-9]|1?[0-9]?[0-9])\.){3}'
      r'(25[0-5]|2[0-4][0-9]|1?[0-9]?[0-9])$',
    );

    return ipv4Pattern.hasMatch(ip);
  }

  Future<void> _connect() async {
    FocusScope.of(context).unfocus();

    final String ip = _ipController.text.trim();

    if (!_isValidIp(ip)) {
      setState(() {
        _errorMessage =
        'Please enter a valid IPv4 address.';
      });

      return;
    }

    setState(() {
      _isConnecting = true;
      _errorMessage = null;
    });

    widget.apiService.setServerIp(ip);

    final bool connected =
    await widget.apiService.checkConnection();

    if (!mounted) {
      return;
    }

    setState(() {
      _isConnecting = false;
    });

    if (connected) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => HomeScreen(
            apiService: widget.apiService,
          ),
        ),
      );

      return;
    }

    setState(() {
      _errorMessage =
      'Unable to connect to the PHP API.\n\n'
          'Make sure the server is running and '
          'the IP address is correct.';
    });

    await _showConnectionError();
  }

  Future<void> _showConnectionError() async {
    if (!mounted) {
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(
                Icons.cloud_off_rounded,
                color: Colors.redAccent,
              ),
              SizedBox(width: 10),
              Text('Connection Failed'),
            ],
          ),
          content: const Text(
            'The PHP API could not be reached.\n\n'
                'Please check the server IP address '
                'and make sure XAMPP/Apache is running.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _ipController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 430,
              ),
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 86,
                    height: 86,
                    decoration: BoxDecoration(
                      borderRadius:
                      BorderRadius.circular(26),
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF6D7CFF),
                          Color(0xFF3948C7),
                        ],
                      ),
                    ),
                    child: const Icon(
                      Icons.inventory_2_rounded,
                      size: 42,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 28),

                  const Text(
                    'EquipTrack',
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1.2,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    'Campus Equipment Management',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white
                          .withValues(alpha: 0.55),
                    ),
                  ),

                  const SizedBox(height: 48),

                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      borderRadius:
                      BorderRadius.circular(26),
                      color: const Color(0xFF12141A),
                      border: Border.all(
                        color: Colors.white
                            .withValues(alpha: 0.07),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Connect to Server',
                          style: TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.w700,
                          ),
                        ),

                        const SizedBox(height: 8),

                        Text(
                          'Enter the local IP address of '
                              'the computer running the PHP API.',
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.5,
                            color: Colors.white
                                .withValues(alpha: 0.50),
                          ),
                        ),

                        const SizedBox(height: 22),

                        TextField(
                          controller: _ipController,
                          keyboardType:
                          TextInputType.number,
                          textInputAction:
                          TextInputAction.done,
                          onSubmitted: (_) {
                            if (!_isConnecting) {
                              _connect();
                            }
                          },
                          decoration:
                          InputDecoration(
                            labelText:
                            'Server IP Address',
                            hintText:
                            '192.168.1.100',
                            prefixIcon: const Icon(
                              Icons.dns_rounded,
                            ),
                            errorText:
                            _errorMessage != null
                                ? null
                                : null,
                          ),
                        ),

                        if (_errorMessage != null) ...[
                          const SizedBox(height: 14),
                          Container(
                            padding:
                            const EdgeInsets.all(13),
                            decoration:
                            BoxDecoration(
                              color: Colors.redAccent
                                  .withValues(
                                alpha: 0.08,
                              ),
                              borderRadius:
                              BorderRadius.circular(
                                14,
                              ),
                              border: Border.all(
                                color: Colors.redAccent
                                    .withValues(
                                  alpha: 0.20,
                                ),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons
                                      .error_outline_rounded,
                                  size: 20,
                                  color:
                                  Colors.redAccent,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style:
                                    const TextStyle(
                                      fontSize: 12,
                                      height: 1.4,
                                      color:
                                      Colors.redAccent,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 22),

                        SizedBox(
                          height: 54,
                          child: FilledButton(
                            onPressed: _isConnecting
                                ? null
                                : _connect,
                            child: _isConnecting
                                ? const SizedBox(
                              width: 22,
                              height: 22,
                              child:
                              CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color:
                                Colors.white,
                              ),
                            )
                                : const Row(
                              mainAxisAlignment:
                              MainAxisAlignment
                                  .center,
                              children: [
                                Icon(
                                  Icons
                                      .wifi_find_rounded,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Connect to Server',
                                  style: TextStyle(
                                    fontWeight:
                                    FontWeight
                                        .w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  Row(
                    mainAxisAlignment:
                    MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.lock_outline_rounded,
                        size: 15,
                        color: Colors.white
                            .withValues(alpha: 0.35),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Server connection required',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white
                              .withValues(alpha: 0.35),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}