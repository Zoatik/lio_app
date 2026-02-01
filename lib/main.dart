import 'package:flutter/material.dart';

import 'data/quizzs_repository.dart';
import 'screens/map_screen.dart';
import 'screens/booster_screen.dart';
import 'storage/age_gate_storage.dart';
import 'storage/credentials_storage.dart';
import 'storage/progress_storage.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cado Lio',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1F6FEB),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const _Bootstrapper(),
    );
  }
}

class _Bootstrapper extends StatelessWidget {
  const _Bootstrapper();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: const AgeGateStorage().isVerified(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final verified = snapshot.data ?? false;
        return verified ? const MapScreen() : const HomeScreen();
      },
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _shift;
  final _userController = TextEditingController();
  final _passController = TextEditingController();
  String? _loginError;

  static const _expectedUser = 'Lionel';
  static const _expectedPass = 'Axelaunegrosseteub';

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat(reverse: true);
    _shift = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _userController.dispose();
    _passController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          AnimatedBuilder(
            animation: _shift,
            builder: (context, child) {
              final v = _shift.value;
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment(-1 + v * 2, -1),
                    end: Alignment(1 - v * 2, 1),
                    colors: const [
                      Color(0xFF061B3A),
                      Color(0xFF0B3A8D),
                      Color(0xFF1F6FEB),
                      Color(0xFFFFC928),
                    ],
                  ),
                ),
              );
            },
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _shift,
                builder: (context, child) {
                  return CustomPaint(
                    painter: _ClashBackgroundPainter(_shift.value),
                  );
                },
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'ACH... LIONEL !',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2.0,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              color: Colors.black.withValues(alpha: 115),
                              blurRadius: 16,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                  ),
                  const SizedBox(height: 30),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 235),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 60),
                          blurRadius: 18,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextField(
                          controller: _userController,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Utilisateur',
                            prefixIcon: Icon(Icons.person),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _passController,
                          textInputAction: TextInputAction.done,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'Mot de passe',
                            prefixIcon: Icon(Icons.lock),
                          ),
                        ),
                        if (_loginError != null) ...[
                          const SizedBox(height: 10),
                          Text(
                            _loginError!,
                            style: const TextStyle(
                              color: Colors.redAccent,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 58,
                    child: ElevatedButton(
                      onPressed: () {
                        final user = _userController.text.trim();
                        final pass = _passController.text;
                        if (user == _expectedUser && pass == _expectedPass) {
                          setState(() {
                            _loginError = null;
                          });
                          const CredentialsStorage().save(
                            username: user,
                            password: pass,
                          );
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const RegisterScreen(),
                            ),
                          );
                        } else {
                          setState(() {
                            _loginError = 'Identifiants incorrects.';
                          });
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFD54F),
                        foregroundColor: const Color(0xFF0B1B3B),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        elevation: 6,
                        textStyle: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.0,
                        ),
                      ),
                      child: const Text('START'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  static final DateTime _expectedDate = DateTime(2002, 1, 31);

  final _formKey = GlobalKey<FormState>();
  final _dobController = TextEditingController();

  bool _dateInvalid = false;
  DateTime? _selectedDob;

  @override
  void dispose() {
    _dobController.dispose();
    super.dispose();
  }

  void _submit() {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) {
      return;
    }
    setState(() {
      _dateInvalid = _selectedDob == null ||
          !_isSameDate(_selectedDob!, _expectedDate);
    });

    if (_dateInvalid) {
      return;
    }

    _handleSuccess();
  }

  Future<void> _handleSuccess() async {
    await const AgeGateStorage().setVerified(true);
    final quizzs = await const QuizzsRepository().load();
    final tutorial = quizzs.firstWhere(
      (q) => q.isTutorial,
      orElse: () => quizzs.first,
    );
    final storage = const ProgressStorage();
    final progress = await storage.load();
    final unlocked = Set<String>.from(progress.unlockedMediaIds)
      ..addAll(tutorial.rewardMedia.map((media) => media.id));
    final updated = progress.copyWith(unlockedMediaIds: unlocked);
    await storage.save(updated);
    if (!mounted) {
      return;
    }
    await Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (ctx) => BoosterScreen(
          media: tutorial.rewardMedia,
          showTutorial: true,
          onDone: () => Navigator.of(ctx).pushReplacement(
            MaterialPageRoute(builder: (_) => const MapScreen()),
          ),
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDob ?? now,
      firstDate: DateTime(1900),
      lastDate: DateTime(now.year + 1),
      helpText: 'Sélectionne ta date de naissance',
    );
    if (picked == null) {
      return;
    }
    setState(() {
      _selectedDob = picked;
      _dobController.text = _formatDate(picked);
      _dateInvalid = false;
    });
  }

  static bool _isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  static String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString().padLeft(4, '0');
    return '$day.$month.$year';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF061B3A),
                  Color(0xFF0B3A8D),
                  Color(0xFF1F6FEB),
                  Color(0xFFFFC928),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 8),
                    Text(
                      'Vérification de l\'âge',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Juste pour être sûr...',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 220),
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 235),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 60),
                            blurRadius: 18,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextFormField(
                            controller: _dobController,
                            textInputAction: TextInputAction.done,
                            readOnly: true,
                            onTap: _pickDate,
                            decoration: InputDecoration(
                              labelText: 'Date de naissance',
                              hintText: 'JJ.MM.AAAA',
                              errorText: _dateInvalid
                                  ? 'Mauvaise date. Essaie encore.'
                                  : null,
                              prefixIcon: const Icon(Icons.cake),
                            ),
                            onFieldSubmitted: (_) => _submit(),
                            validator: (value) {
                              if (_selectedDob == null) {
                                return 'Date requise.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 52,
                            child: ElevatedButton(
                              onPressed: _submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFFD54F),
                                foregroundColor: const Color(0xFF0B1B3B),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                textStyle: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.4,
                                ),
                              ),
                              child: const Text('Valider'),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
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

class _ClashBackgroundPainter extends CustomPainter {
  _ClashBackgroundPainter(this.value);

  final double value;

  @override
  void paint(Canvas canvas, Size size) {
    final t = value;

    final bandPaintBlue = Paint()
      ..color = const Color(0xFF1E4FD8).withValues(alpha: 51);
    final bandPaintGold = Paint()
      ..color = const Color(0xFFFFC928).withValues(alpha: 51);

    final bandHeight = size.height * 0.22;
    final shift = size.width * 0.28 * t;

    canvas.save();
    canvas.translate(-size.width * 0.2 + shift, -size.height * 0.1 + shift);
    canvas.rotate(-0.35);
    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 0.2, size.width * 1.8, bandHeight),
      bandPaintBlue,
    );
    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 0.55, size.width * 1.8, bandHeight * 0.7),
      bandPaintGold,
    );
    canvas.restore();

    final paint = Paint()..blendMode = BlendMode.screen;

    final orb1 = Offset(size.width * (0.18 + 0.12 * t), size.height * 0.25);
    paint.shader = RadialGradient(
      colors: [
        const Color(0xFF4FC3F7).withValues(alpha: 115),
        const Color(0xFF0B3A8D).withValues(alpha: 0),
      ],
    ).createShader(Rect.fromCircle(center: orb1, radius: size.width * 0.55));
    canvas.drawCircle(orb1, size.width * 0.5, paint);

    final orb2 = Offset(size.width * (0.88 - 0.12 * t), size.height * 0.82);
    paint.shader = RadialGradient(
      colors: [
        const Color(0xFFFFD54F).withValues(alpha: 89),
        const Color(0xFFFF8A00).withValues(alpha: 0),
      ],
    ).createShader(Rect.fromCircle(center: orb2, radius: size.width * 0.6));
    canvas.drawCircle(orb2, size.width * 0.55, paint);
  }

  @override
  bool shouldRepaint(covariant _ClashBackgroundPainter oldDelegate) {
    return oldDelegate.value != value;
  }
}


