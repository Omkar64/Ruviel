import 'package:flutter/material.dart';

class MessagesScreen extends StatelessWidget {
  final Function(String username) onChatSelected;

  const MessagesScreen({super.key, required this.onChatSelected});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> chats = [
      {
        "name": "Mama bois group",
        "lastMessage": "Akul sent an attachment.",
        "time": "13m",
        "avatar": "https://i.pravatar.cc/150?img=12",
      },
      {
        "name": "Akul Sajith",
        "lastMessage": "Akul sent an attachment.",
        "time": "53m",
        "avatar": "https://i.pravatar.cc/150?img=32",
      },
      {
        "name": "happy birthday manya",
        "lastMessage": "mitul sent an attachment.",
        "time": "2h",
        "avatar": "https://i.pravatar.cc/150?img=5",
      },
      {
        "name": "Nischay",
        "lastMessage": "Nischay sent an attachment.",
        "time": "4h",
        "avatar": "https://i.pravatar.cc/150?img=9",
      },
    ];

    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "_omkarnilangi_",
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              TextField(
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: "Search",
                  hintStyle: const TextStyle(color: Colors.grey),
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  filled: true,
                  fillColor: Colors.grey[900],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          ),
        ),
        Divider(color: Colors.grey[800]),

        // Chats list
        Expanded(
          child: ListView.builder(
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final chat = chats[index];
              return InkWell(
                onTap: () => onChatSelected(chat['name']!),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(
                    children: [
                      CircleAvatar(radius: 24, backgroundImage: NetworkImage(chat["avatar"]!)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(chat["name"]!,
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text(chat["lastMessage"]!,
                                style: const TextStyle(color: Colors.grey), overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(chat["time"]!, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
