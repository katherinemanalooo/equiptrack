import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../models/equipment.dart';
import '../services/api_service.dart';


class _LiquidBackground extends StatelessWidget {
  const _LiquidBackground();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF090A12),
                  Color(0xFF060810),
                  Color(0xFF0A0C18),
                ],
              ),
            ),
          ),
          Positioned(
            top: -110,
            right: -120,
            child: Container(
              width: 310,
              height: 310,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF596BFF).withValues(alpha: 0.22),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 300,
            left: -150,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF734DFF).withValues(alpha: 0.12),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -170,
            right: -80,
            child: Container(
              width: 340,
              height: 340,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF386BFF).withValues(alpha: 0.13),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ],
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
  State<HomeScreen> createState() =>
      _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController =
  TextEditingController();

  List<Equipment> _equipment = [];

  bool _isLoading = true;
  bool _isCreating = false;
  String? _errorMessage;
  String _searchQuery = '';

  Timer? _serverCheckTimer;
  bool _isDisconnectDialogShowing = false;

  @override
  void initState() {
    super.initState();
    _loadEquipment();
    _serverCheckTimer = Timer.periodic(
      const Duration(seconds: 5),
          (_) => _checkServerConnection(),
    );
  }
  Future<void> _checkServerConnection() async {
    if (_isDisconnectDialogShowing) {
      return;
    }

    final connected =
    await widget.apiService.checkConnection();

    if (!mounted || connected) {
      return;
    }

    _showServerDisconnectedDialog();
  }

  void _showServerDisconnectedDialog() {
    if (_isDisconnectDialogShowing || !mounted) {
      return;
    }

    _isDisconnectDialogShowing = true;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        bool isReconnecting = false;

        return StatefulBuilder(
          builder: (dialogBuildContext, setDialogState) {
            return AlertDialog(
              title: const Text('Server Disconnected'),
              content: const Text(
                'The EquipTrack server cannot be reached. '
                    'Please make sure the PHP server is running '
                    'and try reconnecting.',
              ),
              actions: [
                FilledButton.icon(
                  onPressed: isReconnecting
                      ? null
                      : () async {
                    setDialogState(() {
                      isReconnecting = true;
                    });

                    final connected = await widget.apiService
                        .checkConnection();

                    if (!dialogContext.mounted) {
                      return;
                    }

                    if (connected) {
                      _isDisconnectDialogShowing = false;
                      Navigator.of(dialogContext).pop();
                      await _loadEquipment();
                    } else {
                      setDialogState(() {
                        isReconnecting = false;
                      });

                      ScaffoldMessenger.of(dialogBuildContext)
                          .showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Server is still unreachable.',
                          ),
                        ),
                      );
                    }
                  },
                  icon: isReconnecting
                      ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                      : const Icon(Icons.refresh_rounded),
                  label: Text(
                    isReconnecting ? 'Reconnecting...' : 'Reconnect',
                  ),
                ),
              ],
            );
          },
        );
      },
    ).then((_) {
      _isDisconnectDialogShowing = false;
    });
  }

  @override
  void dispose() {
    _serverCheckTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadEquipment() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final equipment =
      await widget.apiService.getEquipment();

      if (!mounted) return;

      setState(() {
        _equipment = equipment;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage =
        'Unable to load equipment from the server.';
      });
    }
  }

  List<Equipment> get _filteredEquipment {
    if (_searchQuery.trim().isEmpty) {
      return _equipment;
    }

    final query =
    _searchQuery.toLowerCase();

    return _equipment.where((item) {
      return item.name
          .toLowerCase()
          .contains(query) ||
          item.category
              .toLowerCase()
              .contains(query) ||
          item.location
              .toLowerCase()
              .contains(query) ||
          item.status
              .toLowerCase()
              .contains(query);
    }).toList();
  }

  int get _totalQuantity {
    return _equipment.fold<int>(
      0,
          (total, item) =>
      total + item.quantity,
    );
  }

  int get _availableCount {
    return _equipment
        .where(
          (item) =>
      item.status == 'Available',
    )
        .length;
  }

  int get _borrowedCount {
    return _equipment
        .where(
          (item) =>
      item.status == 'Borrowed',
    )
        .length;
  }

  Future<void> _createEquipment({
    required String name,
    required String category,
    required int quantity,
    required String location,
    required String status,
  }) async {
    setState(() {
      _isCreating = true;
    });

    try {
      final response =
      await widget.apiService.post(
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

      final dynamic decoded =
      jsonDecode(response.body);

      if (response.statusCode < 200 ||
          response.statusCode >= 300 ||
          decoded['success'] != true) {
        throw Exception(
          decoded['message']?.toString() ??
              'Failed to create equipment.',
        );
      }

      Navigator.of(context).pop();

      await _loadEquipment();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Equipment added successfully.',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _isCreating = false;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Failed to add equipment. '
                'Please check the server connection.',
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

      final dynamic decoded =
      jsonDecode(response.body);

      if (response.statusCode < 200 ||
          response.statusCode >= 300 ||
          decoded['success'] != true) {
        throw Exception(
          decoded['message']?.toString() ??
              'Failed to update equipment.',
        );
      }

      Navigator.of(context).pop();

      await _loadEquipment();

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Equipment updated successfully.',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Failed to update equipment. '
                'Please check the server connection.',
          ),
        ),
      );
    }
  }

  Future<void> _deleteEquipment(
      Equipment item,
      ) async {
    try {
      final response =
      await widget.apiService.delete(
        'equiptrack/api.php?id=${item.id}',
      );

      if (!mounted) return;

      final dynamic decoded =
      jsonDecode(response.body);

      if (response.statusCode < 200 ||
          response.statusCode >= 300 ||
          decoded['success'] != true) {
        throw Exception(
          decoded['message']?.toString() ??
              'Failed to delete equipment.',
        );
      }

      await _loadEquipment();

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            '${item.name} deleted successfully.',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Failed to delete equipment. '
                'Please check the server connection.',
          ),
        ),
      );
    }
  }

  void _confirmDelete(
      Equipment item,
      ) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Delete Equipment?',
          ),
          content: Text(
            'Are you sure you want to delete '
                '${item.name}?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop();
              },
              child: const Text(
                'Cancel',
              ),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor:
                const Color(0xFFD94A4A),
              ),
              onPressed: () async {
                Navigator.of(
                  dialogContext,
                ).pop();

                await _deleteEquipment(
                  item,
                );
              },
              child: const Text(
                'Delete',
              ),
            ),
          ],
        );
      },
    );
  }

  void _showAddEquipment() {
    final nameController =
    TextEditingController();

    final quantityController =
    TextEditingController();

    final locationController =
    TextEditingController();

    String category = 'Multimedia';
    String status = 'Available';

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (
              context,
              setModalState,
              ) {
            return Container(
              padding: EdgeInsets.fromLTRB(
                24,
                20,
                24,
                24 +
                    MediaQuery.of(context)
                        .viewInsets
                        .bottom,
              ),
              decoration:
              const BoxDecoration(
                color: Color(0xFF15171E),
                borderRadius:
                BorderRadius.vertical(
                  top: Radius.circular(30),
                ),
              ),
              child:
              SingleChildScrollView(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 42,
                        height: 4,
                        decoration:
                        BoxDecoration(
                          color: Colors.white
                              .withValues(
                            alpha: 0.18,
                          ),
                          borderRadius:
                          BorderRadius
                              .circular(10),
                        ),
                      ),
                    ),

                    const SizedBox(
                      height: 24,
                    ),

                    const Text(
                      'Add Equipment',
                      style: TextStyle(
                        fontSize: 25,
                        fontWeight:
                        FontWeight.w800,
                      ),
                    ),

                    const SizedBox(
                      height: 6,
                    ),

                    Text(
                      'Create a new equipment record.',
                      style: TextStyle(
                        color: Colors.white
                            .withValues(
                          alpha: 0.50,
                        ),
                      ),
                    ),

                    const SizedBox(
                      height: 24,
                    ),

                    TextField(
                      controller:
                      nameController,
                      enabled: !_isCreating,
                      decoration:
                      const InputDecoration(
                        labelText:
                        'Equipment Name',
                        prefixIcon: Icon(
                          Icons
                              .inventory_2_outlined,
                        ),
                      ),
                    ),

                    const SizedBox(
                      height: 14,
                    ),

                    DropdownButtonFormField<
                        String>(
                      initialValue:
                      category,
                      decoration:
                      const InputDecoration(
                        labelText: 'Category',
                      ),
                      items: const [
                        'Multimedia',
                        'Audio Equipment',
                        'Computer',
                        'Cable',
                        'Other',
                      ].map((value) {
                        return DropdownMenuItem(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged:
                      _isCreating
                          ? null
                          : (value) {
                        if (value !=
                            null) {
                          setModalState(
                                () {
                              category =
                                  value;
                            },
                          );
                        }
                      },
                    ),

                    const SizedBox(
                      height: 14,
                    ),

                    TextField(
                      controller:
                      quantityController,
                      enabled: !_isCreating,
                      keyboardType:
                      TextInputType.number,
                      decoration:
                      const InputDecoration(
                        labelText: 'Quantity',
                        prefixIcon: Icon(
                          Icons
                              .numbers_rounded,
                        ),
                      ),
                    ),

                    const SizedBox(
                      height: 14,
                    ),

                    TextField(
                      controller:
                      locationController,
                      enabled: !_isCreating,
                      decoration:
                      const InputDecoration(
                        labelText: 'Location',
                        prefixIcon: Icon(
                          Icons
                              .location_on_outlined,
                        ),
                      ),
                    ),

                    const SizedBox(
                      height: 14,
                    ),

                    DropdownButtonFormField<
                        String>(
                      initialValue:
                      status,
                      decoration:
                      const InputDecoration(
                        labelText: 'Status',
                      ),
                      items: const [
                        'Available',
                        'Borrowed',
                        'Maintenance',
                      ].map((value) {
                        return DropdownMenuItem(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged:
                      _isCreating
                          ? null
                          : (value) {
                        if (value !=
                            null) {
                          setModalState(
                                () {
                              status =
                                  value;
                            },
                          );
                        }
                      },
                    ),

                    const SizedBox(
                      height: 24,
                    ),

                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: FilledButton.icon(
                        onPressed:
                        _isCreating
                            ? null
                            : () {
                          final name =
                          nameController
                              .text
                              .trim();

                          final quantity =
                          int.tryParse(
                            quantityController
                                .text
                                .trim(),
                          );

                          final location =
                          locationController
                              .text
                              .trim();

                          if (name
                              .isEmpty ||
                              quantity ==
                                  null ||
                              quantity <=
                                  0 ||
                              location
                                  .isEmpty) {
                            ScaffoldMessenger
                                .of(
                              context,
                            ).showSnackBar(
                              const SnackBar(
                                content:
                                Text(
                                  'Please complete all fields.',
                                ),
                              ),
                            );
                            return;
                          }

                          _createEquipment(
                            name: name,
                            category:
                            category,
                            quantity:
                            quantity,
                            location:
                            location,
                            status:
                            status,
                          );
                        },
                        icon: _isCreating
                            ? const SizedBox(
                          width: 20,
                          height: 20,
                          child:
                          CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                            : const Icon(
                          Icons
                              .add_rounded,
                        ),
                        label: Text(
                          _isCreating
                              ? 'Saving...'
                              : 'Add Equipment',
                          style:
                          const TextStyle(
                            fontWeight:
                            FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
  void _showEditEquipment(Equipment item) {
    final nameController =
    TextEditingController(text: item.name);

    final quantityController =
    TextEditingController(
      text: item.quantity.toString(),
    );

    final locationController =
    TextEditingController(text: item.location);

    String category = item.category;
    String status = item.status;

    bool isSaving = false;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (
              context,
              setModalState,
              ) {
            return Container(
              padding: EdgeInsets.fromLTRB(
                24,
                20,
                24,
                24 +
                    MediaQuery.of(context)
                        .viewInsets
                        .bottom,
              ),
              decoration:
              const BoxDecoration(
                color: Color(0xFF15171E),
                borderRadius:
                BorderRadius.vertical(
                  top: Radius.circular(30),
                ),
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 42,
                        height: 4,
                        decoration:
                        BoxDecoration(
                          color: Colors.white
                              .withValues(
                            alpha: 0.18,
                          ),
                          borderRadius:
                          BorderRadius
                              .circular(10),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    const Text(
                      'Edit Equipment',
                      style: TextStyle(
                        fontSize: 25,
                        fontWeight:
                        FontWeight.w800,
                      ),
                    ),

                    const SizedBox(height: 6),

                    Text(
                      'Update the equipment record.',
                      style: TextStyle(
                        color: Colors.white
                            .withValues(
                          alpha: 0.50,
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    TextField(
                      controller: nameController,
                      enabled: !isSaving,
                      decoration:
                      const InputDecoration(
                        labelText:
                        'Equipment Name',
                        prefixIcon: Icon(
                          Icons
                              .inventory_2_outlined,
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    DropdownButtonFormField<String>(
                      initialValue:
                      category,
                      decoration:
                      const InputDecoration(
                        labelText: 'Category',
                      ),
                      items: const [
                        'Multimedia',
                        'Audio Equipment',
                        'Computer',
                        'Cable',
                        'Other',
                      ].map((value) {
                        return DropdownMenuItem(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: isSaving
                          ? null
                          : (value) {
                        if (value !=
                            null) {
                          setModalState(
                                () {
                              category =
                                  value;
                            },
                          );
                        }
                      },
                    ),

                    const SizedBox(height: 14),

                    TextField(
                      controller:
                      quantityController,
                      enabled: !isSaving,
                      keyboardType:
                      TextInputType.number,
                      decoration:
                      const InputDecoration(
                        labelText: 'Quantity',
                        prefixIcon: Icon(
                          Icons.numbers_rounded,
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    TextField(
                      controller:
                      locationController,
                      enabled: !isSaving,
                      decoration:
                      const InputDecoration(
                        labelText: 'Location',
                        prefixIcon: Icon(
                          Icons
                              .location_on_outlined,
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    DropdownButtonFormField<String>(
                      initialValue: status,
                      decoration:
                      const InputDecoration(
                        labelText: 'Status',
                      ),
                      items: const [
                        'Available',
                        'Borrowed',
                        'Maintenance',
                      ].map((value) {
                        return DropdownMenuItem(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: isSaving
                          ? null
                          : (value) {
                        if (value !=
                            null) {
                          setModalState(
                                () {
                              status =
                                  value;
                            },
                          );
                        }
                      },
                    ),

                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: FilledButton.icon(
                        onPressed: isSaving
                            ? null
                            : () async {
                          final name =
                          nameController
                              .text
                              .trim();

                          final quantity =
                          int.tryParse(
                            quantityController
                                .text
                                .trim(),
                          );

                          final location =
                          locationController
                              .text
                              .trim();

                          if (name.isEmpty ||
                              quantity ==
                                  null ||
                              quantity <= 0 ||
                              location
                                  .isEmpty) {
                            ScaffoldMessenger
                                .of(
                              context,
                            ).showSnackBar(
                              const SnackBar(
                                content:
                                Text(
                                  'Please complete all fields.',
                                ),
                              ),
                            );
                            return;
                          }

                          setModalState(
                                () {
                              isSaving =
                              true;
                            },
                          );

                          await _updateEquipment(
                            id: item.id!,
                            name: name,
                            category:
                            category,
                            quantity:
                            quantity,
                            location:
                            location,
                            status:
                            status,
                          );
                        },
                        icon: isSaving
                            ? const SizedBox(
                          width: 20,
                          height: 20,
                          child:
                          CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                            : const Icon(
                          Icons
                              .save_rounded,
                        ),
                        label: Text(
                          isSaving
                              ? 'Saving...'
                              : 'Save Changes',
                          style:
                          const TextStyle(
                            fontWeight:
                            FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
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

  IconData _equipmentIcon(
      String category,
      ) {
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
    final equipment = _filteredEquipment;

    return GlassPage(
      background: const _LiquidBackground(),
      child: Scaffold(
        extendBody: true,
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: RefreshIndicator(
            color: const Color(0xFF8B7CFF),
            backgroundColor: const Color(0xFF171A29),
            onRefresh: _loadEquipment,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(22, 18, 22, 12),
                  sliver: SliverToBoxAdapter(
                    child: Row(
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
                                  color: Colors.white.withValues(alpha: 0.48),
                                  letterSpacing: 0.15,
                                ),
                              ),
                            ],
                          ),
                        ),
                        _glassIconButton(
                          icon: Icons.inventory_2_rounded,
                          onPressed: _loadEquipment,
                          size: 48,
                          iconSize: 21,
                          accent: true,
                        ),
                      ],
                    ),
                  ),
                ),

                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(22, 10, 22, 16),
                  sliver: SliverToBoxAdapter(
                    child: _glassPanel(
                      padding: EdgeInsets.zero,
                      child: TextField(
                        controller: _searchController,
                        onChanged: (value) {
                          setState(() => _searchQuery = value);
                        },
                        decoration: InputDecoration(
                          hintText: 'Search equipment...',
                          hintStyle: TextStyle(
                            color: Colors.white.withValues(alpha: 0.38),
                            fontSize: 12,
                          ),
                          prefixIcon: Icon(
                            Icons.search_rounded,
                            color: Colors.white.withValues(alpha: 0.62),
                            size: 20,
                          ),
                          suffixIcon: Icon(
                            Icons.tune_rounded,
                            color: Colors.white.withValues(alpha: 0.35),
                            size: 18,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 4,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  sliver: SliverToBoxAdapter(
                    child: _glassPanel(
                      padding: const EdgeInsets.symmetric(
                        vertical: 17,
                        horizontal: 8,
                      ),
                      child: Row(
                        children: [
                          _glassStat(
                            Icons.inventory_2_outlined,
                            _totalQuantity.toString(),
                            'Total',
                            const Color(0xFF8290FF),
                          ),
                          _glassStatDivider(),
                          _glassStat(
                            Icons.check_circle_outline_rounded,
                            _availableCount.toString(),
                            'Available',
                            const Color(0xFF35D7A0),
                          ),
                          _glassStatDivider(),
                          _glassStat(
                            Icons.schedule_rounded,
                            _borrowedCount.toString(),
                            'Borrowed',
                            const Color(0xFFFFB938),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(22, 28, 22, 13),
                  sliver: SliverToBoxAdapter(
                    child: Row(
                      children: [
                        const Text(
                          'Equipment',
                          style: TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.4,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${equipment.length} items',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white.withValues(alpha: 0.40),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                if (_isLoading)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_errorMessage != null)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(30),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.cloud_off_rounded,
                              size: 48,
                              color: Colors.white.withValues(alpha: 0.35),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _errorMessage!,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 18),
                            FilledButton.icon(
                              onPressed: _loadEquipment,
                              icon: const Icon(Icons.refresh_rounded),
                              label: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else if (equipment.isEmpty)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(child: Text('No equipment found')),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 22),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                              (context, index) => _equipmentCard(equipment[index]),
                          childCount: equipment.length,
                        ),
                      ),
                    ),

                const SliverToBoxAdapter(child: SizedBox(height: 112)),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: _glassAddButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    ),
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

  Widget _glassStat(
      IconData icon,
      String value,
      String label,
      Color accent,
      ) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accent.withValues(alpha: 0.13),
              border: Border.all(color: accent.withValues(alpha: 0.20)),
            ),
            child: Icon(icon, size: 16, color: accent),
          ),
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
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.white.withValues(alpha: 0.48),
            ),
          ),
        ],
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

  Widget _glassAddButton() {
    return SafeArea(
      child: SizedBox(
        height: 54,
        child: GlassButton(
          onTap: _showAddEquipment,
          icon: const Icon(Icons.add_rounded, size: 22, color: Colors.white),
          label: 'Add Equipment',
          style: GlassButtonStyle.prominent,
        ),
      ),
    );
  }

  Widget _equipmentCard(Equipment item) {
    final statusColor = _statusColor(item.status);

    return Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: GestureDetector(
        onTap: () => _showEditEquipment(item),
        child: _glassPanel(
          padding: const EdgeInsets.all(13),
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
                      color: const Color(0xFF6374FF).withValues(alpha: 0.22),
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
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: statusColor.withValues(alpha: 0.16),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 5,
                          height: 5,
                          decoration: BoxDecoration(
                            color: statusColor,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: statusColor.withValues(alpha: 0.5),
                                blurRadius: 5,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          item.status,
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.w800,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
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


}
