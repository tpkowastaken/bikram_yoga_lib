import 'package:bikram_yoga_lib/bikram_yoga_lib.dart';
import 'package:test/test.dart';
import 'package:dotenv/dotenv.dart';

void main() {
  var envSecrets = DotEnv(includePlatformEnvironment: true)..load();
  group('Přihlášení a rezervace', () {
    BikramYoga bikramYoga = BikramYoga();
    test('přihlášení', () async {
      expect(await bikramYoga.login(envSecrets['EMAIL']!, envSecrets['PASSWORD']!), true);
    });

    test('rezervace', () async {
      expect(await bikramYoga.rezervovat(30619), true);
    });
  });
}
