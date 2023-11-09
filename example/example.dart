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

  //Získání listů lekcí
  RezervacePage rezervace = await bikramYoga.ziskatLekce();
  print('Pankrac');
  for (int i = 0; i < rezervace.rezervace['Pankrac']!.length; i++) {
    Lekce rezervaceItem = rezervace.rezervace['Pankrac']![i];
    print('${rezervaceItem.cas}: ${rezervaceItem.lekce}, ${rezervaceItem.lektor}, ${rezervaceItem.rezervovano}, ${rezervaceItem.idLekce}');
    if (i == rezervace.rezervace['Pankrac']!.length - 1) {
      await bikramYoga.rezervovat(rezervaceItem.idLekce);
    }
  }
  print('Vodickova');
  for (int i = 0; i < rezervace.rezervace['Vodickova']!.length; i++) {
    Lekce rezervaceItem = rezervace.rezervace['Vodickova']![i];
    print('${rezervaceItem.cas}: ${rezervaceItem.lekce}, ${rezervaceItem.lektor}, ${rezervaceItem.rezervovano}, ${rezervaceItem.idLekce}');
  }
  print('Online');
  for (int i = 0; i < rezervace.rezervace['OnlineClass']!.length; i++) {
    Lekce rezervaceItem = rezervace.rezervace['OnlineClass']![i];
    print('${rezervaceItem.cas}: ${rezervaceItem.lekce}, ${rezervaceItem.lektor}, ${rezervaceItem.rezervovano}, ${rezervaceItem.idLekce}');
  }

  // Získání informací o přihlášeném uživateli
  Uzivatel uzivatel = await bikramYoga.ziskatUdajeKlienta();
  print("Jméno: ${uzivatel.jmeno}");
  print("Datum narození: ${uzivatel.datumNarozeni}");
  print("Adresa: ${uzivatel.adresa}");
  print("Země: ${uzivatel.zeme}");
  print("Telefonní číslo: ${uzivatel.telCislo}");
  print("Produkt: ${uzivatel.produkt}");
  print("Expirace: ${uzivatel.produktExpirace}");
  print("Prodloužit?: ${uzivatel.produktProdlouzit}");

  // Získání novinek
  NovinkyPage novinky = await bikramYoga.ziskatNovinky();
  for (int i = 0; i < novinky.novinky.length; i++) {
    Novinka novinkyItem = novinky.novinky[i];
    print("${novinkyItem.nadpis}; ${novinkyItem.popis}; ${novinkyItem.datumVydani}; ${novinkyItem.url}");
  }
}
