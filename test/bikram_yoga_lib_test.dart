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
      await Future.delayed(Duration(milliseconds: 200));
      await bikramYoga.login(envSecrets['EMAIL']!, envSecrets['PASSWORD']!);
      RezervacePage rezervacePage = await bikramYoga.ziskatRezervace();
      await bikramYoga.rezervovat(rezervacePage.rezervace['Pankrac']![rezervacePage.rezervace.length - 1].idRezervace);
      await Future.delayed(Duration(milliseconds: 200));
      rezervacePage = await bikramYoga.ziskatRezervace();
      bool rezervaceUspesna = rezervacePage.rezervace['Pankrac']![rezervacePage.rezervace.length - 1].rezervovano;
      await Future.delayed(Duration(milliseconds: 500));
      await bikramYoga.rezervovat(rezervacePage.rezervace['Pankrac']![rezervacePage.rezervace.length - 1].idRezervace);
      expect(rezervaceUspesna, true);
    });

    test('rezervace nejsou prázdné', () async {
      await Future.delayed(Duration(milliseconds: 200));
      await bikramYoga.login(envSecrets['EMAIL']!, envSecrets['PASSWORD']!);
      RezervacePage rezervacePage = await bikramYoga.ziskatRezervace();
      expect(rezervacePage.rezervace['Pankrac']!.length, greaterThan(0));
    });
  });
}
