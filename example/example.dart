import 'package:bikram_yoga_lib/bikram_yoga_lib.dart';
import 'package:dotenv/dotenv.dart';

String email = '';
String password = '';

Future<void> main() async {
  var envSecrets = DotEnv(includePlatformEnvironment: true)..load();

  email = envSecrets['EMAIL'] ?? 'email@email.cz';
  password = envSecrets['PASSWORD'] ?? 'password';

  BikramYoga bikramYoga = BikramYoga();
  //bikramYoga.signup('jmeno', 'prijmeni', email);
  await bikramYoga.login(email, password);
  RezervacePage rezervace = await bikramYoga.ziskatRezervace();
  print('Pankrac');
  for (int i = 0; i < rezervace.rezervace['Pankrac']!.length; i++) {
    Rezervace rezervaceItem = rezervace.rezervace['Pankrac']![i];
    print('${rezervaceItem.cas}: ${rezervaceItem.lekce}, ${rezervaceItem.lektor}, ${rezervaceItem.rezervovano}, ${rezervaceItem.idRezervace}');
    if (i == rezervace.rezervace['Pankrac']!.length - 1) {
      await bikramYoga.rezervovat(rezervaceItem.idRezervace);
    }
  }
  print('Vodickova');
  for (int i = 0; i < rezervace.rezervace['Vodickova']!.length; i++) {
    Rezervace rezervaceItem = rezervace.rezervace['Vodickova']![i];
    print('${rezervaceItem.cas}: ${rezervaceItem.lekce}, ${rezervaceItem.lektor}, ${rezervaceItem.rezervovano}, ${rezervaceItem.idRezervace}');
  }
  print('Online');
  for (int i = 0; i < rezervace.rezervace['OnlineClass']!.length; i++) {
    Rezervace rezervaceItem = rezervace.rezervace['OnlineClass']![i];
    print('${rezervaceItem.cas}: ${rezervaceItem.lekce}, ${rezervaceItem.lektor}, ${rezervaceItem.rezervovano}, ${rezervaceItem.idRezervace}');
  }
}
