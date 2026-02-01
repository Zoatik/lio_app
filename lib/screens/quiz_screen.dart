import 'package:flutter/material.dart';

import '../models/quizz.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({
    super.key,
    required this.quizz,
    required this.onCompleted,
  });

  final Quizz quizz;
  final VoidCallback onCompleted;

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  final _answerController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  Future<void> _handleCorrect() async {
    if (_submitting) {
      return;
    }
    setState(() {
      _submitting = true;
    });
    final message = widget.quizz.message.isEmpty
        ? 'Bravo !'
        : widget.quizz.message;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
    await Future<void>.delayed(const Duration(milliseconds: 800));
    widget.onCompleted();
  }

  void _handleWrong() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Mauvaise réponse.')),
    );
  }

  void _submitText() {
    final input = _answerController.text;
    final isCorrect = widget.quizz.isCorrectAnswer(input);
    if (isCorrect) {
      _handleCorrect();
    } else {
      _handleWrong();
    }
  }

  void _submitChoice(int index) {
    final isCorrect = widget.quizz.isCorrectChoice(index);
    if (isCorrect) {
      _handleCorrect();
    } else {
      _handleWrong();
    }
  }

  @override
  Widget build(BuildContext context) {
    final quizz = widget.quizz;

    return Scaffold(
      appBar: AppBar(title: Text(quizz.title)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              quizz.question,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 16),
            if (quizz.questionImages != null &&
                quizz.questionImages!.isNotEmpty)
              SizedBox(
                height: 180,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: quizz.questionImages!.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final path = quizz.questionImages![index];
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.asset(
                        path,
                        width: 220,
                        height: 180,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const SizedBox.shrink(),
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 20),
            if (quizz.type == QuizzType.multipleChoice)
              ...List.generate(quizz.choices?.length ?? 0, (index) {
                final label = quizz.choices![index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _submitting ? null : () => _submitChoice(index),
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(label),
                    ),
                  ),
                );
              }),
            if (quizz.type == QuizzType.text)
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _answerController,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _submitText(),
                    decoration: const InputDecoration(
                      labelText: 'Ta réponse',
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _submitting ? null : _submitText,
                      child: const Text('Valider'),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
