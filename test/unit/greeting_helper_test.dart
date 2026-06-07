import 'package:flutter_test/flutter_test.dart';
import 'package:my_music_app/core/helpers/greeting_helper.dart';

void main() {
  test('6am to 11:59am shows Good Morning', () {
    expect(GreetingHelper.getGreeting(hour: 6), contains('Good Morning'));
    expect(GreetingHelper.getGreeting(hour: 11), contains('Good Morning'));
  });

  test('12pm to 4:59pm shows Good Afternoon', () {
    expect(GreetingHelper.getGreeting(hour: 12), contains('Good Afternoon'));
    expect(GreetingHelper.getGreeting(hour: 16), contains('Good Afternoon'));
  });

  test('5pm to 8:59pm shows Good Evening', () {
    expect(GreetingHelper.getGreeting(hour: 17), contains('Good Evening'));
    expect(GreetingHelper.getGreeting(hour: 20), contains('Good Evening'));
  });

  test('9pm to 5:59am shows Good Night', () {
    expect(GreetingHelper.getGreeting(hour: 21), contains('Good Night'));
    expect(GreetingHelper.getGreeting(hour: 0), contains('Good Night'));
    expect(GreetingHelper.getGreeting(hour: 3), contains('Good Night'));
  });

  test('boundary at exactly 12pm is Good Afternoon', () {
    expect(GreetingHelper.getGreeting(hour: 12), contains('Good Afternoon'));
  });

  test('boundary at exactly 5pm is Good Evening', () {
    expect(GreetingHelper.getGreeting(hour: 17), contains('Good Evening'));
  });

  test('boundary at exactly 9pm is Good Night', () {
    expect(GreetingHelper.getGreeting(hour: 21), contains('Good Night'));
  });
}
