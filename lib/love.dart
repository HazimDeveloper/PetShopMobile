import 'package:flutter/material.dart';
import 'dart:math';

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}

class LovePage extends StatefulWidget {
  const LovePage({super.key});

  @override
  State<LovePage> createState() => _LovePageState();
}

class _LovePageState extends State<LovePage> with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isTyping = false;
  late AnimationController _typingAnimationController;
  late Animation<double> _typingAnimation;

  // Color theme
  final Color lightPastelBrown = Colors.brown[100]!;
  final Color pastelBrown = Colors.brown[300]!;
  final Color darkPastelBrown = Colors.brown[700]!;
  final Color shadowPastelBrown = Colors.brown[300]!.withOpacity(0.3);

  // AI Response patterns
  final Map<String, List<String>> _responses = {
    'greeting': [
      "Hello there! 🐾 I'm LoveBot, your friendly pet companion! How can I help you and your furry friend today?",
      "Woof woof! 🐕 Welcome! I'm here to chat about all things pets. What's on your mind?",
      "Meow! 🐱 Hi there! I'm LoveBot, ready to talk about your adorable pets. How are they doing?",
      "Pawsome to meet you! 🐾 I'm your pet-loving AI friend. Tell me about your furry companions!"
    ],
    'health': [
      "That's a great question about pet health! 🏥 Remember, regular vet checkups are super important for keeping your pet happy and healthy.",
      "Pet health is so important! 💊 Make sure your furry friend gets plenty of exercise, good nutrition, and lots of love.",
      "Health concerns? 🩺 While I can chat about general pet care, always consult your veterinarian for specific health issues.",
      "Keeping pets healthy is all about routine! 🏃‍♂️ Regular exercise, proper diet, and preventive care work wonders."
    ],
    'feeding': [
      "Feeding time is the best time! 🍽️ Make sure to provide age-appropriate food and fresh water daily.",
      "Nutrition is key! 🥗 High-quality pet food, proper portions, and consistent meal times keep pets thriving.",
      "Yummy! 😋 Remember, treats should only be 10% of your pet's daily calories. The rest should be nutritious pet food!",
      "Food is love! 💕 But remember, some human foods can be dangerous for pets. Stick to pet-safe treats!"
    ],
    'training': [
      "Training is bonding time! 🎓 Positive reinforcement with treats and praise works wonders for teaching new tricks.",
      "Pawsome training tip! 🌟 Consistency is key - practice a little bit every day for best results.",
      "Training builds trust! 🤝 Remember to be patient and make it fun for both you and your pet.",
      "Good behavior deserves rewards! 🏆 Use treats, praise, and play to encourage the behaviors you want to see."
    ],
    'play': [
      "Playtime is the best time! 🎾 Interactive toys and games keep pets mentally stimulated and physically active.",
      "Let's play! 🎮 Different pets enjoy different activities - find what makes your furry friend's tail wag!",
      "Fun fact: Play isn't just fun, it's essential! 🎪 It helps with physical fitness and mental health.",
      "Toys, games, and quality time together strengthen your bond! 🎭 What's your pet's favorite game?"
    ],
    'love': [
      "Aww, that's so sweet! 💕 The love between pets and their humans is truly special and unconditional.",
      "Love is what makes the pet-human bond so magical! 💖 Your pet is lucky to have someone who cares so much.",
      "That melts my digital heart! 🥰 Pets have this amazing ability to fill our lives with joy and love.",
      "Pure love! 💝 The way pets show affection - from purrs to tail wags - reminds us what unconditional love looks like."
    ],
    'funny': [
      "Haha! 😂 Pets are natural comedians, aren't they? They always know how to make us smile!",
      "That's hilarious! 🤣 Pets do the silliest things - it's like they're trying to entertain us on purpose!",
      "LOL! 😆 I love pet humor! They're so goofy and adorable, it's impossible not to laugh.",
      "Too funny! 🎭 Pets are the best entertainment - better than any TV show!"
    ],
    'default': [
      "That's interesting! 🤔 Tell me more about your pet - I love hearing pet stories!",
      "Fascinating! 🌟 Every pet is unique and special in their own way. What makes yours special?",
      "I'd love to learn more! 📚 Pets are endlessly interesting creatures with such unique personalities.",
      "How wonderful! 🎉 I'm always excited to chat about pets and their amazing quirks!",
      "That sounds pawsome! 🐾 I'm here to listen and chat about anything pet-related!",
      "Interesting perspective! 💭 What's the most surprising thing you've learned about your pet?",
      "I love chatting about pets! 💬 They bring so much joy to our lives, don't they?"
    ],
    'goodbye': [
      "Goodbye for now! 👋 Take care of your furry friends, and remember - they love you unconditionally!",
      "See you later! 🐾 Give your pets some extra cuddles from me!",
      "Bye bye! 💕 Thanks for the lovely chat about your amazing pets!",
      "Until next time! 🌟 Keep being an awesome pet parent!"
    ]
  };

  final List<String> _funFacts = [
    "🐕 Dogs can learn over 150 words and can count up to four or five!",
    "🐱 Cats spend 70% of their lives sleeping - that's 13-16 hours a day!",
    "🐾 A dog's sense of smell is 10,000 to 100,000 times stronger than humans!",
    "😸 Cats have a third eyelid called a nictitating membrane!",
    "🐕 Dogs dream just like humans - you might see them moving their legs while sleeping!",
    "🐱 A group of cats is called a 'clowder' and a group of kittens is called a 'kindle'!",
    "🐾 Pets can help reduce stress and lower blood pressure in their owners!",
    "🐕 Dogs have unique nose prints, just like human fingerprints!",
    "🐱 Cats can rotate their ears 180 degrees!",
    "💕 Pets can sense human emotions and often comfort us when we're sad!"
  ];

  @override
  void initState() {
    super.initState();
    
    _typingAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _typingAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _typingAnimationController,
      curve: Curves.easeInOut,
    ));

    // Add welcome message
    _addMessage("Hello! 🐾 I'm LoveBot, your friendly pet companion AI! I'm here to answer all your pet questions and chat about your furry, feathered, or scaly friends.\n\nAsk me anything about:\n• Pet training and behavior\n• Health and nutrition\n• Exercise and play\n• Grooming and care\n• Fun facts and more!\n\nWhat would you like to know? 🤔", false);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _typingAnimationController.dispose();
    super.dispose();
  }

  void _addMessage(String text, bool isUser) {
    setState(() {
      _messages.add(ChatMessage(
        text: text,
        isUser: isUser,
        timestamp: DateTime.now(),
      ));
    });
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

  String _generateResponse(String userMessage) {
    final message = userMessage.toLowerCase();
    
    // Check if it's a question (contains question words or ends with ?)
    bool isQuestion = message.contains('?') || 
                     message.contains('how') || 
                     message.contains('what') || 
                     message.contains('when') || 
                     message.contains('where') || 
                     message.contains('why') || 
                     message.contains('which') || 
                     message.contains('who') || 
                     message.contains('can') || 
                     message.contains('should') || 
                     message.contains('do you') ||
                     message.contains('help');

    // Handle specific questions first
    if (isQuestion) {
      return _handleQuestion(message);
    }
    
    // Then handle general conversation
    if (message.contains('hello') || message.contains('hi') || message.contains('hey')) {
      return _getRandomResponse('greeting');
    } else if (message.contains('health') || message.contains('sick') || message.contains('vet') || message.contains('medicine')) {
      return _getRandomResponse('health');
    } else if (message.contains('food') || message.contains('eat') || message.contains('feed') || message.contains('hungry')) {
      return _getRandomResponse('feeding');
    } else if (message.contains('train') || message.contains('trick') || message.contains('command') || message.contains('behavior')) {
      return _getRandomResponse('training');
    } else if (message.contains('play') || message.contains('toy') || message.contains('game') || message.contains('fun')) {
      return _getRandomResponse('play');
    } else if (message.contains('love') || message.contains('cute') || message.contains('adorable') || message.contains('sweet')) {
      return _getRandomResponse('love');
    } else if (message.contains('funny') || message.contains('silly') || message.contains('laugh') || message.contains('haha')) {
      return _getRandomResponse('funny');
    } else if (message.contains('bye') || message.contains('goodbye') || message.contains('see you')) {
      return _getRandomResponse('goodbye');
    } else if (message.contains('fact') || message.contains('tell me') || message.contains('learn')) {
      return "Here's a fun pet fact: ${_funFacts[Random().nextInt(_funFacts.length)]}";
    } else {
      return _getRandomResponse('default');
    }
  }

  String _handleQuestion(String question) {
    // Specific question handling with detailed answers
    
    // Training questions
    if (question.contains('how') && (question.contains('train') || question.contains('teach'))) {
      if (question.contains('dog')) {
        return "🐕 Training your dog:\n\n1. Start with basic commands: sit, stay, come\n2. Use positive reinforcement with treats and praise\n3. Keep training sessions short (5-10 minutes)\n4. Be consistent with commands and rewards\n5. Practice daily for best results\n\nRemember: patience is key! Every dog learns at their own pace. 🎓";
      } else if (question.contains('cat')) {
        return "🐱 Training your cat:\n\n1. Use treats and positive reinforcement\n2. Start with simple commands like 'sit' or 'come'\n3. Keep sessions very short (2-5 minutes)\n4. Train before meal times when they're hungry\n5. Use clicker training for better results\n\nCats are independent but can definitely learn! 🎯";
      } else {
        return "🎓 Pet training basics:\n\n• Use positive reinforcement (treats, praise)\n• Be consistent with commands\n• Keep sessions short and fun\n• Train regularly but don't overdo it\n• End on a positive note\n\nWhat specific pet are you training? I can give more targeted advice! 🐾";
      }
    }
    
    // Health questions
    if (question.contains('health') || question.contains('sick') || question.contains('vet')) {
      if (question.contains('when') || question.contains('how often')) {
        return "🏥 Vet visit schedule:\n\n• Puppies/Kittens: Every 3-4 weeks until 16 weeks\n• Adult pets: Annual checkups\n• Senior pets (7+ years): Every 6 months\n• Emergency: Any sudden changes in behavior, eating, or bathroom habits\n\nRegular checkups help catch problems early! 🩺";
      } else if (question.contains('what') && question.contains('signs')) {
        return "⚠️ Warning signs to watch for:\n\n• Loss of appetite for 24+ hours\n• Lethargy or unusual behavior\n• Vomiting or diarrhea\n• Difficulty breathing\n• Excessive drinking or urination\n• Limping or difficulty moving\n\nWhen in doubt, call your vet! 📞";
      } else {
        return "🏥 Pet health tips:\n\n• Regular vet checkups are essential\n• Keep vaccinations up to date\n• Watch for changes in appetite or behavior\n• Maintain good dental hygiene\n• Provide regular exercise\n\nAlways consult your vet for specific health concerns! 💊";
      }
    }
    
    // Feeding questions
    if (question.contains('feed') || question.contains('food') || question.contains('eat')) {
      if (question.contains('how much') || question.contains('how often')) {
        return "🍽️ Feeding guidelines:\n\n• Puppies (8-12 weeks): 3-4 times daily\n• Adult dogs: 2 times daily\n• Kittens: 3-4 times daily\n• Adult cats: 2 times daily\n\nAmount depends on size, age, and activity level. Check your pet food packaging for specific guidelines! 📏";
      } else if (question.contains('what') && (question.contains('food') || question.contains('best'))) {
        return "🥗 Choosing the right food:\n\n• Look for AAFCO certification\n• Age-appropriate formulas (puppy, adult, senior)\n• High-quality protein as first ingredient\n• Avoid excessive fillers\n• Consider your pet's specific needs\n\nConsult your vet for personalized recommendations! 🌟";
      } else if (question.contains('treat')) {
        return "🍪 Healthy treat guidelines:\n\n• Treats should be <10% of daily calories\n• Use small pieces for training\n• Avoid chocolate, grapes, onions for dogs\n• Fresh fruits/veggies can be great (check safety first)\n• Use treats for training and bonding\n\nModeration is key! 🎯";
      } else {
        return "🍽️ Feeding your pet:\n\n• Consistent meal times help digestion\n• Fresh water should always be available\n• Age-appropriate, high-quality food\n• Monitor weight and adjust portions\n• Treats in moderation\n\nWhat specific feeding question do you have? 🤔";
      }
    }
    
    // Behavior questions
    if (question.contains('behavior') || question.contains('problem') || question.contains('stop')) {
      return "🐾 Common behavior solutions:\n\n• Excessive barking: Training, exercise, mental stimulation\n• Scratching furniture: Provide scratching posts\n• Chewing: Appropriate chew toys, exercise\n• Anxiety: Gradual exposure, comfort items\n• Aggression: Professional trainer consultation\n\nConsistent training and patience work wonders! What specific behavior are you dealing with? 🎭";
    }
    
    // Age/lifespan questions
    if (question.contains('age') || question.contains('old') || question.contains('live')) {
      return "📅 Pet lifespans:\n\n• Small dogs: 12-16 years\n• Medium dogs: 10-14 years\n• Large dogs: 8-12 years\n• Cats: 12-18 years (indoor cats live longer)\n• Rabbits: 8-12 years\n• Birds: Varies widely (5-100+ years)\n\nProper care can help pets live longer, healthier lives! 🌟";
    }
    
    // Exercise questions
    if (question.contains('exercise') || question.contains('walk') || question.contains('activity')) {
      return "🏃‍♂️ Exercise needs:\n\n• High-energy dogs: 1-2 hours daily\n• Medium-energy dogs: 30-60 minutes daily\n• Low-energy dogs: 20-30 minutes daily\n• Cats: 10-15 minutes of active play\n• Mental stimulation is as important as physical!\n\nAdjust based on age, health, and breed! 🎾";
    }
    
    // Grooming questions
    if (question.contains('groom') || question.contains('brush') || question.contains('bath')) {
      return "✨ Grooming basics:\n\n• Brushing: Daily for long hair, weekly for short\n• Baths: Monthly or when dirty (cats rarely need baths)\n• Nail trimming: Every 2-4 weeks\n• Teeth brushing: Daily if possible\n• Ear cleaning: Weekly check, clean if needed\n\nRegular grooming keeps pets healthy and comfortable! 🛁";
    }
    
    
    // General questions
    if (question.contains('what') && question.contains('best')) {
      return "🌟 Best pet care practices:\n\n• Regular vet checkups\n• Quality nutrition\n• Daily exercise and mental stimulation\n• Consistent training with positive reinforcement\n• Lots of love and attention\n• Safe, comfortable environment\n\nEvery pet is unique - what works best depends on your specific furry friend! 🐾";
    }
    
    // Adoption/choosing pet questions
    if (question.contains('adopt') || question.contains('choose') || question.contains('get') && question.contains('pet')) {
      return "🏠 Choosing the right pet:\n\n• Consider your lifestyle and living space\n• Think about time commitment (exercise, grooming, training)\n• Research breed characteristics\n• Budget for ongoing costs\n• Visit shelters - many amazing pets need homes!\n• Consider adopting adult pets (they're often calmer)\n\nWhat type of living situation do you have? That can help narrow down options! 🐾";
    }
    
    // Safety questions
    if (question.contains('safe') || question.contains('danger') || question.contains('poison')) {
      return "⚠️ Pet safety essentials:\n\n🚫 Toxic foods: Chocolate, grapes, onions, garlic, xylitol\n🚫 Dangerous plants: Lilies (cats), azaleas, oleander\n🚫 Household items: Cleaning products, medications\n\n✅ Pet-proof your home:\n• Secure cabinets and trash cans\n• Remove small objects they could swallow\n• Check for escape routes\n\nEmergency vet number should be easily accessible! 📞";
    }
    
    // Travel questions
    if (question.contains('travel') || question.contains('vacation') || question.contains('trip')) {
      return "✈️ Traveling with pets:\n\n• Research pet-friendly accommodations\n• Update ID tags and microchip info\n• Pack familiar items (toys, blankets)\n• Bring health certificates for long trips\n• Never leave pets in hot cars\n• Consider pet sitters for longer trips\n\nFor air travel, check airline pet policies well in advance! 🧳";
    }
    
    // Socialization questions
    if (question.contains('social') || question.contains('other pets') || question.contains('introduce')) {
      return "👥 Pet socialization tips:\n\n• Start socialization early (but safely)\n• Introduce new pets gradually and supervised\n• Use neutral territory for first meetings\n• Watch body language carefully\n• Reward calm, friendly behavior\n• Don't force interactions\n\nProper socialization helps pets be confident and well-adjusted! 🤝";
    }
    
    // Emergency questions
    if (question.contains('emergency') || question.contains('urgent') || question.contains('help')) {
      return "🚨 Pet Emergency Guidelines:\n\n⚡ IMMEDIATE vet attention needed for:\n• Difficulty breathing\n• Severe bleeding\n• Unconsciousness\n• Suspected poisoning\n• Severe trauma\n• Bloated/distended abdomen\n\n📞 Keep emergency vet numbers handy\n🚗 Know the route to nearest emergency clinic\n\nIf in doubt, call your vet immediately! 🏥";
    }
    
    // Default question response
    return "🤔 That's a great question! I'd love to help you more specifically. Could you tell me:\n\n• What type of pet do you have?\n• What specific aspect are you curious about?\n• Any particular challenges you're facing?\n\nThe more details you share, the better advice I can give! Feel free to ask about training, health, feeding, behavior, or anything else pet-related. 💭";
  }

  String _getRandomResponse(String category) {
    final responses = _responses[category] ?? _responses['default']!;
    return responses[Random().nextInt(responses.length)];
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    // Add user message
    _addMessage(text, true);
    _messageController.clear();

    // Show typing indicator
    setState(() {
      _isTyping = true;
    });
    _typingAnimationController.repeat();

    // Simulate AI thinking time
    Future.delayed(Duration(milliseconds: 800 + Random().nextInt(1200)), () {
      if (!mounted) return;
      
      setState(() {
        _isTyping = false;
      });
      _typingAnimationController.stop();

      // Generate and add AI response
      final response = _generateResponse(text);
      _addMessage(response, false);
    });
  }

  Widget _buildMessage(ChatMessage message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 16.0),
      child: Row(
        mainAxisAlignment: message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: pastelBrown,
              child: const Icon(Icons.pets, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: message.isUser ? pastelBrown : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: shadowPastelBrown,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.text,
                    style: TextStyle(
                      color: message.isUser ? Colors.white : darkPastelBrown,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "${message.timestamp.hour.toString().padLeft(2, '0')}:${message.timestamp.minute.toString().padLeft(2, '0')}",
                    style: TextStyle(
                      color: message.isUser ? Colors.white70 : Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (message.isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: darkPastelBrown,
              child: const Icon(Icons.person, color: Colors.white, size: 16),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 16.0),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: pastelBrown,
            child: const Icon(Icons.pets, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: shadowPastelBrown,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: AnimatedBuilder(
              animation: _typingAnimation,
              builder: (context, child) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildDot(0),
                    const SizedBox(width: 4),
                    _buildDot(1),
                    const SizedBox(width: 4),
                    _buildDot(2),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(int index) {
    final delay = index * 0.2;
    final animationValue = (_typingAnimation.value - delay).clamp(0.0, 1.0);
    final opacity = (sin(animationValue * pi) * 0.5 + 0.5).clamp(0.0, 1.0);
    
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: pastelBrown.withOpacity(opacity),
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildQuickReplies() {
    final quickReplies = [
      "How do I train my dog? 🐕",
      "What should I feed my pet? 🍽️",
      "When should I visit the vet? 🏥",
      "How much exercise does my pet need? 🏃‍♂️",
      "Tell me a fun fact! 🎉",
      "How do I stop bad behavior? 🐾",
    ];

    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: quickReplies.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ActionChip(
              label: Text(
                quickReplies[index],
                style: TextStyle(color: darkPastelBrown, fontSize: 12),
              ),
              backgroundColor: Colors.white,
              side: BorderSide(color: pastelBrown),
              onPressed: () {
                _messageController.text = quickReplies[index];
                _sendMessage();
              },
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightPastelBrown,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: darkPastelBrown),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: pastelBrown,
              child: const Icon(Icons.pets, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'LoveBot',
                  style: TextStyle(
                    color: darkPastelBrown,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Your Pet AI Companion',
                  style: TextStyle(
                    color: pastelBrown,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.info_outline, color: pastelBrown),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('About LoveBot', style: TextStyle(color: darkPastelBrown)),
                  content: Text(
                    'LoveBot is your friendly AI companion designed to chat about pets! Ask me about pet care, training, health tips, or just share cute stories about your furry friends! 🐾',
                    style: TextStyle(color: darkPastelBrown),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Got it!', style: TextStyle(color: pastelBrown)),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Quick replies
          if (_messages.length <= 1) _buildQuickReplies(),
          
          // Chat messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length && _isTyping) {
                  return _buildTypingIndicator();
                }
                return _buildMessage(_messages[index]);
              },
            ),
          ),
          
          // Message input
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: shadowPastelBrown,
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: "Chat with LoveBot about your pets...",
                      hintStyle: TextStyle(color: Colors.grey[600]),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide(color: pastelBrown),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide(color: pastelBrown),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide(color: darkPastelBrown, width: 2),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                    maxLines: null,
                    textCapitalization: TextCapitalization.sentences,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                FloatingActionButton(
                  onPressed: _isTyping ? null : _sendMessage,
                  backgroundColor: _isTyping ? Colors.grey : pastelBrown,
                  mini: true,
                  child: Icon(
                    Icons.send,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}