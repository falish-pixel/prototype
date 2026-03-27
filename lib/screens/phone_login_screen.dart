// Файл: lib/screens/phone_login_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/language_service.dart';

class PhoneLoginScreen extends StatefulWidget {
  const PhoneLoginScreen({super.key});

  @override
  State<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends State<PhoneLoginScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _smsController = TextEditingController();

  bool _codeSent = false;
  String _verificationId = '';
  bool _isLoading = false;

  // --- СПИСОК КОДОВ СТРАН ---
  final List<Map<String, String>> _countryCodes = [
    {'code': '+7', 'flag': '🇰🇿'},
    {'code': '+7', 'flag': '🇷🇺'},
    {'code': '+996', 'flag': '🇰🇬'},
    {'code': '+998', 'flag': '🇺🇿'},
    {'code': '+1', 'flag': '🇺🇸'},
  ];

  // Код по умолчанию
  String _selectedCountryCode = '+7';
  String _selectedFlag = '🇰🇿';

  Future<void> _verifyPhone() async {
    setState(() => _isLoading = true);

    // Склеиваем код страны и введенный номер
    final String fullPhoneNumber = '$_selectedCountryCode${_phoneController.text.trim()}';

    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: fullPhoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Firebase автоматически вошел в систему (тестовый номер или авто-перехват)
          await FirebaseAuth.instance.signInWithCredential(credential);

          // ЗАКРЫВАЕМ ЭКРАН ПОСЛЕ УСПЕШНОГО АВТО-ВХОДА
          if (mounted) {
            Navigator.pop(context);
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${LanguageService.tr('error')}: ${e.message}')),
          );
        },
        codeSent: (String verificationId, int? resendToken) {
          setState(() {
            _verificationId = verificationId;
            _codeSent = true;
            _isLoading = false;
          });
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
      );
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithSms() async {
    setState(() => _isLoading = true);
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId,
        smsCode: _smsController.text.trim(),
      );
      await FirebaseAuth.instance.signInWithCredential(credential);

      // Закрываем экран после ручного ввода правильного кода
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(LanguageService.tr('invalid_sms'))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(LanguageService.tr('login_phone'))),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!_codeSent) ...[
              // --- ПОЛЕ ВВОДА НОМЕРА С КОДОМ СТРАНЫ ---
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: LanguageService.tr('phone_hint'),
                  border: const OutlineInputBorder(),
                  prefixIcon: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: '$_selectedFlag:$_selectedCountryCode',
                            icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
                            items: _countryCodes.map((country) {
                              return DropdownMenuItem<String>(
                                value: '${country['flag']}:${country['code']}',
                                child: Text('${country['flag']} ${country['code']}'),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                final parts = value.split(':');
                                setState(() {
                                  _selectedFlag = parts[0];
                                  _selectedCountryCode = parts[1];
                                });
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(width: 1, height: 24, color: Colors.grey.shade400),
                        const SizedBox(width: 12),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                onPressed: _verifyPhone,
                style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                child: Text(LanguageService.tr('get_code')),
              ),
            ] else ...[
              TextField(
                controller: _smsController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: LanguageService.tr('sms_code'),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                onPressed: _signInWithSms,
                style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                child: Text(LanguageService.tr('enter')),
              ),
            ],
          ],
        ),
      ),
    );
  }
}