import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:pointycastle/export.dart'; // Required for low-level cryptography
import 'package:asn1lib/asn1lib.dart';


// Utility for random prime generation (simplified example)
BigInt generateRandomPrime(int bitLength) {
  final secureRandom = SecureRandom("Fortuna")
    ..seed(KeyParameter(Uint8List.fromList(List<int>.generate(32, (i) => Random.secure().nextInt(256)))));
  // return generateProbablePrime(bitLength, secureRandom);
    return generateProbablePrime(bitLength, 1, secureRandom);

}

String generateRandomPlaintext({int length = 16}) {
  const charset = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
  final random = Random.secure();
  return List.generate(length, (_) => charset[random.nextInt(charset.length)]).join();
}


// Generate RSA keys
AsymmetricKeyPair<RSAPublicKey, RSAPrivateKey> generateRSAKeyPair({int bitLength = 2048}) {
  final keyGenerator = RSAKeyGenerator()
    ..init(ParametersWithRandom(
      RSAKeyGeneratorParameters(BigInt.parse('65537'), bitLength, 64),
      SecureRandom("Fortuna")
        ..seed(KeyParameter(Uint8List.fromList(List<int>.generate(32, (i) => Random.secure().nextInt(256))))),
    ));
  final pair = keyGenerator.generateKeyPair();
  final publicKey = pair.publicKey as RSAPublicKey;
  final privateKey = pair.privateKey as RSAPrivateKey;
  return AsymmetricKeyPair<RSAPublicKey, RSAPrivateKey>(publicKey, privateKey);
}
// AsymmetricKeyPair<RSAPublicKey, RSAPrivateKey> generateRSAKeyPair(SecureRandom secureRandom) {
//   final keyGenerator = RSAKeyGenerator()
//     ..init(ParametersWithRandom(RSAKeyGeneratorParameters(BigInt.from(65537), 2048, 12), secureRandom));
  
//   final pair = keyGenerator.generateKeyPair();
  
//   // Explicitly cast the generated keys
//   final publicKey = pair.publicKey as RSAPublicKey;
//   final privateKey = pair.privateKey as RSAPrivateKey;
  
//   return AsymmetricKeyPair<RSAPublicKey, RSAPrivateKey>(publicKey, privateKey);
// }


// RSA Encryption
String rsaEncrypt(String plaintext, RSAPublicKey publicKey) {
  final rsaEncryptor = encrypt.Encrypter(encrypt.RSA(publicKey: publicKey));
  return rsaEncryptor.encrypt(plaintext).base64;
}

// RSA Decryption
String rsaDecrypt(String encryptedText, RSAPrivateKey privateKey) {
  final rsaDecryptor = encrypt.Encrypter(encrypt.RSA(privateKey: privateKey));
  return rsaDecryptor.decrypt64(encryptedText);
}

// AES Encryption
String aesEncrypt(String plaintext, String key) {
  final aesKey = encrypt.Key.fromUtf8(key);
  final encrypter = encrypt.Encrypter(encrypt.AES(aesKey, mode: encrypt.AESMode.ecb));
  final encrypted = encrypter.encrypt(plaintext, iv: encrypt.IV.fromLength(16));
  return encrypted.base64;
}

// AES Decryption
String aesDecrypt(String encryptedText, String key) {
  final aesKey = encrypt.Key.fromUtf8(key);
  final encrypter = encrypt.Encrypter(encrypt.AES(aesKey, mode: encrypt.AESMode.ecb));
  final decrypted = encrypter.decrypt64(encryptedText, iv: encrypt.IV.fromLength(16));
  return decrypted;
}

String hybridEncrypt(String plaintext, RSAPublicKey publicKey) {
  // Step 1: Generate AES key
  final aesKey = generateRandomPlaintext(length: 16); // 16-byte AES key (128 bits)

  // Step 2: Encrypt the plaintext with the AES key
  final aesEncrypted = aesEncrypt(plaintext, aesKey);

  // Step 3: Encrypt the AES key with the RSA public key
  final rsaEncrypted = rsaEncrypt(aesKey, publicKey);

  // Step 4: Combine RSA encrypted AES key and AES encrypted data
  final result = {
    'aesKeyEncrypted': rsaEncrypted,
    'aesEncryptedData': aesEncrypted,
  };

  return jsonEncode(result); // Return a JSON encoded string of the result
}

String hybridEncryptMessageReplied(String plaintext, RSAPrivateKey privateKey, String aesKeyEncrypted) {
  // Step 1: Generate AES key
  // final aesKey = generateRandomPlaintext(length: 16); // 16-byte AES key (128 bits)

    final aesKey = rsaDecrypt(aesKeyEncrypted, privateKey);


  // Step 2: Encrypt the plaintext with the AES key
  final aesEncrypted = aesEncrypt(plaintext, aesKey);


  return aesEncrypted; // Return a JSON encoded string of the result
}


String hybridDecrypt(String encryptedData, RSAPrivateKey privateKey) {
  final decoded = jsonDecode(encryptedData);

  // Step 1: Extract the RSA encrypted AES key and AES encrypted data
  final rsaEncryptedKey = decoded['aesKeyEncrypted'];
  final aesEncryptedData = decoded['aesEncryptedData'];

  // Step 2: Decrypt the AES key using RSA private key
  final aesKey = rsaDecrypt(rsaEncryptedKey, privateKey);

  // Step 3: Decrypt the actual data with the decrypted AES key
  final decryptedData = aesDecrypt(aesEncryptedData, aesKey);

  return decryptedData; // Return the decrypted data
  
}

Uint8List bigIntToBytes(BigInt number) {
  final byteList = <int>[];
  BigInt current = number;

  while (current > BigInt.zero) {
    byteList.insert(0, (current & BigInt.from(0xff)).toInt());
    current = current >> 8;
  }

  return Uint8List.fromList(byteList);
}

BigInt bytesToBigInt(Uint8List bytes) {
  BigInt result = BigInt.zero;
  for (final byte in bytes) {
    result = (result << 8) | BigInt.from(byte);
  }
  return result;
}

   String encodePublicKeyToPem(RSAPublicKey publicKey) {
    final asn1Sequence = ASN1Sequence();
    asn1Sequence.add(ASN1Integer(publicKey.modulus!));
    asn1Sequence.add(ASN1Integer(publicKey.exponent!));

    final publicKeyBytes = asn1Sequence.encodedBytes;
    // final publicKeyBase64 = base64Encode(publicKeyBytes);

    return '-----BEGIN PUBLIC KEY-----\n${_chunk(base64Encode(publicKeyBytes))}\n-----END PUBLIC KEY-----';
  }

   String encodePrivateKeyToPem(RSAPrivateKey privateKey) {
    final asn1Sequence = ASN1Sequence();
    asn1Sequence.add(ASN1Integer(BigInt.zero)); // Version
    asn1Sequence.add(ASN1Integer(privateKey.modulus!));
    asn1Sequence.add(ASN1Integer(privateKey.publicExponent!));
    asn1Sequence.add(ASN1Integer(privateKey.privateExponent!));
    asn1Sequence.add(ASN1Integer(privateKey.p!));
    asn1Sequence.add(ASN1Integer(privateKey.q!));
    asn1Sequence.add(ASN1Integer(privateKey.privateExponent! % (privateKey.p! - BigInt.one)));
    asn1Sequence.add(ASN1Integer(privateKey.privateExponent! % (privateKey.q! - BigInt.one)));
    asn1Sequence.add(ASN1Integer(privateKey.q!.modInverse(privateKey.p!)));

    final privateKeyBytes = asn1Sequence.encodedBytes;
    return '-----BEGIN PRIVATE KEY-----\n${_chunk(base64Encode(privateKeyBytes))}\n-----END PRIVATE KEY-----';
  }

   String _chunk(String str, {int size = 64}) =>
      str.replaceAllMapped(RegExp('.{1,$size}'), (match) => '${match.group(0)}\n');

   RSAPublicKey decodePublicKeyFromPem(String pem) {
    try {
      // Step 1: Print the original PEM string for debugging
      // print("Original PEM:\n$pem");

      // Step 2: Clean the PEM string
      final cleanedPem = pem
          .replaceAll('-----BEGIN PUBLIC KEY-----', '')
          .replaceAll('-----END PUBLIC KEY-----', '')
          .replaceAll('\n', '')
          .replaceAll('\r', '')
          .trim();
      // print("Cleaned PEM:\n$cleanedPem");

      // Step 3: Re-chunk the string to ensure proper formatting
      final formattedPem = _chunk(cleanedPem);
      // print("Formatted PEM:\n$formattedPem");

      // Step 4: Decode the Base64 string
      final publicKeyBytes = base64Decode(cleanedPem);
      // print("Decoded Public Key Bytes:\n$publicKeyBytes");

      // Step 5: Parse ASN.1 structure
      final asn1Parser = ASN1Parser(publicKeyBytes);
      // print("ASN.1 Parser initialized.");

      final sequence = asn1Parser.nextObject() as ASN1Sequence;
      // print("ASN.1 Sequence parsed:\n$sequence");

      // Step 6: Extract modulus and exponent
      final modulus = (sequence.elements![0] as ASN1Integer).valueAsBigInteger!;
      // print("Modulus:\n$modulus");

      final exponent = (sequence.elements![1] as ASN1Integer).valueAsBigInteger!;
      // print("Exponent:\n$exponent");

      // Step 7: Create and return RSAPublicKey
      final rsaPublicKey = RSAPublicKey(modulus, exponent);
      // print("RSAPublicKey created successfully.");
      return rsaPublicKey;

    } catch (e, stacktrace) {
      // Log error and stack trace
      print("Error during PEM decoding: $e");
      print("Stacktrace:\n$stacktrace");
      throw FormatException("Failed to decode PEM public key: $e");
    }
  }

   RSAPrivateKey decodePrivateKeyFromPem(String pem) {
    try {
      // Clean the PEM input
      final cleanedPem = pem
          .replaceAll('-----BEGIN PRIVATE KEY-----', '')
          .replaceAll('-----END PRIVATE KEY-----', '')
          .replaceAll('\n', '')
          .replaceAll('\r', '')
          .trim();
      // print("Cleaned PEM: $cleanedPem");

      // Decode the Base64 string
      final privateKeyBytes = base64Decode(cleanedPem);
      // print("Decoded Private Key Bytes: $privateKeyBytes");

      // Parse the ASN.1 structure
      final asn1Parser = ASN1Parser(privateKeyBytes);
      final sequence = asn1Parser.nextObject() as ASN1Sequence;

      // Extract the RSA key components
      final modulus = (sequence.elements![1] as ASN1Integer).valueAsBigInteger!;
      final publicExponent = (sequence.elements![2] as ASN1Integer).valueAsBigInteger!;
      final privateExponent = (sequence.elements![3] as ASN1Integer).valueAsBigInteger!;
      final p = (sequence.elements![4] as ASN1Integer).valueAsBigInteger!;
      final q = (sequence.elements![5] as ASN1Integer).valueAsBigInteger!;

      // Log the key components
      // print("Modulus (n): $modulus");
      // print("Prime P: $p");
      // print("Prime Q: $q");
      // print("Public Exponent (e): $publicExponent");
      // print("Private Exponent (d): $privateExponent");

      // Validate that modulus matches p * q
      // print("Hello ${modulus != (p * q)}");

      if (modulus != (p * q)) {
        throw ArgumentError("Modulus is inconsistent with P and Q");
      }

      // Create and return the RSAPrivateKey
      final rsaPrivateKey = RSAPrivateKey(modulus, privateExponent, p, q,publicExponent);
      // print("RSAPrivateKey created successfully.");
      return rsaPrivateKey;

    } catch (e, stacktrace) {
      print("hellooooo");
      print("Error during PEM decoding: $e");
      print("Stacktrace:\n$stacktrace");
      throw FormatException("Failed to decode PEM private key: $e");
    }
  }

// void main() {
//   // RSA Setup
//   final rsaKeyPair = generateRSAKeyPair();
//   final publicKey = rsaKeyPair.publicKey as RSAPublicKey;
//   final privateKey = rsaKeyPair.privateKey as RSAPrivateKey;

//   final rsaPlaintext = "PASSWORD00000000"; // Ensure this is 16 bytes
//   final rsaEncrypted = rsaEncrypt(rsaPlaintext, publicKey);
//   final rsaDecrypted = rsaDecrypt(rsaEncrypted, privateKey);

//   print("RSA Encrypted: $rsaEncrypted");
//   print("RSA Decrypted: $rsaDecrypted");

//   // AES Setup
//   final aesKey = rsaDecrypted; // Use RSA decrypted message as AES key
//   final aesPlaintext = "Hello World!0000"; // Ensure 16-byte plaintext
//   final aesEncrypted = aesEncrypt(aesPlaintext, aesKey);
//   final aesDecrypted = aesDecrypt(aesEncrypted, aesKey);

//   print("AES Encrypted: $aesEncrypted");
//   print("AES Decrypted: $aesDecrypted");
// }
