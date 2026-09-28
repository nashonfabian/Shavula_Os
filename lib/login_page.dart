import 'package:flutter/material.dart';
import 'helpers/auth_helper.dart';
import 'supplier_home_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final AuthHelper _authHelper = AuthHelper();

  void _goToHome(AuthResult result) {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => SupplierHomePage(
          userId: result.userId,
          userEmail: result.email,
          fullName: result.fullName,
          wasOffline: result.wasOffline,
        ),
      ),
    );
  }

  // ---------------- POPUP: INGIA (LOGIN) ----------------
  void _showLoginDialog() {
    final emailCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();
    bool isLoading = false;
    String? errorText;

    showDialog(
      context: context,
      barrierDismissible: !isLoading,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> handleLogin() async {
              if (emailCtrl.text.trim().isEmpty || passwordCtrl.text.isEmpty) {
                setDialogState(
                    () => errorText = 'Jaza barua pepe na namba ya siri.');
                return;
              }
              setDialogState(() {
                isLoading = true;
                errorText = null;
              });
              try {
                final result = await _authHelper.loginUser(
                  emailCtrl.text,
                  passwordCtrl.text,
                );
                if (dialogContext.mounted) Navigator.of(dialogContext).pop();
                _goToHome(result);
              } catch (e) {
                setDialogState(() {
                  isLoading = false;
                  errorText = e.toString().replaceFirst('Exception: ', '');
                });
              }
            }

            return AlertDialog(
              title: const Text('Ingia'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                          labelText: 'Barua pepe (Email)'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: passwordCtrl,
                      obscureText: true,
                      decoration:
                          const InputDecoration(labelText: 'Namba ya siri'),
                    ),
                    if (errorText != null) ...[
                      const SizedBox(height: 12),
                      Text(errorText!,
                          style: const TextStyle(color: Colors.red)),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isLoading
                      ? null
                      : () => Navigator.of(dialogContext).pop(),
                  child: const Text('Ghairi'),
                ),
                ElevatedButton(
                  onPressed: isLoading ? null : handleLogin,
                  child: isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Ingia'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ---------------- POPUP: JISAJILI (REGISTER) ----------------
  void _showRegisterDialog() {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    bool isLoading = false;
    String? errorText;

    showDialog(
      context: context,
      barrierDismissible: !isLoading,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> handleRegister() async {
              if (nameCtrl.text.trim().isEmpty ||
                  emailCtrl.text.trim().isEmpty ||
                  passwordCtrl.text.isEmpty) {
                setDialogState(() => errorText = 'Jaza sehemu zote.');
                return;
              }
              if (passwordCtrl.text.length < 6) {
                setDialogState(
                    () => errorText = 'Namba ya siri iwe angalau herufi 6.');
                return;
              }
              if (passwordCtrl.text != confirmCtrl.text) {
                setDialogState(() => errorText = 'Namba za siri hazifanani.');
                return;
              }
              setDialogState(() {
                isLoading = true;
                errorText = null;
              });
              try {
                final result = await _authHelper.registerUser(
                  emailCtrl.text,
                  passwordCtrl.text,
                  nameCtrl.text.trim(),
                );
                if (!dialogContext.mounted) return;
                Navigator.of(dialogContext).pop();
                if (result == null) {
                  if (mounted) {
                    ScaffoldMessenger.of(this.context).showSnackBar(
                      const SnackBar(
                        content: Text(
                            'Kagua barua pepe yako kwa kiungo cha uthibitisho, kisha ingia.'),
                      ),
                    );
                  }
                  return;
                }
                _goToHome(result);
              } catch (e) {
                setDialogState(() {
                  isLoading = false;
                  errorText = e.toString().replaceFirst('Exception: ', '');
                });
              }
            }

            return AlertDialog(
              title: const Text('Jisajili'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: nameCtrl,
                      decoration:
                          const InputDecoration(labelText: 'Jina kamili'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                          labelText: 'Barua pepe (Email)'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: passwordCtrl,
                      obscureText: true,
                      decoration:
                          const InputDecoration(labelText: 'Namba ya siri'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: confirmCtrl,
                      obscureText: true,
                      decoration: const InputDecoration(
                          labelText: 'Thibitisha namba ya siri'),
                    ),
                    if (errorText != null) ...[
                      const SizedBox(height: 12),
                      Text(errorText!,
                          style: const TextStyle(color: Colors.red)),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isLoading
                      ? null
                      : () => Navigator.of(dialogContext).pop(),
                  child: const Text('Ghairi'),
                ),
                ElevatedButton(
                  onPressed: isLoading ? null : handleRegister,
                  child: isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Jisajili'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D2380),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'SHAVULA ',
              style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 18),
            ),
            Text(
              'OS',
              style: TextStyle(
                  color: Color(0xFFD4A017),
                  fontWeight: FontWeight.bold,
                  fontSize: 18),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Bidhaa',
                      style: TextStyle(color: Colors.white, fontSize: 16)),
                ),
                const Text('Mtoa Bidhaa',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline)),
                const Text('Mteja',
                    style: TextStyle(color: Colors.white, fontSize: 16)),
              ],
            ),
            const SizedBox(height: 20),

            // Vitufe vya Ingia na Jisajili - sasa vinafungua popups halisi
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: _showLoginDialog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 30, vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Ingia',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 15),
                ElevatedButton(
                  onPressed: _showRegisterDialog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF64D2D0),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 30, vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Jisajili',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 30),

            const Text(
              'Usimamizi wa kazi na malipo',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF0D2380),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'SHAVULA inakusaidia kurekodi wateja, kufuatilia kazi za kila siku, kudhibiti kazi ambazo hazijalipwa na kupata ripoti za siku, wiki, mwezi na muda wote za shughuli zako za kazi na mapato yako yote kwa usalama na uhakika wa 100%\n\n'
                'KUMBUKA :SHAVULA ni mfumo wa kusaidia watoa huduma kutunza kumbukumbu za mauzo ya awamu. SISI SI TAASISI YA FEDHA (BANK)',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
