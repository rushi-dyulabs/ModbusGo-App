import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;

enum ReadWriteMode { read, write, ota }

class ModbusHomePage extends StatefulWidget {
  const ModbusHomePage({super.key});

  @override
  State<ModbusHomePage> createState() => _ModbusHomePageState();
}

class _ModbusHomePageState extends State<ModbusHomePage> with SingleTickerProviderStateMixin {

  Map<String, dynamic>? _responseData;

  final _slaveIdController = TextEditingController();
  final _addressController = TextEditingController();
  final _quantityController = TextEditingController();

  // ───────────────── FOCUS ─────────────────

  final FocusNode _slaveFocus = FocusNode();
  final FocusNode _baudFocus = FocusNode();
  final FocusNode _readFocus = FocusNode();
  final FocusNode _writeFocus = FocusNode();
  final FocusNode _otaFocus = FocusNode();
  final FocusNode _addressFocus = FocusNode();
  final FocusNode _quantityFocus = FocusNode();

  FocusNode? _activeFocus;

  void _setFocused(FocusNode node) {
    FocusScope.of(context).unfocus();
    setState(() {
      _activeFocus = node;
    });
  }

  bool _isFocused(FocusNode node) => _activeFocus == node;
  bool _isBaudDropdownOpen = false;
  String _selectedBaudRate = '9600';
  ReadWriteMode _selectedMode = ReadWriteMode.read;
  bool _isConnected = false;

  final List<String> _baudRates = [
    '1200',
    '2400',
    '4800',
    '9600',
    '19200',
    '38400',
    '57600',
    '115200',
  ];

  Map<String, String> _getModbusReason(int status) {

    switch (status) {

      case 0:
        return {
          "title": "Success",
          "description":
          "Modbus request completed successfully.",
        };

      case 1:
        return {
          "title": "Illegal Function",
          "description":
          "Device does not support this Modbus function.",
        };

      case 2:
        return {
          "title": "Illegal Data Address",
          "description":
          "Register address is invalid or outside supported range.",
        };

      case 3:
        return {
          "title": "Illegal Data Value",
          "description":
          "Invalid quantity or unsupported parameter value.",
        };

      case 4:
        return {
          "title": "Slave Device Failure",
          "description":
          "Device had internal processing failure.",
        };

      case 224:
        return {
          "title": "Invalid Slave ID",
          "description":
          "Unexpected slave ID or corrupted communication.",
        };

      case 225:
        return {
          "title": "Invalid Function",
          "description":
          "Returned function code does not match request.",
        };

      case 226:
        return {
          "title": "Response Timed Out",
          "description":
          "No valid response received. Check baud rate, slave ID, wiring, parity, or sensor connection.",
        };

      case 227:
        return {
          "title": "Invalid CRC",
          "description":
          "CRC validation failed. Data corruption detected.",
        };

      default:
        return {
          "title": "Unknown Error",
          "description":
          "Unknown Modbus error occurred.",
        };
    }
  }

  // ───────────────── COLORS ─────────────────

  static const Color _blue = Color(0xFF1A73E8);
  static const Color _green = Color(0xFF00A86B);
  static const Color _orange = Color(0xFFFF8F00);
  static const Color _purple = Color(0xFF7C4DFF);
  static const Color _bgWhite = Colors.white;
  static const Color _bgField = Color(0xFFF4F7FC);
  static const Color _borderColor = Color(0xFFE3E8F2);
  static const Color _textPrimary = Color(0xFF1C1C1E);
  static const Color _textSec = Color(0xFF8E8E93);
  Color get _modeColor {
    switch (_selectedMode) {
      case ReadWriteMode.read:
        return _green;
      case ReadWriteMode.write:
        return _orange;
      case ReadWriteMode.ota:
        return _purple;
    }
  }

  @override
  void dispose() {
    _slaveFocus.dispose();
    _baudFocus.dispose();
    _readFocus.dispose();
    _writeFocus.dispose();
    _otaFocus.dispose();
    _addressFocus.dispose();
    _quantityFocus.dispose();
    _slaveIdController.dispose();
    _addressController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  // void _onSend() {
  //   if (_slaveIdController.text.isEmpty || _addressController.text.isEmpty || _quantityController.text.isEmpty) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(
  //         content: Text('Please fill all required fields'),
  //       ),
  //     );
  //     return;
  //   }
  //   FocusScope.of(context).unfocus();
  //   setState(() {
  //     _activeFocus = null;
  //     _isConnected = !_isConnected;
  //   });
  // }

  Future<void> _onSend() async {


    if(_selectedMode == ReadWriteMode.ota){
      print('perform Ota');
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
      );

      String? filePath = result?.files.first.path;
      print('filePath : $filePath');
      File file = File(filePath!);

      debugPrint("Selected File : $filePath");
      var request = http.MultipartRequest("POST", Uri.parse("http://192.168.4.1/update"),);
      request.files.add(
        await http.MultipartFile.fromPath(
          "file",
          file.path,
        ),
      );

      var response = await request.send();
      final responseBody = await response.stream.bytesToString();
      debugPrint("STATUS : ${response.statusCode}");
      debugPrint("BODY : $responseBody");

    }else if(_selectedMode == ReadWriteMode.write){
      print('perform write action');
    }else if(_selectedMode == ReadWriteMode.read){
      if (_slaveIdController.text.isEmpty || _addressController.text.isEmpty || _quantityController.text.isEmpty) {

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Please fill all required fields',
            ),
          ),
        );

        return;
      }
      FocusScope.of(context).unfocus();
      setState(() {
        _activeFocus = null;
        _responseData = null;
      });
      try {

        // final request = {
        //   "s": int.parse(_slaveIdController.text),
        //   "b": int.parse(_selectedBaudRate),
        //   "a": int.parse(_addressController.text),
        //   "q": int.parse(_quantityController.text),
        // };
        final request = {
          "s": _slaveIdController.text,
          "b": _selectedBaudRate,
          "a": _addressController.text,
          "q": _quantityController.text,
        };

        debugPrint("REQUEST : ${jsonEncode(request)}");

        final response = await http.post(
          Uri.parse("http://192.168.4.1/rs485/read"),

          // headers: {
          //   "Content-Type": "application/json",
          // },

          body: jsonEncode(request),
        );

        debugPrint("STATUS : ${response.statusCode}");
        debugPrint("BODY : ${response.body}");

        if (!mounted) return;

        if (response.statusCode == 200) {

          final data = jsonDecode(response.body);

          setState(() {
            _responseData = data;
          });

        } else {

          setState(() {
            _responseData = {
              "status": "error",
              "message":
              "HTTP Error ${response.statusCode}",
              "modbus_status": -1,
              "values": [],
            };
          });
        }

      } catch (e) {

        setState(() {
          _responseData = {
            "status": "error",
            "message": e.toString(),
            "modbus_status": -1,
            "values": [],
          };
        });

      } finally {
      }
    }
    else{
      print('not define condition');
    }

  }

  // ───────────────── UI ─────────────────

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        setState(() {
          _activeFocus = null;
          _isBaudDropdownOpen = false;
        });
      },
      child: Scaffold(
        backgroundColor: _bgWhite,
        appBar: _buildAppBar(),
        body: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _buildConfigCard(),
                const SizedBox(height: 18),
                _buildModeCard(),
                const SizedBox(height: 18),
                _buildRegisterCard(),
                const SizedBox(height: 28),
                _buildSendButton(),
                if (_responseData != null) ...[
                  const SizedBox(height: 24),
                  _buildResponseCard(),
                ],

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ───────────────── APP BAR ─────────────────

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: _bgWhite,
      elevation: 0,
      scrolledUnderElevation: 0,
      toolbarHeight: 76,
      automaticallyImplyLeading: false,
      titleSpacing: 20,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      title: Row(
        children: [
          Container(
            width: 62,
            height: 62,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: SvgPicture.asset(
              'assets/svg/o_logo.svg',
              fit: BoxFit.contain,
            ),
          ),

          Expanded(
            child: SvgPicture.asset(
              'assets/svg/aalok_logo.svg',
              height: 34,
              alignment: Alignment.centerLeft,
              fit: BoxFit.contain,
            ),
          ),
        ],
      ),

      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: _borderColor,),
      ),
    );
  }

  // ───────────────── CONFIG CARD ─────────────────

  Widget _buildConfigCard() {
    return _card(
      title: 'Device Configuration',
      icon: Icons.settings_input_component_rounded,
      color: _blue,
      child: Column(
        children: [
          _buildTextField(
            label: 'Slave ID',
            hint: 'Enter slave ID',
            controller: _slaveIdController,
            focusNode: _slaveFocus,
            icon: Icons.memory_rounded,
            color: _blue,
            onChanged: (_) {
              setState(() {});
            },
            formatters: [
              FilteringTextInputFormatter.digitsOnly,
              _RangeInputFormatter(1, 247),
            ],
          ),
          const SizedBox(height: 18),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _fieldLabel('Baud Rate', Icons.speed_rounded, _blue,),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () {
                  FocusScope.of(context).unfocus();
                  _setFocused(_baudFocus);
                  setState(() {
                    _isBaudDropdownOpen = !_isBaudDropdownOpen;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  height: 54,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _isFocused(_baudFocus) ? Colors.grey : _borderColor,
                      width: _isFocused(_baudFocus) ? 1.5 : 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _isFocused(_baudFocus) ? Colors.grey.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.02),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Text(
                              _selectedBaudRate,
                              style: const TextStyle(
                                color: _textPrimary,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Text(
                              'bps',
                              style: TextStyle(color: _textSec, fontSize: 12,),
                            ),
                          ],
                        ),
                      ),
                      AnimatedRotation(
                        turns: _isBaudDropdownOpen ? 0.5 : 0,
                        duration: const Duration(milliseconds: 220),
                        child: const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: !_isBaudDropdownOpen
                    ? const SizedBox.shrink()
                    : Container(
                  key: const ValueKey(1),
                  margin: const EdgeInsets.only(top: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey.shade200,),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Scrollbar(
                      thumbVisibility: true,
                      radius: const Radius.circular(20),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 240,),
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          shrinkWrap: true,
                          itemCount: _baudRates.length,
                          itemBuilder: (context, index) {
                            final e = _baudRates[index];
                            final selected = e == _selectedBaudRate;
                            return InkWell(
                              onTap: () {
                                setState(() {
                                  _selectedBaudRate = e;
                                  _isBaudDropdownOpen = false;
                                  _activeFocus = null;
                                });
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 2,),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14,),
                                decoration: BoxDecoration(
                                  color: selected ? _blue.withValues(alpha:0.08) : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                ),

                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Row(
                                        children: [
                                          Text(
                                            e,
                                            style: TextStyle(
                                              color: selected ? _blue : _textPrimary,
                                              fontSize: 15,
                                              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            'bps',
                                            style: TextStyle(
                                              color: selected ? _blue.withValues(alpha:0.7) : _textSec,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              )
            ],
          )
        ],
      ),
    );
  }

  // ───────────────── MODE CARD ─────────────────

  Widget _buildModeCard() {
    return _card(
      title: 'Operation Mode',
      icon: Icons.tune_rounded,
      color: _modeColor,
      child: Row(
        children: [
          _modeButton(
            mode: ReadWriteMode.read,
            label: 'Read',
            color: _green,
          ),
          const SizedBox(width: 10),
          _modeButton(
            mode: ReadWriteMode.write,
            label: 'Write',
            color: _orange,
          ),
          const SizedBox(width: 10),
          _modeButton(
            mode: ReadWriteMode.ota,
            label: 'OTA',
            color: _purple,
          ),
        ],
      ),
    );
  }

  Widget _modeButton({required ReadWriteMode mode, required String label, required Color color,}) {
    final selected = _selectedMode == mode;
    final FocusNode currentFocus =
    mode == ReadWriteMode.read ? _readFocus
        : mode == ReadWriteMode.write ? _writeFocus : _otaFocus;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
          _setFocused(currentFocus);
          setState(() {
            _selectedMode = mode;
            _isBaudDropdownOpen = false;
            _responseData = null;

          });

        },

        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? color.withValues(alpha:0.12) : _bgField,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _isFocused(currentFocus) ? color
                  : selected ? color : _borderColor,
              width: _isFocused(currentFocus) ? 1.5 : 1,
            ),
          ),

          child: Column(
            children: [
              Text(
                label,
                style: TextStyle(
                  color: selected ? color : _textSec,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 6),

              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width: selected ? 22 : 0,
                height: 3,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ───────────────── REGISTER CARD ─────────────────
  Widget _buildRegisterCard() {
    // Hide register settings for OTA
    if (_selectedMode == ReadWriteMode.ota) {
      return const SizedBox.shrink();
    }

    return _card(
      title: 'Register Settings',
      icon: Icons.table_rows_rounded,
      color: _orange,
      child: Column(
        children: [
          _buildTextField(
            label: 'Start Address',
            hint: 'e.g. 40001',
            controller: _addressController,
            focusNode: _addressFocus,
            icon: Icons.location_on_rounded,
            color: _orange,
            formatters: [
              FilteringTextInputFormatter.digitsOnly,
            ],
          ),

          const SizedBox(height: 18),

          _buildTextField(
            label: 'Quantity',
            hint: '1 - 125',
            controller: _quantityController,
            focusNode: _quantityFocus,
            icon: Icons.format_list_numbered_rounded,
            color: _purple,
            formatters: [
              FilteringTextInputFormatter.digitsOnly,
              _RangeInputFormatter(1, 125),
            ],
          ),
        ],
      ),
    );
  }

  // ───────────────── BUTTON ─────────────────

  Widget _buildSendButton() {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),

      child: Ink(
        height: 58,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _isConnected
                ? [
              const Color(0xFFFF7E5F),
              const Color(0xFFFFB88C),
            ]
                : [
              const Color(0xFF5B0E91),
              const Color(0xFF8E2DE2),
              const Color(0xFFC86DD7),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: const [0.1, 0.6, 1.0],
          ),

          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.10),
            width: 1.2,
          ),

          boxShadow: [
            BoxShadow(
              color: (_isConnected ? const Color(0xFFFF7E5F) : const Color(0xFF8E2DE2)).withValues(alpha: 0.40),
              blurRadius: 24,
              spreadRadius: 2,
              offset: const Offset(0, 10),
            ),
          ],
        ),

        child: InkWell(
          onTap: _onSend,
          borderRadius: BorderRadius.circular(18),
          splashColor: Colors.white.withValues(alpha: 0.35),
          highlightColor: Colors.white.withValues(alpha: 0.18),
          overlayColor: WidgetStateProperty.resolveWith<Color?>(
                (states) {
              if (states.contains(WidgetState.pressed)) {
                return Colors.white.withValues(alpha: 0.22);
              }
              return null;
            },
          ),

          splashFactory: InkRipple.splashFactory,
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: Icon(
                    _isConnected
                        ? Icons.stop_circle_outlined
                        : Icons.send_rounded,

                    key: ValueKey(_isConnected),
                    color: Colors.white,
                    size: 24,
                  ),
                ),

                const SizedBox(width: 12),

                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: Text(
                    _isConnected
                        ? 'Disconnect'
                        : 'Send Request',

                    key: ValueKey(_isConnected),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4,
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

  // ───────────────── COMMON ─────────────────

  Widget _card({
    required String title,
    required IconData icon,
    required Color color,
    required Widget child,
  }) {

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: _textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),

        const SizedBox(height: 18),

        child,
      ],
    );
  }

  Widget _fieldLabel(
      String label,
      IconData icon,
      Color color,
      ) {

    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: _textSec,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required FocusNode focusNode,
    required IconData icon,
    required Color color,
    List<TextInputFormatter>? formatters,
    ValueChanged<String>? onChanged,
  }) {

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel(label, icon, color),

        const SizedBox(height: 8),

        TextField(
          controller: controller,
          focusNode: focusNode,
          onTap: () {
            _setFocused(focusNode);
            setState(() {
              _isBaudDropdownOpen = false;
            });
          },

          onChanged: onChanged,
          inputFormatters: formatters,
          keyboardType: TextInputType.number,
          style: const TextStyle(
            color: _textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),

          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              color: _textSec,
              fontSize: 13,
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15,),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _borderColor,),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _borderColor,),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: _isFocused(focusNode) ? Colors.grey : _borderColor,
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResponseCard() {

    final status =
        _responseData?["status"] ?? "";

    final message =
        _responseData?["message"] ?? "";

    final modbusStatus =
        _responseData?["modbus_status"] ?? -1;

    final values =
        _responseData?["values"] ?? [];

    final isSuccess =
        status.toString().toLowerCase() ==
            "success";

    final reason =
    _getModbusReason(modbusStatus);

    return AnimatedContainer(

      duration: const Duration(milliseconds: 250),

      width: double.infinity,

      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(

        color: isSuccess
            ? _green.withValues(alpha: 0.08)
            : Colors.red.withValues(alpha: 0.08),

        borderRadius: BorderRadius.circular(16),

        border: Border.all(
          color:
          isSuccess ? _green : Colors.red,
        ),
      ),

      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,

        children: [

          Row(
            children: [

              Icon(
                isSuccess
                    ? Icons.check_circle_rounded
                    : Icons.error_rounded,

                color:
                isSuccess
                    ? _green
                    : Colors.red,
              ),

              const SizedBox(width: 10),

              Expanded(
                child: Text(

                  isSuccess
                      ? "Request Success"
                      : "Request Failed",

                  style: TextStyle(
                    color:
                    isSuccess
                        ? _green
                        : Colors.red,

                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          _responseTile(
            "Status",
            status.toUpperCase(),
          ),

          _responseTile(
            "Message",
            message,
          ),

          _responseTile(
            "Modbus Status",
            modbusStatus.toString(),
          ),

          const SizedBox(height: 14),

          Container(

            width: double.infinity,

            padding: const EdgeInsets.all(14),

            decoration: BoxDecoration(

              color:
              isSuccess
                  ? _green.withValues(alpha: 0.08)
                  : Colors.red.withValues(alpha: 0.08),

              borderRadius:
              BorderRadius.circular(12),
            ),

            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,

              children: [

                Text(
                  reason["title"] ?? "",

                  style: TextStyle(
                    color:
                    isSuccess
                        ? _green
                        : Colors.red,

                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  reason["description"] ?? "",

                  style: const TextStyle(
                    color: _textPrimary,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),

          if (isSuccess &&
              values.isNotEmpty) ...[

            const SizedBox(height: 18),

            const Text(
              "Register Values",

              style: TextStyle(
                color: _textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 10),

            Wrap(
              spacing: 10,
              runSpacing: 10,

              children: List.generate(
                values.length,

                    (index) {

                  return Container(

                    padding:
                    const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),

                    decoration: BoxDecoration(
                      color:
                      _green.withValues(alpha: 0.12),

                      borderRadius:
                      BorderRadius.circular(12),
                    ),

                    child: Text(
                      values[index].toString(),

                      style: const TextStyle(
                        color: _green,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _responseTile(
      String title,
      String value,
      ) {

    return Padding(
      padding:
      const EdgeInsets.only(bottom: 10),

      child: Row(
        crossAxisAlignment:
        CrossAxisAlignment.start,

        children: [

          SizedBox(
            width: 120,

            child: Text(
              title,

              style: const TextStyle(
                color: _textSec,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          Expanded(
            child: Text(
              value,

              style: const TextStyle(
                color: _textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ───────────────── RANGE FORMATTER ─────────────────

class _RangeInputFormatter extends TextInputFormatter {
  final int min;
  final int max;

  _RangeInputFormatter(this.min, this.max);

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue,) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    final value = int.tryParse(newValue.text);

    if (value == null || value < min || value > max) {
      return oldValue;
    }
    return newValue;
  }
}
