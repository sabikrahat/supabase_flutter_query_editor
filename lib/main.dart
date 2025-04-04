import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:json_view/json_view.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Supabase Editor',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final formKey = GlobalKey<FormState>();
  final supabaseUrlCntrlr = TextEditingController();
  final supabaseAnonKeyCntrlr = TextEditingController();
  final supabaseTableNameCntrlr = TextEditingController();
  final supabaseEditorCntrlr = TextEditingController();

  Supabase? supabase;
  dynamic response;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSavedData();
  }

  Future<void> _loadSavedData() async {
    final prefs = await SharedPreferences.getInstance();
    supabaseUrlCntrlr.text = prefs.getString('supabase_url') ?? '';
    supabaseAnonKeyCntrlr.text = prefs.getString('supabase_anon_key') ?? '';
    supabaseTableNameCntrlr.text = prefs.getString('supabase_table') ?? '';
    supabaseEditorCntrlr.text = prefs.getString('supabase_editor') ?? '';
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('supabase_url', supabaseUrlCntrlr.text);
    await prefs.setString('supabase_anon_key', supabaseAnonKeyCntrlr.text);
    await prefs.setString('supabase_table', supabaseTableNameCntrlr.text);
    await prefs.setString('supabase_editor', supabaseEditorCntrlr.text);
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.deepPurpleAccent),
      filled: true,
      fillColor: Colors.white,

      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.deepPurpleAccent),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.deepPurple, width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Supabase Editor'),
        backgroundColor: Colors.deepPurpleAccent,
      ),
      body: Form(
        key: formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            const Text(
              "🧠 Supabase Query Editor",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              "Fill in your Supabase credentials and table info to fetch and display data beautifully formatted as JSON.",
              style: TextStyle(fontSize: 16, color: Colors.black54),
            ),
            const SizedBox(height: 24),

            // Input Fields
            TextFormField(
              controller: supabaseUrlCntrlr,
              decoration: _inputDecoration('Supabase URL'),
              validator:
                  (value) => value == null || value.isEmpty ? 'Please enter a Supabase URL' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: supabaseAnonKeyCntrlr,
              decoration: _inputDecoration('Supabase Anon Key'),
              validator:
                  (value) =>
                      value == null || value.isEmpty ? 'Please enter a Supabase Anon Key' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: supabaseTableNameCntrlr,
              decoration: _inputDecoration('Supabase Table Name'),
              validator:
                  (value) =>
                      value == null || value.isEmpty ? 'Please enter a Supabase Table Name' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: supabaseEditorCntrlr,
              minLines: 1,
              maxLines: 10,
              decoration: _inputDecoration('Supabase Editor (e.g. *)'),
              validator:
                  (value) =>
                      value == null || value.isEmpty ? 'Please enter a Supabase Editor' : null,
            ),
            const SizedBox(height: 24),

            // Submit Button
            isLoading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.cloud_download),
                  label: const Text("Fetch Data", style: TextStyle(fontSize: 16)),
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      setState(() => isLoading = true); // 👈 Show loader
                      await _saveData();
                      try {
                        supabase ??= await Supabase.initialize(
                          debug: !kReleaseMode,
                          url: supabaseUrlCntrlr.text,
                          anonKey: supabaseAnonKeyCntrlr.text,
                        );
                        debugPrint('Supabase initialized');
                        final res = await supabase?.client
                            .from(supabaseTableNameCntrlr.text)
                            .select(supabaseEditorCntrlr.text);
                        setState(() {
                          response = res;
                        });
                      } catch (e) {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text('Error: $e')));
                      } finally {
                        setState(() => isLoading = false); // 👈 Hide loader
                      }
                    }
                  },
                ),

            const SizedBox(height: 30),

            // JSON Result View
            if (response != null)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(top: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: JsonConfig(
                  data: JsonConfigData(
                    animation: true,
                    animationDuration: const Duration(milliseconds: 300),
                    animationCurve: Curves.ease,
                    itemPadding: const EdgeInsets.only(left: 8),
                    color: JsonColorScheme(
                      stringColor: Colors.lightGreenAccent,
                      numColor: Colors.orangeAccent,
                      boolColor: Colors.cyanAccent,
                      nullColor: Colors.redAccent,
                      normalColor: Colors.lightBlueAccent,
                    ),
                    style: JsonStyleScheme(
                      arrow: const Icon(Icons.arrow_right, color: Colors.white),
                      keysStyle: const TextStyle(color: Colors.lightBlueAccent),
                      valuesStyle: const TextStyle(color: Colors.lightGreenAccent),
                    ),
                  ),
                  child: JsonView(json: response, shrinkWrap: true, animation: true),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
