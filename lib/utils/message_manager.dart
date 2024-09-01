class MessageManager {
  static const int maxMessages = 5;

  static List<Map<String, String>> manageMessages(
      List<Map<String, String>> messages) {
    final systemMessage = messages.firstWhere(
      (message) => message['role'] == 'system',
      orElse: () => {'role': 'none', 'content': ''},
    );

    final nonSystemMessages =
        messages.where((message) => message['role'] != 'system').toList();

    if (nonSystemMessages.length > maxMessages) {
      nonSystemMessages.removeRange(0, nonSystemMessages.length - maxMessages);
    }

    if (systemMessage['role'] == 'system') {
      nonSystemMessages.insert(0, systemMessage);
    }

    return nonSystemMessages;
  }
}
