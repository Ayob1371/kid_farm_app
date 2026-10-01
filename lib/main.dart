import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_animate/flutter_animate.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const PersonalizedFarmApp());
}

class PersonalizedFarmApp extends StatelessWidget {
  const PersonalizedFarmApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'مزرعه هوشمند',
      theme: ThemeData(useMaterial3: true, fontFamily: 'sans-serif'),
      home: const MainGameScreen(),
    );
  }
}

class MainGameScreen extends StatefulWidget {
  const MainGameScreen({super.key});

  @override
  State<MainGameScreen> createState() => _MainGameScreenState();
}

class _MainGameScreenState extends State<MainGameScreen> {
  final FlutterTts _tts = FlutterTts();
  final stt.SpeechToText _speech = stt.SpeechToText();
  
  String _childName = '';
  bool _isListening = false;
  String _spokenText = '';
  String _targetPhrase = 'سلام گاو مهربون';
  
  final TextEditingController _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initTts();
    _loadChildName();
  }

  void _initTts() async {
    await _tts.setLanguage("fa-IR");
    await _tts.setPitch(1.2);
    await _tts.setSpeechRate(0.4);
  }

  void _loadChildName() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _childName = prefs.getString('child_name') ?? '';
      _nameController.text = _childName;
    });
    if (_childName.isNotEmpty) {
      _speak("سلام $_childName جان! خوش اومدی به مزرعه!");
    }
  }

  void _saveChildName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('child_name', name);
    setState(() {
      _childName = name;
    });
    _speak("عالیه! حالا با هم بازی می‌کنیم $_childName جان!");
  }

  Future<void> _speak(String text) async {
    await _tts.speak(text);
  }

  void _listenAndRepeat() async {
    bool available = await _speech.initialize();
    if (available) {
      setState(() => _isListening = true);
      _speak("$_childName جان، حالا تو بگو: $_targetPhrase");
      
      await Future.delayed(const Duration(seconds: 3));
      
      _speech.listen(
        onResult: (result) {
          setState(() {
            _spokenText = result.recognizedWords;
            _isListening = false;
          });
          _speak("آفرین $_childName خفن! خیلی خوب گفتی!");
        },
        localeId: "fa_IR",
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF81D4FA), Color(0xFFA5D6A7)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                if (_childName.isEmpty)
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          const Text("اسم گل پسرت رو وارد کن:", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                          TextField(
                            controller: _nameController,
                            textAlign: TextAlign.center,
                            decoration: const InputDecoration(hintText: "مثلاً: پسرم"),
                          ),
                          const SizedBox(height: 10),
                          ElevatedButton(
                            onPressed: () => _saveChildName(_nameController.text),
                            child: const Text("شروع بازی"),
                          )
                        ],
                      ),
                    ),
                  )
                else
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("دوست کوچک: $_childName", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.white),
                        onPressed: () => setState(() => _childName = ''),
                      )
                    ],
                  ),

                const SizedBox(height: 30),

                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: () {
                          _speak("$_childName جان! روی گاو بزن تا صداشو بشنوی!");
                        },
                        child: Container(
                          padding: const EdgeInsets.all(30),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 15)],
                          ),
                          child: const Text("🐮", style: TextStyle(fontSize: 90)),
                        ).animate().scale(duration: 500.ms),
                      ),
                      const SizedBox(height: 30),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          backgroundColor: Colors.orangeAccent,
                        ),
                        onPressed: _listenAndRepeat,
                        icon: Icon(_isListening ? Icons.mic : Icons.volume_up, color: Colors.white),
                        label: Text(
                          _isListening ? "دارم گوش میدم..." : "تکرار جمله با $_childName",
                          style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                      if (_spokenText.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Text("شنیدم گفتی: $_spokenText", style: const TextStyle(fontSize: 18, color: Colors.white)),
                        )
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

