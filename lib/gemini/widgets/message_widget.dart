import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_gemini/models.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class MessageWidget extends StatelessWidget {
  // final String text;
  final ImageChatModel chats;
  final bool isFromUser;

  const MessageWidget({
    super.key,
    required this.chats,
    required this.isFromUser,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment:
          isFromUser ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                constraints: const BoxConstraints(maxWidth: 600),
                decoration: BoxDecoration(
                  color: isFromUser
                      ? Theme.of(context).colorScheme.primaryContainer
                      : Theme.of(context).colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(18),
                ),
                padding: const EdgeInsets.symmetric(
                  vertical: 15,
                  horizontal: 20,
                ),
                margin: const EdgeInsets.only(bottom: 8),
                child: MarkdownBody(
                  onTapLink: (a, b, c) {
                    print(" a: $a b: $b c: $c");
                  },
                  selectable: true,
                  data: chats.text,
                ),
              ),
              if (chats.imagePaths != null)
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ...chats.imagePaths!.map((e) => SizedBox(
                          height: 60,
                          width: 60,
                          child: Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: Image.file(
                              File(e),
                              fit: BoxFit.cover,
                            ),
                          ),
                        )),
                  ],
                ),
              const SizedBox(
                height: 16,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
