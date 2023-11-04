import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;
import 'package:html/dom.dart' as dom;

enum PossibleFails {
  emailAlreadyExists,
  nameAlreadyExists,
  success,
  networkError,
}

class Uzivatel {
  String jmeno;
  DateTime? datumNarozeni;
  String adresa;
  String zeme;
  int? telCislo;
  String produkt;
  DateTime? produktExpirace;
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

class Rezervace {
  DateTime cas;
  String lekce;
  String lektor;
  int idRezervace;
  bool rezervovano;
  Rezervace({
    required this.cas,
    required this.lekce,
    required this.lektor,
    required this.idRezervace,
    required this.rezervovano,
  });
}

class RezervacePage {
  //vodičkova, pankrác, live stream
  Map<String, List<Rezervace>> rezervace = {};
  RezervacePage({required this.rezervace});
}

class BikramYoga {
  String phpsessid = '';
  String cookieEmail = '';
  Completer<void> completer = Completer<void>();

  BikramYoga() {
    _doInitialRequest();
  }
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

  //vráti true pokud se přihlášení povedlo jinak vrátí false
  Future<bool> login(String email, String password) async {
    await completer.future;
    bool success = false;
    Uri url = Uri.parse("https://www.bikramyoga.cz/");

    var headers = {
      "content-type": "application/x-www-form-urlencoded; charset=UTF-8",
      "cookie": "PHPSESSID=$phpsessid",
    };

    var body = {
      "type": "login",
      "username": email,
      "password": password,
      "request_uri": "/",
      "url": "Modules/BikramYoga/Server/Ajax.php",
    };

    var response = await http.post(url, headers: headers, body: body);
    var login = response.headers["set-cookie"]!.split(";");

    for (var kvPair in login) {
      var kv = kvPair.split("=");
      var key = kv[1].trim();

      if (key.contains("login")) {
        cookieEmail = kv[2];
        success = true;
      }
    }
    return success;
  }

  Future<PossibleFails> signup(String firstName, String lastName, String email) async {
    await completer.future;
    var company = ''; //optional
    var adresa = ''; //optional
    var postovniSmerovaciCislo = '';
    var mesto = '';
    var statCislo = '1'; //1 pro cz
    var telefon = ''; //optional
    var datumNarozeni = '';
    var pohlaviNulaProMuzeJednaProZenu = '0';
    var jakJsteSeONasDozvedeli = '';

    var headers = {
      HttpHeaders.contentTypeHeader: 'application/x-www-form-urlencoded; charset=UTF-8',
      HttpHeaders.cookieHeader: 'PHPSESSID=$phpsessid; comment=comment; web_lang=cs; ',
    };
    var body =
        'bikram-yoga-register%5Bfirst_name%5D=$firstName&bikram-yoga-register%5Bsurname%5D=$lastName&bikram55-yoga-register%5Bcompany%5D=$company&bikram-yoga-register%5Baddress%5D=$adresa&bikram-yoga-register%5Bzip_code%5D=$postovniSmerovaciCislo&bikram-yoga-register%5Bcity%5D=$mesto&bikram-yoga-register%5Bid_sys_states%5D=$statCislo&bikram-yoga-register%5Bphone%5D=$telefon&bikram-yoga-register%5Bemail%5D=$email&bikram-yoga-register%5Bbirth_date%5D=$datumNarozeni&bikram-yoga-register%5Bgender%5D=$pohlaviNulaProMuzeJednaProZenu&bikram-yoga-register%5Breason%5D=$jakJsteSeONasDozvedeli';
    var url = 'https://www.bikramyoga.cz/registrace/';

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

  List<Rezervace> parseRezervace(String id, String html) {
    List<Rezervace> rezervace = [];
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
      String idRezervace = child.children[4].children[0].attributes['data-id']!;
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

      rezervace.add(
        Rezervace(
          cas: casDateTime,
          lekce: lekce,
          lektor: lektor,
          idRezervace: int.parse(idRezervace),
          rezervovano: rezervovano,
        ),
      );
    }
    return rezervace;
  }

  //vrátí seznam rezervací
  Future<RezervacePage> ziskatRezervace() async {
    await completer.future;
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
      "cookie": cookieString,
    };
    var response = await http.get(Uri.parse("https://www.bikramyoga.cz/rezervace"), headers: headers);
    //File("response.html").writeAsString(response.body);
    RezervacePage rezervacePage = RezervacePage(rezervace: {});
    rezervacePage.rezervace['Pankrac'] = parseRezervace('Pankrac', response.body);
    rezervacePage.rezervace['Vodickova'] = parseRezervace('Vodickova', response.body);
    rezervacePage.rezervace['OnlineClass'] = parseRezervace('OnlineClass', response.body);
    return rezervacePage;
  }

  //vrátí true pokud se rezervace povedla jinak vrátí false
  Future<bool> rezervovat(int idRezervace) async {
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
    String requestBody = "async=false&type=reserve&id=$idRezervace&request_uri=%2Frezervace%2F&url=Modules%2FBikramYoga%2FServer%2FAjax.php";

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

  Uzivatel parseUzivatel(String html) {
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

    DateTime? datumNarozeniDateTime;
    if (int.tryParse(datumNarozeni) != null) {
      datumNarozeniDateTime = DateTime(
        int.parse(datumNarozeni.split('.')[2]),
        int.parse(datumNarozeni.split('.')[1]),
        int.parse(datumNarozeni.split('.')[0]),
      );
    }

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
        produktProdlouzit: produktProdlouzit);
  }

  Future<Uzivatel> ziskatUdajeKlienta() async {
    await completer.future;
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
      "cookie": cookieString,
    };
    var response = await http.get(Uri.parse("https://www.bikramyoga.cz/informace-o-uzivateli"), headers: headers);
    //File("response.html").writeAsString(response.body);
    Uzivatel uzivatel = parseUzivatel(response.body);
    return uzivatel;
  }
}
