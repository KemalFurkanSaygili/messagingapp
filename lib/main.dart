// Real-time Messaging Application with Firebase
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart'; // <-- YENİ EKLENDİ
import 'package:intl/intl.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // ⭐ GÜVENLİK İÇİN ANONİM OTURUM AÇMA İŞLEMİ EKLENDİ
  try {
    // Realtime Database'e erişmek için oturum açmış bir kullanıcı gereklidir.
    // Anonim oturum açma, her cihaza benzersiz bir kimlik sağlar.
    await FirebaseAuth.instance.signInAnonymously();
    print("Anonim kullanıcı oturumu başarıyla açıldı.");
  } catch (e) {
    // Oturum açma hatası olursa uygulamayı başlatma
    print("Firebase Auth Hatası: $e");
    // Hata durumunda kullanıcıya bilgi gösterilebilir,
    // ancak şimdilik uygulamayı başlatıyoruz.
  }
  // ⭐ YENİ EKLENEN KISIM BİTTİ

  runApp(MessagingApp());
}

class MessagingApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Real-time Messaging',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: UserSelectionPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// ... UserSelectionPage ve MessagingPage sınıflarının kalanı aynı ...

class UserSelectionPage extends StatefulWidget {
  @override
  _UserSelectionPageState createState() => _UserSelectionPageState();
}

class _UserSelectionPageState extends State<UserSelectionPage> {
  final TextEditingController _usernameController = TextEditingController();

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  void _enterChat() {
    if (_usernameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a username')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MessagingPage(
          username: _usernameController.text.trim(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Real-time Messaging'),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.chat_bubble_outline,
                size: 100,
                color: Colors.blue,
              ),
              SizedBox(height: 40),
              Text(
                'Enter Your Username',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20),
              TextField(
                controller: _usernameController,
                decoration: InputDecoration(
                  labelText: 'Username',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                onSubmitted: (_) => _enterChat(),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _enterChat,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                ),
                child: Text('Enter Chat', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MessagingPage extends StatefulWidget {
  final String username;

  MessagingPage({required this.username});

  @override
  _MessagingPageState createState() => _MessagingPageState();
}

class _MessagingPageState extends State<MessagingPage> {
  final TextEditingController _messageController = TextEditingController();
  final DatabaseReference _messagesRef =
  FirebaseDatabase.instance.ref().child('messages');
  final List<Message> _messages = [];

  @override
  void initState() {
    super.initState();
    _listenToMessages();
  }

  void _listenToMessages() {
    _messagesRef.onChildAdded.listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>;
      setState(() {
        _messages.insert(
          0,
          Message(
            username: data['username'] ?? 'Unknown',
            text: data['text'] ?? '',
            timestamp: data['timestamp'] ?? 0,
          ),
        );
      });
    });
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    final messageData = {
      'username': widget.username,
      'text': _messageController.text.trim(),
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };

    _messagesRef.push().set(messageData).then((_) {
      _messageController.clear();
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending message: $error')),
      );
    });
  }

  String _formatTime(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return DateFormat('HH:mm').format(date);
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat Room'),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: Text(
                widget.username,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? Center(
              child: Text(
                'No messages yet. Start the conversation!',
                style: TextStyle(color: Colors.grey),
              ),
            )
                : ListView.builder(
              itemCount: _messages.length,
              reverse: true,
              padding: EdgeInsets.all(12),
              itemBuilder: (context, index) {
                final message = _messages[index];
                final isCurrentUser =
                    message.username == widget.username;

                return Align(
                  alignment: isCurrentUser
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin: EdgeInsets.symmetric(vertical: 4),
                    padding: EdgeInsets.all(12),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.7,
                    ),
                    decoration: BoxDecoration(
                      color: isCurrentUser
                          ? Colors.blue[100]
                          : Colors.grey[300],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          message.username,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          message.text,
                          style: TextStyle(fontSize: 16),
                        ),
                        SizedBox(height: 4),
                        Text(
                          _formatTime(message.timestamp),
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                      maxLines: null,
                    ),
                  ),
                  SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: Colors.blue,
                    child: IconButton(
                      icon: Icon(Icons.send, color: Colors.white),
                      onPressed: _sendMessage,
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

class Message {
  final String username;
  final String text;
  final int timestamp;

  Message({
    required this.username,
    required this.text,
    required this.timestamp,
  });
}