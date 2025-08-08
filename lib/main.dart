import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

void main() => runApp(const KratosApp());

class KratosApp extends StatelessWidget {
  const KratosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kratos GPT',
      theme: ThemeData(
        colorScheme: ColorScheme(
          brightness: Brightness.dark,
          primary: const Color(0xFF8B0000), // rojo sangre
          onPrimary: Colors.white,
          secondary: const Color(0xFFC0C0C0), // metálico
          onSecondary: Colors.black,
          surface: const Color(0xFF1A1A1A), // fondo oscuro
          onSurface: Colors.white,
          background: const Color(0xFF1A1A1A),
          onBackground: Colors.white,
          error: Colors.red,
          onError: Colors.white,
        ),
        scaffoldBackgroundColor: const Color(0xFF1A1A1A),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          scrolledUnderElevation: 2,
          centerTitle: false,
          backgroundColor: Color(0xFF8B0000),
          titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          iconTheme: IconThemeData(color: Colors.white),
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF2B2B2B),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Color(0xFF333333), width: 1),
          ),
          margin: EdgeInsets.zero,
        ),
        dividerTheme: const DividerThemeData(
          color: Color(0xFF333333),
          thickness: 1,
          space: 0,
        ),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Colors.white),
          bodySmall: TextStyle(color: Colors.white70),
        ),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      home: const ChatScreen(),
    );
  }
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<ChatMessage> _messages = [];
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  bool _showOptions = false;

  static const _predefinedResponses = {
    "hola": "¡Saludos guerrero! Soy Kratos GPT. ¿En qué puedo servirte hoy?",
    "¿quién eres?":
        "Soy Kratos GPT, tu asistente basado en la sabiduría y fuerza del Dios de la Guerra. Pero no te preocupes, estoy aquí para ayudarte, no para destruirte.",
    "help":
        "Puedo ayudarte con:\n\n• Respuestas a preguntas\n• Generación de contenido\n• Asistencia con código\n• Análisis de datos\n\nDi '¡Por los dioses!' y dime qué necesitas.",
    "gracias":
        "No es necesaria tu gratitud, pero es apreciada. ¿Necesitas algo más?",
    "adiós":
        "Que los dioses te guíen en tu viaje. Regresa cuando necesites mi ayuda.",
  };

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty && _selectedImage == null) return;

    setState(() {
      _messages.add(
        ChatMessage(
          sender: 'user',
          text: text,
          image: _selectedImage,
          timestamp: DateTime.now(),
        ),
      );
      _isLoading = true;
      _messageController.clear();
      _selectedImage = null;
      _showOptions = false;
    });

    _scrollToBottom();

    await Future.delayed(const Duration(milliseconds: 300));

    if (_predefinedResponses.containsKey(text.toLowerCase())) {
      setState(() {
        _messages.add(
          ChatMessage(
            sender: 'kratos',
            text: _predefinedResponses[text.toLowerCase()]!,
            timestamp: DateTime.now(),
          ),
        );
        _isLoading = false;
      });
      _scrollToBottom();
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {
          'Authorization': 'Bearer TU_API_DE_KratosGPT',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': 'gpt-4',
          'messages': [
            {
              'role': 'system',
              'content':
                  'Eres Kratos GPT, el asistente basado en el Dios de la Guerra. '
                  'Responde con un tono fuerte pero sabio, usando ocasionalmente frases icónicas de Kratos. '
                  'Mantén respuestas directas pero detalladas cuando sea necesario. '
                  'Usa emojis SPARINGLY solo cuando refuercen el mensaje.',
            },
            {'role': 'user', 'content': text},
          ],
          'temperature': 0.7,
          'max_tokens': 500,
        }),
      );

      setState(() => _isLoading = false);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final responseText = data['choices'][0]['message']['content'].trim();

        setState(() {
          _messages.add(
            ChatMessage(
              sender: 'kratos',
              text: responseText,
              timestamp: DateTime.now(),
            ),
          );
        });
      } else {
        setState(() {
          _messages.add(
            ChatMessage(
              sender: 'kratos',
              text:
                  '¡Por los dioses! Algo ha fallado (Error ${response.statusCode})',
              timestamp: DateTime.now(),
            ),
          );
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _messages.add(
          ChatMessage(
            sender: 'kratos',
            text:
                '¡Las puertas del Infierno están cerradas! No puedo conectarme ahora: ${e.toString()}',
            timestamp: DateTime.now(),
          ),
        );
      });
    }

    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
        _showOptions = false;
      });
    }
  }

  Widget _buildMessage(ChatMessage message) {
    final isUser = message.sender == 'user';
    final colors = Theme.of(context).colorScheme;
    final isKratos = message.sender == 'kratos';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          if (!isUser)
            Container(
              width: 32,
              height: 32,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isKratos
                    ? colors.primary.withOpacity(0.2)
                    : colors.secondary.withOpacity(0.1),
              ),
              child: Center(
                child: Icon(
                  isKratos ? Icons.bolt : Icons.help_outline,
                  size: 16,
                  color: isKratos ? colors.primary : colors.secondary,
                ),
              ),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: isUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                if (!isUser)
                  Text(
                    isKratos ? 'KRATOS GPT' : 'SISTEMA',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                      color: isKratos
                          ? colors.primary.withOpacity(0.8)
                          : colors.secondary.withOpacity(0.8),
                    ),
                  ),
                const SizedBox(height: 4),
                if (message.image != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      message.image!,
                      width: 220,
                      height: 220,
                      fit: BoxFit.cover,
                    ),
                  ),
                if (message.text.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 16,
                    ),
                    decoration: BoxDecoration(
                      color: isUser
                          ? colors.primary
                          : isKratos
                          ? colors.primary.withOpacity(0.05)
                          : colors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isUser
                            ? Colors.transparent
                            : const Color(0xFFE6E0F2),
                        width: 1,
                      ),
                    ),
                    child: SelectableText(
                      message.text,
                      style: TextStyle(
                        color: isUser ? Colors.white : colors.onSurface,
                        fontSize: 15,
                        height: 1.5,
                      ),
                    ),
                  ),
                const SizedBox(height: 4),
                Text(
                  _formatTime(message.timestamp),
                  style: TextStyle(
                    fontSize: 10,
                    color: colors.onSurface.withOpacity(0.4),
                  ),
                ),
              ],
            ),
          ),
          if (isUser)
            Container(
              width: 32,
              height: 32,
              margin: const EdgeInsets.only(left: 12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colors.primary.withOpacity(0.1),
              ),
              child: Center(
                child: Icon(Icons.person, size: 16, color: colors.primary),
              ),
            ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('KRATOS GPT'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              setState(() {
                _messages.add(
                  ChatMessage(
                    sender: 'kratos',
                    text:
                        '¡Soy Kratos GPT! Versión ${DateTime.now().year}. '
                        'Construido con la fuerza de los dioses y la sabiduría del Ragnarök.',
                    timestamp: DateTime.now(),
                  ),
                );
                _scrollToBottom();
              });
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: NetworkImage(
                  'https://placehold.co/600x1000/ddd/6C0BA9?text=KRATOS&font=montserrat',
                ),
                opacity: 0.03,
                fit: BoxFit.cover,
              ),
            ),
            child: Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                    itemCount: _messages.length + (_isLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _messages.length) {
                        return _buildTypingIndicator();
                      }
                      return _buildMessage(_messages[index]);
                    },
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: colors.surface,
                border: Border(
                  top: BorderSide(color: const Color(0xFFE6E0F2), width: 1),
                ),
              ),
              child: Column(
                children: [
                  if (_showOptions)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildOptionButton(
                                icon: Icons.image,
                                label: 'Galería',
                                onTap: () => _pickImage(ImageSource.gallery),
                              ),
                              _buildOptionButton(
                                icon: Icons.camera_alt,
                                label: 'Cámara',
                                onTap: () => _pickImage(ImageSource.camera),
                              ),
                              _buildOptionButton(
                                icon: Icons.help,
                                label: 'Ayuda',
                                onTap: () {
                                  setState(() {
                                    _messages.add(
                                      ChatMessage(
                                        sender: 'kratos',
                                        text:
                                            'Comandos disponibles:\n\n'
                                            '• "ayuda" - Muestra esto\n'
                                            '• "borrar" - Limpia la conversación\n'
                                            '• "historial" - Muestra el historial\n'
                                            '\nNo necesitas pedir permiso, solo di lo que necesitas.',
                                        timestamp: DateTime.now(),
                                      ),
                                    );
                                    _showOptions = false;
                                    _scrollToBottom();
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          _showOptions ? Icons.close : Icons.add,
                          color: colors.primary,
                        ),
                        onPressed: () {
                          setState(() {
                            _showOptions = !_showOptions;
                          });
                        },
                      ),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: colors.surface,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: const Color(0xFFE6E0F2),
                              width: 1,
                            ),
                          ),
                          child: TextField(
                            controller: _messageController,
                            decoration: InputDecoration(
                              hintText: 'Habla, guerrero...',
                              border: InputBorder.none,
                              hintStyle: TextStyle(
                                color: colors.onSurface.withOpacity(0.4),
                              ),
                            ),
                            maxLines: 4,
                            minLines: 1,
                            onSubmitted: (value) => _sendMessage(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: _isLoading ? 48 : 56,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _isLoading
                              ? colors.primary.withOpacity(0.1)
                              : colors.primary,
                        ),
                        child: IconButton(
                          icon: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.send, color: Colors.white),
                          onPressed: _isLoading ? null : _sendMessage,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE6E0F2), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
            ),
            child: Center(
              child: Icon(
                Icons.bolt,
                size: 16,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'KRATOS GPT',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.8),
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 4),
              SizedBox(
                width: 120,
                child: LinearProgressIndicator(
                  minHeight: 2,
                  borderRadius: BorderRadius.circular(2),
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class ChatMessage {
  final String sender;
  final String text;
  final File? image;
  final DateTime timestamp;

  ChatMessage({
    required this.sender,
    this.text = '',
    this.image,
    required this.timestamp,
  });
}
