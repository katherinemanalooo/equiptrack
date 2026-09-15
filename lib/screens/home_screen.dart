import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../models/equipment.dart';
import '../services/api_service.dart';
import 'settings_screen.dart';

class _LiquidBackground extends StatelessWidget {
  final bool darkMode;

  const _LiquidBackground({required this.darkMode});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
      Container(
      decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: darkMode
            ? [
          Color(0xFF070912),
          Color(0xFF0A0D18),
          Color(0xFF11152A),
        ]
            : [
          Color(0xFFEAF0FF),
          Color(0xFFF5F7FC),
          Color(0xFFE7ECF8),
        ],
      ),
    ),
    ),
          _glow(-120, -100, 320, const Color(0xFF6878FF)),
          _glow(300, -170, 310, const Color(0xFF754FFF)),
          _glow(-180, -100, 350, const Color(0xFF386BFF)),
        ],
      ),
    );
  }

  Widget _glow(
      double top,
      double left,
      double size,
      Color color,
      ) {
    return Positioned(
      top: top,
      left: left,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withValues(alpha: darkMode ? 0.20 : 0.10),
              Colors.transparent,
            ],
          ),
        ),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  final ApiService apiService;

  const HomeScreen({
    super.key,
    required this.apiService,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchController = TextEditingController();

  List<Equipment> _equipment = [];
  bool _isLoading = true;
  bool _isCreating = false;
  String? _errorMessage;
  String _searchQuery = '';

  int _selectedTab = 0;
  bool _autoRefresh = true;
  bool _darkMode = true;

  Timer? _serverCheckTimer;
  bool _isDisconnectDialogShowing = false;

  static const _categories = [
    'Multimedia',
    'Audio Equipment',
    'Computer',
    'Cable',
    'Other',
  ];

  static const _statuses = [
    'Available',
    'Borrowed',
    'Maintenance',
  ];

  @override
  void initState() {
    super.initState();
    _loadEquipment();
    _startServerCheckTimer();
  }

  @override
  void dispose() {
    _serverCheckTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _startServerCheckTimer() {
    _serverCheckTimer?.cancel();

    if (!_autoRefresh) return;

    _serverCheckTimer = Timer.periodic(
      const Duration(seconds: 5),
          (_) => _checkServerConnection(),
    );
  }

  void _setAutoRefresh(bool value) {
    setState(() => _autoRefresh = value);
    _startServerCheckTimer();
  }

  void _setDarkMode(bool value) {
    setState(() => _darkMode = value);
  }

  Color get _primaryTextColor =>
      _darkMode ? Colors.white : const Color(0xFF171A24);

  Color get _secondaryTextColor =>
      _darkMode ? Colors.white.withValues(alpha: 0.55) : const Color(0xFF697386);

  Color get _mutedTextColor =>
      _darkMode ? Colors.white.withValues(alpha: 0.38) : const Color(0xFF8992A4);



  Future<void> _checkServerConnection() async {
    if (_isDisconnectDialogShowing) return;
    final connected = await widget.apiService.checkConnection();
    if (!mounted || connected) return;
    _showServerDisconnectedDialog();
  }

  void _showServerDisconnectedDialog() {
    if (_isDisconnectDialogShowing || !mounted) return;
    _isDisconnectDialogShowing = true;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      builder: (dialogContext) {
        bool reconnecting = false;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.all(24),
              child: GlassCard(
                padding: const EdgeInsets.all(22),
                quality: GlassQuality.standard,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _dialogHeader(
                      Icons.cloud_off_rounded,
                      const Color(0xFFFF6B6B),
                      'Server Disconnected',
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'The EquipTrack server cannot be reached. '
                          'Please make sure the PHP server is running '
                          'and try reconnecting.',
                      style: TextStyle(
                        height: 1.45,
                        color: _secondaryTextColor,
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: GlassButton(
                        onTap: reconnecting
                            ? () {}
                            : () {
                          setDialogState(
                                () => reconnecting = true,
                          );

                          widget.apiService.checkConnection().then((connected) {
                            if (!dialogContext.mounted) return;

                            if (connected) {
                              _isDisconnectDialogShowing = false;
                              Navigator.of(dialogContext).pop();
                              _loadEquipment();
                            } else {
                              setDialogState(
                                    () => reconnecting = false,
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Server is still unreachable.',
                                  ),
                                ),
                              );
                            }
                          });
                        },
                        icon: reconnecting
                            ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                            : const Icon(
                          Icons.refresh_rounded,
                          color: Colors.white,
                        ),
                        label: reconnecting
                            ? 'Reconnecting...'
                            : 'Reconnect',
                        style: GlassButtonStyle.prominent,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    ).then((_) => _isDisconnectDialogShowing = false);
  }

  Widget _dialogHeader(
      IconData icon,
      Color color,
      String title,
      ) {
    return Row(
      children: [
        _circleIcon(icon, color),
        const SizedBox(width: 13),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _loadEquipment() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final equipment = await widget.apiService.getEquipment();
      if (!mounted) return;

      setState(() {
        _equipment = equipment;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = 'Unable to load equipment from the server.';
      });
    }
  }

  List<Equipment> get _filteredEquipment {
    final q = _searchQuery.trim().toLowerCase();
    if (q.isEmpty) return _equipment;

    return _equipment.where((item) {
      return item.name.toLowerCase().contains(q) ||
          item.category.toLowerCase().contains(q) ||
          item.location.toLowerCase().contains(q) ||
          item.status.toLowerCase().contains(q);
    }).toList();
  }

  int get _totalQuantity =>
      _equipment.fold(0, (sum, item) => sum + item.quantity);

  int get _availableCount =>
      _equipment.where((item) => item.status == 'Available').length;

  int get _borrowedCount =>
      _equipment.where((item) => item.status == 'Borrowed').length;

  Future<void> _createEquipment({
    required String name,
    required String category,
    required int quantity,
    required String location,
    required String status,
  }) async {
    setState(() => _isCreating = true);

    try {
      final response = await widget.apiService.post(
        'equiptrack/api.php',
        {
          'name': name,
          'category': category,
          'quantity': quantity,
          'location': location,
          'status': status,
        },
      );

      if (!mounted) return;
      final decoded = jsonDecode(response.body);

      if (response.statusCode < 200 ||
          response.statusCode >= 300 ||
          decoded['success'] != true) {
        throw Exception(
          decoded['message']?.toString() ?? 'Failed to create equipment.',
        );
      }

      Navigator.of(context).pop();
      await _loadEquipment();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Equipment added successfully.')),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _isCreating = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Failed to add equipment. Please check the server connection.',
          ),
        ),
      );
    }
  }

  Future<void> _updateEquipment({
    required int id,
    required String name,
    required String category,
    required int quantity,
    required String location,
    required String status,
  }) async {
    try {
      final response = await widget.apiService.put(
        'equiptrack/api.php',
        {
          'id': id,
          'name': name,
          'category': category,
          'quantity': quantity,
          'location': location,
          'status': status,
        },
      );

      if (!mounted) return;
      final decoded = jsonDecode(response.body);

      if (response.statusCode < 200 ||
          response.statusCode >= 300 ||
          decoded['success'] != true) {
        throw Exception(
          decoded['message']?.toString() ?? 'Failed to update equipment.',
        );
      }

      Navigator.of(context).pop();
      await _loadEquipment();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Equipment updated successfully.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Failed to update equipment. Please check the server connection.',
          ),
        ),
      );
    }
  }

  Future<void> _deleteEquipment(Equipment item) async {
    try {
      final response = await widget.apiService.delete(
        'equiptrack/api.php?id=${item.id}',
      );

      if (!mounted) return;
      final decoded = jsonDecode(response.body);

      if (response.statusCode < 200 ||
          response.statusCode >= 300 ||
          decoded['success'] != true) {
        throw Exception(
          decoded['message']?.toString() ?? 'Failed to delete equipment.',
        );
      }

      await _loadEquipment();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${item.name} deleted successfully.'),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Failed to delete equipment. Please check the server connection.',
          ),
        ),
      );
    }
  }

  void _confirmDelete(Equipment item) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(24),
          child: GlassCard(
            padding: const EdgeInsets.all(22),
            quality: GlassQuality.standard,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _dialogHeader(
                  Icons.delete_outline_rounded,
                  const Color(0xFFFF6B6B),
                  'Delete Equipment?',
                ),
                const SizedBox(height: 14),
                Text(
                  'Are you sure you want to delete ${item.name}?',
                  style: TextStyle(
                    color: _secondaryTextColor,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: GlassButton(
                          onTap: () =>
                              Navigator.of(dialogContext).pop(),
                          icon: const Icon(
                            Icons.close_rounded,
                            color: Colors.white70,
                          ),
                          label: 'Cancel',
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: GlassButton(
                          onTap: () async {
                            Navigator.of(dialogContext).pop();
                            await _deleteEquipment(item);
                          },
                          icon: const Icon(
                            Icons.delete_outline_rounded,
                            color: Color(0xFFFF7A7A),
                          ),
                          label: 'Delete',
                          style: GlassButtonStyle.prominent,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<String?> _pickValue({
    required String title,
    required String current,
    required List<String> options,
  }) {
    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      isScrollControlled: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
            child: GlassCard(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              quality: GlassQuality.standard,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _sheetHandle(),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Choose an option',
                      style: TextStyle(
                        fontSize: 12,
                        color: _secondaryTextColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  ...options.map((option) {
                    final selected = option == current;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: GestureDetector(
                        onTap: () => Navigator.of(sheetContext).pop(option),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          width: double.infinity,
                          height: 54,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            color: selected
                                ? const Color(0xFF7584FF).withValues(alpha: 0.17)
                                : Colors.white.withValues(alpha: 0.045),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: selected
                                  ? const Color(0xFF9AA5FF).withValues(alpha: 0.50)
                                  : Colors.white.withValues(alpha: 0.08),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _pickerIcon(option),
                                size: 20,
                                color: selected
                                    ? const Color(0xFFAEB7FF)
                                    : _secondaryTextColor,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  option,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: selected
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: _primaryTextColor,
                                  ),
                                ),
                              ),
                              Container(
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: selected
                                      ? const Color(0xFF8290FF)
                                      : Colors.transparent,
                                  border: Border.all(
                                    color: selected
                                        ? const Color(0xFF8290FF)
                                        : Colors.white38,
                                    width: 1.4,
                                  ),
                                ),
                                child: selected
                                    ? const Icon(
                                  Icons.check_rounded,
                                  size: 15,
                                  color: Colors.white,
                                )
                                    : null,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  IconData _pickerIcon(String value) {
    switch (value.toLowerCase()) {
      case 'multimedia':
        return Icons.videocam_rounded;
      case 'audio equipment':
        return Icons.mic_rounded;
      case 'computer':
        return Icons.laptop_rounded;
      case 'cable':
        return Icons.cable_rounded;
      case 'available':
        return Icons.check_circle_outline_rounded;
      case 'borrowed':
        return Icons.schedule_rounded;
      case 'maintenance':
        return Icons.build_circle_outlined;
      default:
        return Icons.inventory_2_rounded;
    }
  }

  void _showAddEquipment() {
    final name = TextEditingController();
    final quantity = TextEditingController();
    final location = TextEditingController();

    String category = _categories.first;
    String status = _statuses.first;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return _formSheet(
              title: 'Add Equipment',
              subtitle: 'Create a new equipment record.',
              nameController: name,
              quantityController: quantity,
              locationController: location,
              category: category,
              status: status,
              busy: _isCreating,
              onCategory: () {
                _pickValue(
                  title: 'Select Category',
                  current: category,
                  options: _categories,
                ).then((value) {
                  if (value != null) {
                    setModalState(() => category = value);
                  }
                });
              },
              onStatus: () {
                _pickValue(
                  title: 'Select Status',
                  current: status,
                  options: _statuses,
                ).then((value) {
                  if (value != null) {
                    setModalState(() => status = value);
                  }
                });
              },
              onSubmit: () {
                final n = name.text.trim();
                final q = int.tryParse(quantity.text.trim());
                final l = location.text.trim();

                if (n.isEmpty || q == null || q <= 0 || l.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please complete all fields.'),
                    ),
                  );
                  return;
                }

                _createEquipment(
                  name: n,
                  category: category,
                  quantity: q,
                  location: l,
                  status: status,
                );
              },
              submitLabel: 'Add Equipment',
              submitIcon: Icons.add_rounded,
            );
          },
        );
      },
    );
  }

  void _showEditEquipment(Equipment item) {
    final name = TextEditingController(text: item.name);
    final quantity = TextEditingController(
      text: item.quantity.toString(),
    );
    final location = TextEditingController(text: item.location);

    String category = item.category;
    String status = item.status;
    bool saving = false;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return _formSheet(
              title: 'Edit Equipment',
              subtitle: 'Update the equipment record.',
              nameController: name,
              quantityController: quantity,
              locationController: location,
              category: category,
              status: status,
              busy: saving,
              onCategory: () {
                _pickValue(
                  title: 'Select Category',
                  current: category,
                  options: _categories,
                ).then((value) {
                  if (value != null) {
                    setModalState(() => category = value);
                  }
                });
              },
              onStatus: () {
                _pickValue(
                  title: 'Select Status',
                  current: status,
                  options: _statuses,
                ).then((value) {
                  if (value != null) {
                    setModalState(() => status = value);
                  }
                });
              },
              onSubmit: () {
                final n = name.text.trim();
                final q = int.tryParse(quantity.text.trim());
                final l = location.text.trim();

                if (n.isEmpty || q == null || q <= 0 || l.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please complete all fields.'),
                    ),
                  );
                  return;
                }

                setModalState(() => saving = true);

                _updateEquipment(
                  id: item.id!,
                  name: n,
                  category: category,
                  quantity: q,
                  location: l,
                  status: status,
                );
              },
              submitLabel: 'Save Changes',
              submitIcon: Icons.save_rounded,
            );
          },
        );
      },
    );
  }

  Widget _formSheet({
    required String title,
    required String subtitle,
    required TextEditingController nameController,
    required TextEditingController quantityController,
    required TextEditingController locationController,
    required String category,
    required String status,
    required bool busy,
    required VoidCallback onCategory,
    required VoidCallback onStatus,
    required VoidCallback onSubmit,
    required String submitLabel,
    required IconData submitIcon,
  }) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          14,
          10,
          14,
          14 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: GlassCard(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
          quality: GlassQuality.standard,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sheetHandle(),
                const SizedBox(height: 20),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: _secondaryTextColor,
                  ),
                ),
                const SizedBox(height: 20),
                GlassTextField(
                  controller: nameController,
                  enabled: !busy,
                  placeholder: 'Equipment Name',
                  prefixIcon: const Icon(
                    Icons.inventory_2_outlined,
                    color: Colors.white70,
                  ),
                  useOwnLayer: true,
                  quality: GlassQuality.standard,
                ),
                const SizedBox(height: 12),
                _selectionField(
                  title: 'Category',
                  value: category,
                  icon: Icons.category_outlined,
                  enabled: !busy,
                  onTap: onCategory,
                ),
                const SizedBox(height: 12),
                GlassTextField(
                  controller: quantityController,
                  enabled: !busy,
                  keyboardType: TextInputType.number,
                  placeholder: 'Quantity',
                  prefixIcon: const Icon(
                    Icons.numbers_rounded,
                    color: Colors.white70,
                  ),
                  useOwnLayer: true,
                  quality: GlassQuality.standard,
                ),
                const SizedBox(height: 12),
                GlassTextField(
                  controller: locationController,
                  enabled: !busy,
                  placeholder: 'Location',
                  prefixIcon: const Icon(
                    Icons.location_on_outlined,
                    color: Colors.white70,
                  ),
                  useOwnLayer: true,
                  quality: GlassQuality.standard,
                ),
                const SizedBox(height: 12),
                _selectionField(
                  title: 'Status',
                  value: status,
                  icon: Icons.circle_outlined,
                  enabled: !busy,
                  onTap: onStatus,
                ),
                const SizedBox(height: 18),
                Center(
                  child: GestureDetector(
                    onTap: busy ? () {} : onSubmit,
                    child: GlassCard(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 22,
                        vertical: 12,
                      ),
                      quality: GlassQuality.standard,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (busy)
                            const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFFB2BAFF),
                              ),
                            )
                          else
                            Icon(
                              submitIcon,
                              size: 18,
                              color: Color(0xFFB2BAFF),
                            ),
                          const SizedBox(width: 8),
                          Text(
                            busy ? 'Saving...' : submitLabel,
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
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _selectionField({
    required String title,
    required String value,
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: GlassCard(
        padding: EdgeInsets.zero,
        quality: GlassQuality.standard,
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 13,
            ),
            child: Row(
              children: [
                Icon(icon, color: _secondaryTextColor, size: 20),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 9,
                          color: _secondaryTextColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        value,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: _secondaryTextColor,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sheetHandle() {
    return Center(
      child: Container(
        width: 42,
        height: 4,
        decoration: BoxDecoration(
          color: _darkMode ? Colors.white.withValues(alpha: 0.22) : Colors.black.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }

  Widget _circleIcon(IconData icon, Color color) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.12),
        border: Border.all(
          color: color.withValues(alpha: 0.22),
        ),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }

  Widget _glassPanel({
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(16),
  }) {
    return GlassCard(
      padding: padding,
      quality: GlassQuality.standard,
      child: child,
    );
  }

  Widget _glassIconButton({
    required IconData icon,
    required VoidCallback onPressed,
    required double size,
    required double iconSize,
    bool accent = false,
  }) {
    return GlassIconButton(
      icon: Icon(
        icon,
        size: iconSize,
        color: Colors.white,
      ),
      onPressed: onPressed,
      size: size,
      iconSize: iconSize,
      glowColor: accent ? const Color(0xFF7C8CFF) : null,
      glowRadius: accent ? 26 : 20,
    );
  }

  Widget _glassStat({
    required IconData icon,
    required String value,
    required String label,
    required Color accent,
  }) {
    return Expanded(
      child: Column(
        children: [
          _circleIcon(icon, accent),
          const SizedBox(height: 7),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Category',
            style: TextStyle(
              fontSize: 10,
              color: _secondaryTextColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _equipmentCard(Equipment item) {
    final statusColor = _statusColor(item.status);

    return Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: GlassCard(
        padding: const EdgeInsets.all(13),
        quality: GlassQuality.standard,
        child: InkWell(
          onTap: () => _showEditEquipment(item),
          borderRadius: BorderRadius.circular(20),
          child: Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(17),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF6E80FF),
                      Color(0xFF5044D7),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6374FF)
                          .withValues(alpha: 0.22),
                      blurRadius: 18,
                      spreadRadius: -5,
                    ),
                  ],
                ),
                child: Icon(
                  _equipmentIcon(item.category),
                  color: Colors.white,
                  size: 27,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.category,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.white.withValues(alpha: 0.46),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 12,
                          color: Colors.white.withValues(alpha: 0.43),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Qty: ${item.quantity}',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.white.withValues(alpha: 0.58),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 3,
                          height: 3,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.25),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.location_on_outlined,
                          size: 12,
                          color: Colors.white.withValues(alpha: 0.43),
                        ),
                        const SizedBox(width: 3),
                        Flexible(
                          child: Text(
                            item.location,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.white.withValues(alpha: 0.58),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 7),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _statusPill(item.status, statusColor),
                  const SizedBox(height: 8),
                  GlassIconButton(
                    icon: Icon(
                      Icons.delete_outline_rounded,
                      size: 16,
                      color: Colors.white.withValues(alpha: 0.78),
                    ),
                    onPressed: () => _confirmDelete(item),
                    size: 32,
                    iconSize: 16,
                    shape: GlassIconButtonShape.roundedSquare,
                    borderRadius: 10,
                    glowColor: Colors.redAccent,
                    glowRadius: 18,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusPill(String status, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withValues(alpha: 0.16),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.5),
                  blurRadius: 5,
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          Text(
            status,
            style: TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Available':
        return const Color(0xFF42D392);
      case 'Borrowed':
        return const Color(0xFFFFB74D);
      case 'Maintenance':
        return const Color(0xFFFF6B6B);
      default:
        return Colors.grey;
    }
  }

  IconData _equipmentIcon(String category) {
    switch (category) {
      case 'Multimedia':
        return Icons.videocam_rounded;
      case 'Audio Equipment':
        return Icons.mic_rounded;
      case 'Computer':
        return Icons.laptop_rounded;
      case 'Cable':
        return Icons.cable_rounded;
      default:
        return Icons.inventory_2_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeData(
      useMaterial3: true,
      brightness: _darkMode ? Brightness.dark : Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF7584FF),
        brightness: _darkMode ? Brightness.dark : Brightness.light,
      ),
      scaffoldBackgroundColor: Colors.transparent,
    );

    return Theme(
      data: theme,
      child: GlassPage(
        background: _LiquidBackground(darkMode: _darkMode),
        child: Scaffold(
          extendBody: true,
          backgroundColor: Colors.transparent,
          body: IndexedStack(
            index: _selectedTab,
            children: [
              _buildHomeContent(),
              SettingsScreen(
                apiService: widget.apiService,
                autoRefresh: _autoRefresh,
                darkMode: _darkMode,
                onAutoRefreshChanged: _setAutoRefresh,
                onDarkModeChanged: _setDarkMode,
                onTestConnection: widget.apiService.checkConnection,
              ),
            ],
          ),
          bottomNavigationBar: _buildBottomNavigationBar(),
        ),
      ),
    );
  }

  Widget _buildHomeContent() {
    final equipment = _filteredEquipment;

    return SafeArea(
      child: RefreshIndicator(
        color: const Color(0xFF8B7CFF),
        backgroundColor: const Color(0xFF171A29),
        onRefresh: _loadEquipment,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShaderMask(
                        shaderCallback: (bounds) =>
                            const LinearGradient(
                              colors: [
                                Colors.white,
                                Color(0xFF9EACFF),
                                Color(0xFFB58CFF),
                              ],
                            ).createShader(bounds),
                        child: const Text(
                          'EquipTrack',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 27,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -1.1,
                          ),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Campus Equipment Management',
                        style: TextStyle(
                          fontSize: 11,
                          color: _secondaryTextColor,
                        ),
                      ),
                    ],
                  ),
                ),
                _glassIconButton(
                  icon: Icons.refresh_rounded,
                  onPressed: _loadEquipment,
                  size: 48,
                  iconSize: 21,
                  accent: true,
                ),
              ],
            ),
            const SizedBox(height: 16),
            GlassTextField.search(
              controller: _searchController,
              placeholder: 'Search equipment...',
              prefixIcon: const Icon(
                Icons.search_rounded,
                size: 20,
                color: Colors.white70,
              ),
              suffixIcon: const Icon(
                Icons.tune_rounded,
                size: 18,
                color: Colors.white38,
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value);
              },
              useOwnLayer: true,
              quality: GlassQuality.standard,
            ),
            const SizedBox(height: 14),
            _glassPanel(
              padding: const EdgeInsets.symmetric(
                vertical: 17,
                horizontal: 8,
              ),
              child: Row(
                children: [
                  _glassStat(
                    icon: Icons.inventory_2_outlined,
                    value: _totalQuantity.toString(),
                    label: 'Total',
                    accent: const Color(0xFF8290FF),
                  ),
                  _glassStatDivider(),
                  _glassStat(
                    icon: Icons.check_circle_outline_rounded,
                    value: _availableCount.toString(),
                    label: 'Available',
                    accent: const Color(0xFF35D7A0),
                  ),
                  _glassStatDivider(),
                  _glassStat(
                    icon: Icons.schedule_rounded,
                    value: _borrowedCount.toString(),
                    label: 'Borrowed',
                    accent: const Color(0xFFFFB938),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 26),
            Row(
              children: [
                Text(
                  'Equipment',
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                Text(
                  '${equipment.length} items',
                  style: TextStyle(
                    fontSize: 11,
                    color: _mutedTextColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 13),
            if (_isLoading)
              const SizedBox(
                height: 250,
                child: Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF8290FF),
                  ),
                ),
              )
            else if (_errorMessage != null)
              _glassPanel(
                padding: const EdgeInsets.all(28),
                child: Column(
                  children: [
                    _circleIcon(
                      Icons.cloud_off_rounded,
                      const Color(0xFFFF6B6B),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _secondaryTextColor,
                      ),
                    ),
                    const SizedBox(height: 18),
                    _compactGlassAction(
                      icon: Icons.refresh_rounded,
                      label: 'Retry',
                      onTap: _loadEquipment,
                    ),
                  ],
                ),
              )
            else if (equipment.isEmpty)
                _glassPanel(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    children: [
                      _circleIcon(
                        Icons.inventory_2_outlined,
                        const Color(0xFF8290FF),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'No equipment found',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: _primaryTextColor,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _searchQuery.isEmpty
                            ? 'Add your first equipment record.'
                            : 'Try a different search term.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _secondaryTextColor,
                        ),
                      ),
                    ],
                  ),
                )
              else
                ...equipment.map(_equipmentCard),
            const SizedBox(height: 8),
            _glassAddButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(18, 0, 18, 14),
      child: GlassTabBar.bottom(
        selectedIndex: _selectedTab,
        onTabSelected: (index) {
          setState(() {
            _selectedTab = index;
          });
        },
        tabs: const [
          GlassTab(
            icon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          GlassTab(
            icon: Icon(Icons.settings_rounded),
            label: 'Settings',
          ),
        ],
        selectedIconColor: Color(0xFFB2BAFF),
        selectedLabelColor: Colors.white,
        unselectedIconColor: Colors.white,
        unselectedLabelColor: Colors.white54,
      ),
    );
  }

  Widget _glassAddButton() {
    return Align(
      alignment: Alignment.center,
      child: _compactGlassAction(
        icon: Icons.add_rounded,
        label: 'Add Equipment',
        onTap: _showAddEquipment,
      ),
    );
  }

  Widget _compactGlassAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: GlassCard(
        padding: const EdgeInsets.symmetric(
          horizontal: 17,
          vertical: 11,
        ),
        quality: GlassQuality.standard,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 19,
              color: const Color(0xFFB2BAFF),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _glassStatDivider() {
    return Container(
      width: 1,
      height: 68,
      color: Colors.white.withValues(alpha: 0.10),
    );
  }
}
