import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_gemini/models.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/environment_config.dart';
import 'message_widget.dart';

class ChatWidget extends StatefulWidget {
  const ChatWidget({super.key});

  @override
  State<ChatWidget> createState() => _ChatWidgetState();
}

class _ChatWidgetState extends State<ChatWidget> {
  late final GenerativeModel _modelImage;
  late final GenerativeModel _modelChat;
  late final ChatSession _chat;

  final ScrollController _scrollController = ScrollController();
  final TextEditingController _textController = TextEditingController();
  final FocusNode _textFieldFocus = FocusNode();
  bool _loading = false;
  static final _apiKey = EnvConfig().apiKey;
  List<ImageChatModel> chatResponses = [];
  List<XFile> images = [];

  @override
  void initState() {
    super.initState();
    _modelImage = GenerativeModel(
      // model: 'gemini-pro',
      model: 'gemini-pro-vision',
      apiKey: _apiKey!,
    );
    _modelChat = GenerativeModel(
      model: 'gemini-pro',
      apiKey: _apiKey!,
    );
    _chat = _modelChat.startChat();
  }

  void _scrollDown() {
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(
          milliseconds: 750,
        ),
        curve: Curves.easeOutCirc,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    var textFieldDecoration = InputDecoration(
      contentPadding: const EdgeInsets.all(15),
      hintText: 'Enter a prompt',
      border: OutlineInputBorder(
        borderRadius: const BorderRadius.all(
          Radius.circular(14),
        ),
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.secondary,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: const BorderRadius.all(
          Radius.circular(14),
        ),
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.secondary,
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _apiKey != null && _apiKey!.isNotEmpty
                ? ListView.builder(
                    controller: _scrollController,
                    itemBuilder: (context, idx) {
                      // var content = _chat.history.toList()[idx];
                      // var text = content.parts
                      //     .whereType<TextPart>()
                      //     .map<String>((e) => e.text)
                      //     .join('');
                      return MessageWidget(
                        chats: chatResponses[idx],
                        isFromUser: idx % 2 == 0,
                        // isFromUser: content.role == 'user',
                      );
                    },
                    itemCount: chatResponses.length,
                    // itemCount: _chat.history.length,?
                  )
                : ListView(
                    children: const [
                      Text('No API key found. Please provide an API Key.'),
                    ],
                  ),
          ),
          if (images.isNotEmpty)
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                ...List.generate(
                    images.length,
                    (index) => SizedBox(
                          height: 60,
                          width: 60,
                          child: Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: GestureDetector(
                              onTap: () {
                                images.removeAt(index);
                                setState(() {});
                              },
                              child: Image.file(
                                File(images[index].path),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ))
              ],
            ),
          Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 25,
              horizontal: 15,
            ),
            child: Row(
              children: [
                IconButton(
                    onPressed: () {
                      onTapImage();
                    },
                    icon: const Icon(Icons.image)),
                Expanded(
                  child: TextField(
                    autofocus: true,
                    focusNode: _textFieldFocus,
                    decoration: textFieldDecoration,
                    controller: _textController,
                    onSubmitted: (String value) {
                      _sendMessage(value);
                    },
                  ),
                ),
                const SizedBox.square(
                  dimension: 15,
                ),
                if (!_loading)
                  IconButton(
                    onPressed: () async {
                      // _sendChatMessage(_textController.text);
                      _sendMessage(_textController.text);
                    },
                    icon: Icon(
                      Icons.send,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  )
                else
                  const CircularProgressIndicator(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  XFile? pickedFile;

  onTapImage() async {
    if (images.length < 2) {
      pickedFile = await ImagePicker()
          .pickImage(source: ImageSource.gallery, imageQuality: 50);

      if (pickedFile != null) {
        setState(() {
          images.add(pickedFile!);
        });
        // _sendChatMessageWithImage(_textController.text);
      }
    }
  }

  Future<Uint8List> _getImageBytes(File file) {
    return file.readAsBytes();
  }

  _sendMessage(String message) {
    if (message.isEmpty) {
      return;
    }
    setState(() {
      chatResponses.add(ImageChatModel(
          text: message, imagePaths: images.map((e) => e.path).toList()));
    });
    if (images.isEmpty) {
      _sendChatMessage(message);
    } else {
      _sendChatMessageWithImage(message);
    }
  }

  _sendChatMessageWithImage(String message) async {
    try {
      setState(() {
        _loading = true;
      });

      // var listOfImageBytes = [];
      var imageParts = [];
      for (var image in images) {
        await _getImageBytes(File(image.path));
        imageParts.add(
            DataPart('image/jpeg', await _getImageBytes(File(image.path))));
      }
      // final firstImage = await _getImageBytes(File(images[0].path));
      // final secondImage = await _getImageBytes(File(images[1].path));

      final prompt = TextPart(message);
      // final firstImage = await _getImageBytes(File(pickedFile!.path));
      // final imageParts = [
      //   DataPart('image/jpeg', firstImage),
      //   DataPart('image/jpeg', secondImage),
      // ];

      final responses = await _modelImage.generateContent([
        Content.multi([prompt, ...imageParts])
      ]);
      var text = responses.text;
      setState(() {
        chatResponses
            .add(ImageChatModel(text: text ?? "No response from API."));
        // _scrollDown();
      });

      if (text == null) {
        _showError('No response from API.');
        return;
      } else {
        setState(() {
          _loading = false;
          _scrollDown();
          images.clear();
        });
      }
    } catch (e) {
      _showError(e.toString());
      setState(() {
        _loading = false;
      });
    } finally {
      _textController.clear();
      setState(() {
        _loading = false;
      });
      _textFieldFocus.requestFocus();
    }
  }

  Future<void> _sendChatMessage(String message) async {
    setState(() {
      _loading = true;
    });

    try {
      var response = await _chat?.sendMessage(
        Content.text(message),
      );
      var text = response?.text;

      if (text == null) {
        _showError('No response from API.');
        return;
      } else {
        setState(() {
          chatResponses.add(ImageChatModel(text: text));
          _loading = false;
          _scrollDown();
        });
      }
    } catch (e) {
      _showError(e.toString());
      setState(() {
        _loading = false;
      });
    } finally {
      _textController.clear();
      setState(() {
        // _loading = false;
      });
      _textFieldFocus.requestFocus();
    }
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Something went wrong'),
          content: SingleChildScrollView(
            child: SelectableText(message),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            )
          ],
        );
      },
    );
  }
}
