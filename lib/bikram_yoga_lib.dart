import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;
import 'package:html/dom.dart' as dom;

/// Enumerátor možných chyb při registraci
enum PossibleFails {
  emailAlreadyExists,
  nameAlreadyExists,
  success,
  networkError,
}

/// Classa reprezentující jednoho uživatele
class Uzivatel {
  /// Jméno uživatele
  String jmeno;

  /// Datum narození uživatele
  DateTime? datumNarozeni;

  /// Adresa uživatele
  String adresa;

  /// Země, odkud uživatel pochází
  String zeme;

  /// Telefonní číslo uživatele
  int? telCislo;

  /// Aktivní produkt uživatele
  String produkt;

  /// Datum, kdy uživateli expiruje zakoupený produkt
  DateTime? produktExpirace;

  /// True pokud má uživatel nabídku si platnost produktu prodloužit, jinak false
  bool produktProdlouzit;
  Uzivatel({
    required this.jmeno,
    required this.datumNarozeni,
    required this.adresa,
    required this.zeme,
    required this.telCislo,
    required this.produkt,
    required this.produktExpirace,
    required this.produktProdlouzit,
  });
}

/// Classa reprezentující jednu lekci
class Lekce {
  /// Datum a čas lekce
  DateTime cas;

  /// Název lekce
  String lekce;

  /// Jméno lektora
  String lektor;

  /// ID lekce
  int idLekce;

  /// True pokud je lekce rezervována, jinak false
  bool rezervovano;
  Lekce({
    required this.cas,
    required this.lekce,
    required this.lektor,
    required this.idLekce,
    required this.rezervovano,
  });
}

/// Classa poskytující všechny informace na stránce ohledně rezervací
class RezervacePage {
  // Lekce se zde
  Map<String, List<Lekce>> rezervace = {};
  RezervacePage({required this.rezervace});
}

/// Classa reprezentující jednu novinku
class Novinka {
  /// Nadpis novinky
  String nadpis;

  /// Popis novinky
  String? popis;

  /// Odkaz na novinku
  Uri url;

  /// Datum vydání novinky
  DateTime? datumVydani;

  Novinka({
    required this.nadpis,
    this.popis,
    required this.url,
    this.datumVydani,
  });
}

/// Classa poskytující všechny aktuální novinky na stránce
class NovinkyPage {
  List<Novinka> novinky = [];
  NovinkyPage({required this.novinky});
}

/// Classa pro komunikaci s bikramyoga.cz
class BikramYoga {
  String phpsessid = '';
  String cookieEmail = '';
  Completer<void> completer = Completer<void>();

  BikramYoga() {
    _doInitialRequest();
  }

  /// Provede inicializaci. Získá PHPSESSID, které nás identifikuje na serveru
  Future<void> _doInitialRequest() async {
    try {
      Uri url = Uri.parse("https://www.bikramyoga.cz/");

      var getCookies = await http.get(url);

      String? cookieItem;
      String? cookies = getCookies.headers["set-cookie"];
      int index;

      if (cookies != null) {
        index = cookies.indexOf(';');
        cookieItem = (index == -1) ? cookies : cookies.substring(0, index);
      }
      if (cookieItem != null) {
        index = cookieItem.indexOf('=');
        if (index != -1 && index < cookieItem.length - 1) {
          phpsessid = cookieItem.substring(index + 1);
        }
      }
      completer.complete();
    } catch (e) {
      completer.completeError(e);
    }
  }

  /// Přihlášení na bikramyoga.cz
  ///
  /// [email] = email; [password]= heslo;
  ///
  /// Je potřeba zavolat před provedení rezervace lekce.
  /// Vrátí true pokud se přihlášení povedlo, jinak false
  Future<bool> login(String email, String password) async {
    await completer.future;
    bool success = false;
    Uri url = Uri.parse("https://www.bikramyoga.cz/");

    Map<String, String> headers = {
      "content-type": "application/x-www-form-urlencoded; charset=UTF-8",
      "cookie": "PHPSESSID=$phpsessid",
    };

    Map<String, String> body = {
      "type": "login",
      "username": email,
      "password": password,
      "request_uri": "/",
      "url": "Modules/BikramYoga/Server/Ajax.php",
    };

    var response = await http.post(url, headers: headers, body: body);
    if (response.headers["set-cookie"] != null) {
      List<String> login = response.headers["set-cookie"]!.split(";");
      for (var kvPair in login) {
        var kv = kvPair.split("=");
        var key = kv[1].trim();

        if (key.contains("login")) {
          cookieEmail = kv[2];
          success = true;
        }
      }
    }
    return success;
  }

  /// Registrace na bikramyoga.cz
  ///
  /// [firstName] = křestní jméno;
  /// [lastName] =  příjmení;
  /// [email] =  email;
  ///
  /// Vrátí [PossibleFails.success] pokud se registrace povedla.
  ///
  /// Vrátí [PossibleFails.emailAlreadyExists] pokud se email již používá.
  ///
  /// Vrátí [PossibleFails.nameAlreadyExists] pokud se jméno již používá.
  ///
  /// Vrátí [PossibleFails.networkError] pokud se registrace nepovedla z důvodu sítě.
  Future<PossibleFails> signup(String firstName, String lastName, String email) async {
    await completer.future;
    String company = ''; //optional
    String adresa = ''; //optional
    String postovniSmerovaciCislo = '';
    String mesto = '';
    String statCislo = '1'; //1 pro cz
    String telefon = ''; //optional
    String datumNarozeni = '';
    String pohlaviNulaProMuzeJednaProZenu = '0';
    String jakJsteSeONasDozvedeli = '';

    Map<String, String> headers = {
      HttpHeaders.contentTypeHeader: 'application/x-www-form-urlencoded; charset=UTF-8',
      HttpHeaders.cookieHeader: 'PHPSESSID=$phpsessid; comment=comment; web_lang=cs; ',
    };
    String body =
        'bikram-yoga-register%5Bfirst_name%5D=$firstName&bikram-yoga-register%5Bsurname%5D=$lastName&bikram55-yoga-register%5Bcompany%5D=$company&bikram-yoga-register%5Baddress%5D=$adresa&bikram-yoga-register%5Bzip_code%5D=$postovniSmerovaciCislo&bikram-yoga-register%5Bcity%5D=$mesto&bikram-yoga-register%5Bid_sys_states%5D=$statCislo&bikram-yoga-register%5Bphone%5D=$telefon&bikram-yoga-register%5Bemail%5D=$email&bikram-yoga-register%5Bbirth_date%5D=$datumNarozeni&bikram-yoga-register%5Bgender%5D=$pohlaviNulaProMuzeJednaProZenu&bikram-yoga-register%5Breason%5D=$jakJsteSeONasDozvedeli';
    String url = 'https://www.bikramyoga.cz/registrace/';

    try {
      var request = await HttpClient().postUrl(Uri.parse(url));
      headers.forEach(
        (key, value) {
          request.headers.set(key, value);
        },
      );
      request.write(body);
      var response = await request.close();
      var statusCode = response.statusCode;
      var responseBody = await response.transform(utf8.decoder).join();
      //save responsebody to an html file
      String check = responseBody;
      if (statusCode == 302) {
        return PossibleFails.success;
      } else if (statusCode == 200) {
        if (check.contains(
            'Omlouv&aacute;me se, ale už existuje jeden klient se stejn&yacute;m e-mailem, jako m&aacute;te Vy, proto nen&iacute; možn&eacute; založit V')) {
          return PossibleFails.emailAlreadyExists;
        } else if (check.contains(
            'Omlouv&aacute;me se, ale už existuje jeden klient se stejn&yacute;m jmenem jako vy, proto nen&iacute; možn&eacute; založit V&aacute;&scaron; on-line &uacute;čet')) {
          return PossibleFails.nameAlreadyExists;
        } else {
          return PossibleFails.networkError;
        }
      } else {
        return PossibleFails.networkError;
      }
    } catch (error) {
      return PossibleFails.networkError;
    }
  }

  /// Získá seznam lekcí z bikramyoga.cz
  ///
  /// Je potřeba být přihlášen. [login]
  Future<RezervacePage> ziskatLekce() async {
    await completer.future;
    Map<String, String> cookies = {
      "PHPSESSID": phpsessid,
      "web_lang": "cs",
      "login": Uri.parse(cookieEmail).toString(),
    };

    // Spojí cookies do jedné string
    String cookieString = cookies.entries.map((entry) => '${entry.key}=${entry.value}').join('; ');
    // Vytvoří mapu kde ukládá headers
    Map<String, String> headers = {
      "authority": "www.bikramyoga.cz",
      "cookie": cookieString,
    };
    var response = await http.get(Uri.parse("https://www.bikramyoga.cz/rezervace"), headers: headers);

    RezervacePage rezervacePage = RezervacePage(rezervace: {});
    rezervacePage.rezervace['Pankrac'] = _parseLekce('Pankrac', response.body);
    rezervacePage.rezervace['Vodickova'] = _parseLekce('Vodickova', response.body);
    rezervacePage.rezervace['OnlineClass'] = _parseLekce('OnlineClass', response.body);
    return rezervacePage;
  }

  /// Zpracuje html a vrátí seznam lekcí.
  List<Lekce> _parseLekce(String id, String html) {
    List<Lekce> rezervace = [];
    dom.Document document = parser.parse(html);
    late dom.Element pankrac;
    try {
      pankrac = document.getElementById(id)!;
    } catch (e) {
      throw ('chyba při získání rezervací');
    }
    dom.Document pankracDocument = parser.parse(pankrac.innerHtml);
    dom.Element pankracNode = pankracDocument.firstChild!.children[1].children[0].children[1];

    for (int i = 0; i < pankracNode.children.length; i++) {
      dom.Element child = pankracNode.children[i];
      if (child.children.isEmpty) continue;
      String datum = child.children[0].text;
      String cas = child.children[2].text;
      String lekceLektor = child.children[3].text;
      String idLekce = child.children[4].children[0].attributes['data-id']!;
      bool rezervovano = child.children[4].children[0].text == 'Rezervovat' ? false : true;

      DateTime casDateTime = DateTime(
        int.parse(datum.split('.')[2]),
        int.parse(datum.split('.')[1]),
        int.parse(datum.split('.')[0]),
        int.parse(cas.split(':')[0]),
        int.parse(cas.split(':')[1]),
      );

      // Rozděluje lektora na lekci a lektora
      String lekce;
      String lektor;
      List<String> words = lekceLektor.split(' ');
      String posledniSlovo = words.last;

      if (lekceLektor == "ADVANCE" || lekceLektor == "Detska lekce" || int.tryParse(posledniSlovo) != null) {
        // Pro "ADVANCE" nebo "Detska Lekce," není jméno lektora
        lekce = lekceLektor;
        lektor = "";
      } else if (words.length == 1 || (words.length == 2 && words[1].contains('.'))) {
        // Pro lekce kde lekceLektor ma 1 nebo 2 slova a 2. obsahuje tečku ("."), myslíme si že to je jméno lektora
        lekce = "Bikram Yoga Class 90";
        lektor = lekceLektor;
      } else if (posledniSlovo.contains('.')) {
        int lastIndex = words.length - 1;
        lekce = words.sublist(0, lastIndex - 1).join(' '); // Spojit všechny slova kromě posledních 2(jméno lektora)
        lektor = '${words[lastIndex - 1]} $posledniSlovo'; // Spojit poslední 2 slova pro jméno lektora
      } else if (posledniSlovo.isEmpty) {
        lekce = "Bikram Yoga Class 90";
        lektor = words.sublist(0, words.length - 1).join(" ");
      } else {
        // Když poslední slovo neobsahuje tečku ("."), myslíme si že to je jméno lektora
        lekce = words.sublist(0, words.length - 1).join(' '); //  Spojit vše kromě posledního slova
        lektor = posledniSlovo; // Poslední slovo je jméno lektora
      }

      //Přidá lekci do listu
      rezervace.add(
        Lekce(
          cas: casDateTime,
          lekce: lekce,
          lektor: lektor,
          idLekce: int.parse(idLekce),
          rezervovano: rezervovano,
        ),
      );
    }
    return rezervace;
  }

  /// Rezervuje/zruší rezervaci u dané lekce.
  ///
  /// Je potřeba získat [idLekce] pomocí [ziskatLekce].
  Future<bool> rezervovat(int idLekce) async {
    await completer.future;
    if (cookieEmail == '') return false;
    Map<String, String> cookies = {
      "PHPSESSID": phpsessid,
      "web_lang": "cs",
      "login": Uri.parse(cookieEmail).toString(),
    };

    // Combine the cookies into a single string
    String cookieString = cookies.entries.map((entry) => '${entry.key}=${entry.value}').join('; ');
    // Create a Map to hold the headers
    Map<String, String> headers = {
      "authority": "www.bikramyoga.cz",
      "Content-Type": "application/x-www-form-urlencoded; charset=UTF-8",
      "referer": "https://www.bikramyoga.cz/rezervace/",
      "cookie": cookieString,
    };

    // Create a Map to hold the cookies

    // Create the request body
    String requestBody = "async=false&type=reserve&id=$idLekce&request_uri=%2Frezervace%2F&url=Modules%2FBikramYoga%2FServer%2FAjax.php";

    // Create the HTTP client
    var client = http.Client();

    // Send the POST request
    try {
      await client.post(
        Uri.parse("https://www.bikramyoga.cz/"),
        headers: headers,
        body: requestBody,
      );
      return true;
    } catch (e) {
      return false;
    } finally {
      client.close();
    }
  }

  /// Získá informace o uživateli z bikramyoga.cz
  ///
  /// Je potřeba být přihlášen. [login]
  Future<Uzivatel> ziskatUdajeKlienta() async {
    await completer.future;
    Map<String, String> cookies = {
      "PHPSESSID": phpsessid,
      "web_lang": "cs",
      "login": Uri.parse(cookieEmail).toString(),
    };

    // Combine the cookies into a single string
    String cookieString = cookies.entries.map((entry) => '${entry.key}=${entry.value}').join('; ');
    // Vytvoří mapu kde ukládá headers
    Map<String, String> headers = {
      "authority": "www.bikramyoga.cz",
      "cookie": cookieString,
    };
    var response = await http.get(Uri.parse("https://www.bikramyoga.cz/informace-o-uzivateli"), headers: headers);

    Uzivatel uzivatel = _parseUzivatel(response.body);
    return uzivatel;
  }

  /// Zpracuje html a vrátí list informací o uživateli.
  Uzivatel _parseUzivatel(String html) {
    dom.Document document = parser.parse(html);
    late dom.Element uzivatelData;
    try {
      uzivatelData = document.getElementById("user-information")!;
    } catch (e) {
      throw ('Chyba při získání uživatelských dat');
    }
    dom.Document uzivatelDataDocument = parser.parse(uzivatelData.innerHtml);
    dom.Element uzivatelDataNode = uzivatelDataDocument.firstChild!.children[1].children[0].children[1];

    String jmeno = uzivatelDataDocument.firstChild!.children[1].children[0].children[0].text;
    String datumNarozeni = uzivatelDataNode.children[0].children[1].text;
    String adresa = uzivatelDataNode.children[1].children[1].text;
    String zeme = uzivatelDataNode.children[2].children[1].text;
    int? telCislo = int.tryParse(uzivatelDataNode.children[3].children[1].text.replaceAll(" ", ""));
    String produkt = uzivatelDataNode.children[4].children[1].text;
    String produktExpirace = uzivatelDataNode.children[5].children[1].text;
    bool produktProdlouzit = false;
    if (uzivatelDataNode.children[5].children.length > 2) {
      produktProdlouzit = true;
    }

    /// Pokud jsme získaly datumNarozeni tak převedeme na DateTime, jinak vracíme null
    DateTime? datumNarozeniDateTime;
    if (int.tryParse(datumNarozeni) != null) {
      datumNarozeniDateTime = DateTime(
        int.parse(datumNarozeni.split('.')[2]),
        int.parse(datumNarozeni.split('.')[1]),
        int.parse(datumNarozeni.split('.')[0]),
      );
    }

    /// Pokud jsme získaly produktExpirace tak převedeme na DateTime, jinak vracíme null
    DateTime? datumExpiraceDateTime;
    if (produktExpirace.trim() != "No product") {
      datumExpiraceDateTime = DateTime(
        int.parse(produktExpirace.split('.')[2]),
        int.parse(produktExpirace.split('.')[1]),
        int.parse(produktExpirace.split('.')[0]),
      );
    }

    return Uzivatel(
      jmeno: jmeno,
      datumNarozeni: datumNarozeniDateTime,
      adresa: adresa,
      zeme: zeme,
      telCislo: telCislo,
      produkt: produkt,
      produktExpirace: datumExpiraceDateTime,
      produktProdlouzit: produktProdlouzit,
    );
  }

  Future<NovinkyPage> ziskatNovinky() async {
    await completer.future;
    Map<String, String> cookies = {
      "PHPSESSID": phpsessid,
      "web_lang": "cs",
      "login": Uri.parse(cookieEmail).toString(),
    };

    // Spojí cookies do jedné string
    String cookieString = cookies.entries.map((entry) => '${entry.key}=${entry.value}').join('; ');
    // Vytvoří mapu kde ukládá headers
    Map<String, String> headers = {
      "authority": "www.bikramyoga.cz",
      "cookie": cookieString,
    };

    var response = await http.get(Uri.parse("https://www.bikramyoga.cz/novinky/"), headers: headers);
    int numberOfPages = _ziskatPocetStranNovinek(response.body);

    /// Získáme jednotlivé novinky a přidáme do listu
    NovinkyPage novinkyPage = NovinkyPage(novinky: []);
    for (int i = 1; i <= numberOfPages; i++) {
      var response = await http.get(Uri.parse("https://www.bikramyoga.cz/novinky/$i/"), headers: headers);
      novinkyPage.novinky.addAll(_parseNovinky(response.body));
    }

    return novinkyPage;
  }

  ///Získá počet stránek novinek
  int _ziskatPocetStranNovinek(String html) {
    dom.Document document = parser.parse(html);
    late List<dom.Element> novinkyData;
    try {
      novinkyData = document.getElementsByClassName("Pagelist");
    } catch (e) {
      throw ('Chyba při získání novinek');
    }

    // Odstraníme nepotřebé
    novinkyData[0].firstChild?.remove();
    novinkyData[0].children.removeLast();
    novinkyData[0].children.removeLast();

    return novinkyData[0].children.length;
  }

  ///Zpracuje html a vrátí list novinek
  List<Novinka> _parseNovinky(String html) {
    List<Novinka> novinky = [];

    dom.Document document = parser.parse(html);
    late dom.Element novinkyData;
    try {
      novinkyData = document.getElementById("news")!;
    } catch (e) {
      throw ('Chyba při získání novinek');
    }

    // Odstranění zbytečného divu a listu stránek
    novinkyData.children[0].children.removeLast();
    novinkyData.children[0].children.removeLast();

    for (int i = 0; i < novinkyData.children[0].children.length; i++) {
      dom.Element child = novinkyData.children[0].children[i];

      // Nadpis novinky
      if (child.children.length > 2) {
        child.children[0].remove();
        child.children.removeLast();
      } else if (child.children.length > 1) {
        child.children.removeLast();
      }

      String nadpis = child.children[0].children[0].text;
      String urlString = "1";
      if (child.children[0].children[0].children.isNotEmpty) {
        urlString = child.children[0].children[0].children[0].attributes.entries.first.value.toString();
      } else {
        urlString = _ziskatUrlNovinekZNavigace(html, nadpis);
      }

      DateTime? datumVydaniDateTime;
      String? popis;

      // Pokud je jenom 1 child tak to znamena ze je jenom nadpis
      if (child.children[0].children.length > 1) {
        // Datum novinky
        if (child.children[0].children[1].attributes.entries.first.toString() == "MapEntry(class: Date)") {
          String datumVydani = child.children[0].children[1].text;
          if (datumVydani.isNotEmpty) {
            datumVydaniDateTime = DateTime(
              int.parse(datumVydani.split('.')[2]),
              int.parse(datumVydani.split('.')[1]),
              int.parse(datumVydani.split('.')[0]),
            );
          }
        } else {
          // Popis novinky
          if (1 < child.children[0].children[1].children.length) {
            // Když je popisek <div> s children <p>
            child.children[0].children[1].children[0].remove();
            child.children[0].children[1].children[0].remove();
            popis = child.children[0].children[1].children[0].text;
          } else {
            // Když je popisek pouze <p>
            popis = child.children[0].children[1].text.trim();
          }
        }
      }

      Uri url = Uri.parse("https://www.bikramyoga.cz$urlString");

      novinky.add(Novinka(
        nadpis: nadpis,
        popis: popis,
        url: url,
        datumVydani: datumVydaniDateTime,
      ));
    }
    return novinky;
  }

  /// Tady získáváme odkazy na novinky které nemají odkaz na stránce novinek, ale jenom v main menu...
  String _ziskatUrlNovinekZNavigace(String html, String nadpis) {
    dom.Document document = parser.parse(html);
    late dom.Element novinkyData;
    try {
      novinkyData = document.getElementById("main-menu")!;
    } catch (e) {
      throw ('Chyba při získání novinek');
    }
    dom.Element child = novinkyData.children[0].children[0].children.first.children[1].children[0];

    /// Když i tak nenajdeme odkaz na novinku, tak uživatele pošleme na všechny novinky
    String url = "/novinky/";
    for (int i = 0; i < child.children.length; i++) {
      if (child.children[i].text.trim().toUpperCase() == nadpis.trim().toUpperCase()) {
        url = child.children[i].children[0].attributes.entries.first.value.toString();
      }
    }
    return url;
  }
}
