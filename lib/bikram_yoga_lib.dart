import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

BikramYoga bikramYoga = BikramYoga();

enum PossibleFails {
  emailAlreadyExists,
  nameAlreadyExists,
  success,
  networkError,
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
}
