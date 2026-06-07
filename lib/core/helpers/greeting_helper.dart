/// Helper to generate greetings based on the hour of the day
class GreetingHelper {
  GreetingHelper._();

  static String getGreeting({int? hour}) {
    final activeHour = hour ?? DateTime.now().hour;
    if (activeHour >= 6 && activeHour < 12) {
      return "Good Morning 🌅";
    } else if (activeHour >= 12 && activeHour < 17) {
      return "Good Afternoon ☀️";
    } else if (activeHour >= 17 && activeHour < 21) {
      return "Good Evening 🌙";
    } else {
      return "Good Night ✨";
    }
  }
}
