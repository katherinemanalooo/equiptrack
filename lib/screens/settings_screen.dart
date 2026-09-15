import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../services/api_service.dart';

class SettingsScreen extends StatefulWidget {
  final ApiService apiService;
  final bool autoRefresh;
  final bool darkMode;
  final ValueChanged<bool> onAutoRefreshChanged;
  final ValueChanged<bool> onDarkModeChanged;
  final Future<bool> Function() onTestConnection;

  const SettingsScreen({
    super.key,
    required this.apiService,
    required this.autoRefresh,
    required this.darkMode,
    required this.onAutoRefreshChanged,
    required this.onDarkModeChanged,
    required this.onTestConnection,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _testing = false;
  bool? _connected;

  Future<void> _testConnection() async {
    if (_testing) return;

    setState(() {
      _testing = true;
      _connected = null;
    });

    final result = await widget.onTestConnection();

    if (!mounted) return;

    setState(() {
      _testing = false;
      _connected = result;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result ? 'Server connection is active.' : 'Server is unreachable.',
        ),
      ),
    );
  }

  Color get _primaryTextColor =>
      widget.darkMode ? Colors.white : const Color(0xFF171A24);

  Color get _secondaryTextColor =>
      widget.darkMode
          ? Colors.white.withValues(alpha: 0.55)
          : const Color(0xFF697386);

  Color get _mutedTextColor =>
      widget.darkMode
          ? Colors.white.withValues(alpha: 0.38)
          : const Color(0xFF8992A4);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(22, 20, 22, 28),
        children: [
          Text(
            'Settings',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.8,
              color: _primaryTextColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Customize your EquipTrack experience.',
            style: TextStyle(
              fontSize: 12,
              color: _secondaryTextColor,
            ),
          ),
          const SizedBox(height: 24),

          _sectionCard(
            title: 'Appearance',
            icon: Icons.palette_outlined,
            children: [
              _settingRow(
                icon: Icons.dark_mode_outlined,
                title: 'Dark Mode',
                subtitle: 'Use the dark EquipTrack interface.',
                trailing: _LiquidSwitch(
                  value: widget.darkMode,
                  onChanged: widget.onDarkModeChanged,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          _sectionCard(
            title: 'Equipment',
            icon: Icons.inventory_2_outlined,
            children: [
              _settingRow(
                icon: Icons.sync_rounded,
                title: 'Auto Refresh',
                subtitle: 'Check the PHP server every 5 seconds.',
                trailing: _LiquidSwitch(
                  value: widget.autoRefresh,
                  onChanged: widget.onAutoRefreshChanged,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          _sectionCard(
            title: 'Server',
            icon: Icons.dns_outlined,
            children: [
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _connected == null
                          ? Colors.white38
                          : _connected!
                          ? const Color(0xFF42D392)
                          : const Color(0xFFFF6B6B),
                      boxShadow: [
                        if (_connected != null)
                          BoxShadow(
                            color: (_connected!
                                ? const Color(0xFF42D392)
                                : const Color(0xFFFF6B6B))
                                .withValues(alpha: 0.45),
                            blurRadius: 10,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _connected == null
                        ? 'Connection not tested'
                        : _connected!
                        ? 'Connected to PHP API'
                        : 'Server unreachable',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _primaryTextColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                widget.apiService.apiUrl,
                style: TextStyle(
                  fontSize: 11,
                  color: _mutedTextColor,
                ),
              ),
              const SizedBox(height: 14),
              GestureDetector(
                onTap: _testing ? null : () { _testConnection(); },
                child: GlassCard(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 13,
                  ),
                  quality: GlassQuality.standard,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_testing)
                        const SizedBox(
                          width: 17,
                          height: 17,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      else
                        const Icon(
                          Icons.network_check_rounded,
                          size: 18,
                          color: Color(0xFF9CA8FF),
                        ),
                      const SizedBox(width: 8),
                      Text(
                        _testing ? 'Testing Connection...' : 'Test Connection',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: _primaryTextColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          GlassCard(
            padding: const EdgeInsets.all(16),
            quality: GlassQuality.standard,
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  color: Color(0xFF9CA8FF),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'EquipTrack requires the PHP API server to stay reachable while the app is in use.',
                    style: TextStyle(
                      fontSize: 11,
                      height: 1.45,
                      color: _secondaryTextColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      quality: GlassQuality.standard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: const Color(0xFF7E8CFF).withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(
                    color: const Color(0xFF7E8CFF).withValues(alpha: 0.16),
                  ),
                ),
                child: Icon(
                  icon,
                  size: 18,
                  color: const Color(0xFF9CA8FF),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _primaryTextColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          ...children,
        ],
      ),
    );
  }

  Widget _settingRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget trailing,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(
          icon,
          size: 21,
          color: _secondaryTextColor,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 10,
                  height: 1.35,
                  color: _mutedTextColor,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        trailing,
      ],
    );
  }
}

class _LiquidSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const _LiquidSwitch({
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: GlassCard(
        padding: EdgeInsets.zero,
        quality: GlassQuality.standard,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 58,
          height: 32,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: value
                ? const Color(0xFF7282FF).withValues(alpha: 0.30)
                : Colors.white.withValues(alpha: 0.06),
            border: Border.all(
              color: value
                  ? const Color(0xFF9CA8FF).withValues(alpha: 0.42)
                  : Colors.white.withValues(alpha: 0.12),
            ),
          ),
          child: AnimatedAlign(
            duration: const Duration(milliseconds: 180),
            alignment: value
                ? Alignment.centerRight
                : Alignment.centerLeft,
            child: Container(
              width: 23,
              height: 23,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: value
                    ? const Color(0xFFBFC6FF)
                    : Colors.white.withValues(alpha: 0.72),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
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
