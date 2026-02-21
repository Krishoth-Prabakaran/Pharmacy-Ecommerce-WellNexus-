import 'package:flutter/material.dart';
import 'dart:math';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Word Finder Game',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const WordGame(),
    );
  }
}

class WordGame extends StatefulWidget {
  const WordGame({super.key});

  @override
  State<WordGame> createState() => _WordGameState();
}

class _WordGameState extends State<WordGame> {
  final String targetWord = "CAT"; // The word player must find
  String selectedWord = ""; // The word the player selects
  final int gridSize = 3; // 3x3 grid
  late List<String> letters;

  @override
  void initState() {
    super.initState();
    _generateLetters();
  }

  void _generateLetters() {
    // Fill grid with random letters and include the target word letters
    letters = List.generate(gridSize * gridSize, (_) => String.fromCharCode(65 + Random().nextInt(26)));
    // Replace random positions with target letters
    for (int i = 0; i < targetWord.length; i++) {
      letters[i] = targetWord[i];
    }
    letters.shuffle();
  }

  void _selectLetter(String letter) {
    setState(() {
      selectedWord += letter;
    });
  }

  void _resetWord() {
    setState(() {
      selectedWord = "";
      _generateLetters();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Word Finder Game"),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Form the word: $targetWord",
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Text(
              "Your Word: $selectedWord",
              style: const TextStyle(fontSize: 20, color: Colors.blue),
            ),
            const SizedBox(height: 20),
            GridView.builder(
              shrinkWrap: true,
              itemCount: letters.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: gridSize,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
              ),
              itemBuilder: (context, index) {
                return ElevatedButton(
                  onPressed: selectedWord.length < targetWord.length
                      ? () => _selectLetter(letters[index])
                      : null,
                  child: Text(letters[index], style: const TextStyle(fontSize: 24)),
                );
              },
            ),
            const SizedBox(height: 20),
            if (selectedWord == targetWord)
              Column(
                children: [
                  const Text(
                    "🎉 You Found It! 🎉",
                    style: TextStyle(fontSize: 28, color: Colors.green, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: _resetWord,
                    child: const Text("Play Again"),
                  )
                ],
              )
            else if (selectedWord.length == targetWord.length)
              ElevatedButton(
                onPressed: _resetWord,
                child: const Text("Try Again"),
              ),
          ],
        ),
      ),
    );
  }
}
