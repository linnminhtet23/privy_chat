import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:pointycastle/export.dart';
import 'package:pointycastle/api.dart' as pc;
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:asn1lib/asn1lib.dart';

class EncryptionUtils {
  // Generate RSA key pair
  static AsymmetricKeyPair<PublicKey, PrivateKey> generateRSAKeyPair({int bitLength = 2048}) {
    final rsaKeyGen = RSAKeyGenerator()
      ..init(ParametersWithRandom(RSAKeyGeneratorParameters(BigInt.parse('65537'), bitLength, 64), _secureRandom()));

    return rsaKeyGen.generateKeyPair();
  }

  // AES encryption
  static Map<String, dynamic> encryptWithAES(String plainText, String aesKey){
  try {

  final key = encrypt.Key(Uint8List.fromList(utf8.encode(aesKey)));
    final iv = encrypt.IV.fromLength(16);
    final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.cbc));

    final encrypted = encrypter.encrypt(plainText, iv: iv);
    return {
      'cipherText': encrypted.base64,
      'iv': iv.base64,
    };
  } catch (e, stacktrace) {
  // Log the error and stack trace for debugging
  print("Decryption failed: $e");
  print("Stacktrace: $stacktrace");

  // Rethrow the exception for further handling if needed
  rethrow;
}
  }

  static String decryptWithAES(String cipherText, String aesKey, String ivBase64) {
  try {

    final key = encrypt.Key(Uint8List.fromList(utf8.encode(aesKey)));
    print("Key: $key");
    final iv = encrypt.IV.fromBase64(ivBase64);
        print("IV: $iv");

    final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.cbc));
        print("Encrypter: ${encrypter}");

    return encrypter.decrypt64(cipherText, iv: iv);
  } catch (e, stacktrace) {
  // Log the error and stack trace for debugging
  print("Decryption failed: $e");
  print("Stacktrace: $stacktrace");

  // Rethrow the exception for further handling if needed
  rethrow;
}
  }


  // static String decryptWithAES(String cipherText, String aesKey, String ivBase64) {
  //   try {
  //     // Ensure the AES key is one of the required lengths: 128, 192, or 256 bits
  //     final keyBytes = _getValidKeyLength(aesKey);
  //     final key = encrypt.Key(keyBytes);
  //     final iv = encrypt.IV.fromBase64(ivBase64);
  //
  //     // Debugging: Log the key and IV
  //     print("AES Key (UTF-8): $keyBytes");
  //     print("IV (Base64 Decoded): ${iv.bytes}");
  //
  //     // Initialize the encrypter with AES CBC mode
  //     final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.cbc));
  //
  //     // Debugging: Log the cipher text before decryption
  //     print("Cipher Text (Base64): $cipherText");
  //
  //     // Perform decryption
  //     final decryptedText = encrypter.decrypt64(cipherText, iv: iv);
  //
  //     // Debugging: Log the decrypted text
  //     print("Decrypted Text: $decryptedText");
  //
  //     return decryptedText;
  //   } catch (e, stacktrace) {
  //     // Log the error and stack trace for debugging
  //     print("Decryption failed: $e");
  //     print("Stacktrace: $stacktrace");
  //
  //     // Rethrow the exception for further handling if needed
  //     rethrow;
  //   }
  // }
  //
  // static Uint8List _getValidKeyLength(String aesKey) {
  //   // Ensure the key is 128, 192, or 256 bits (16, 24, or 32 bytes)
  //   final keyBytes = Uint8List.fromList(utf8.encode(aesKey));
  //
  //   if (keyBytes.length == 16 || keyBytes.length == 24 || keyBytes.length == 32) {
  //     return keyBytes;
  //   } else if (keyBytes.length < 16) {
  //     // Pad the key to 16 bytes if it's too short
  //     return Uint8List.fromList(keyBytes + List.filled(16 - keyBytes.length, 0));
  //   } else {
  //     // Truncate the key to 32 bytes if it's too long
  //     return keyBytes.sublist(0, 32);
  //   }
  // }


  // RSA encryption
  static Uint8List encryptWithRSA(String data, RSAPublicKey publicKey) {
    final rsaEngine = RSAEngine()..init(true, PublicKeyParameter<RSAPublicKey>(publicKey));
    return rsaEngine.process(Uint8List.fromList(utf8.encode(data)));
  }

  static String decryptWithRSA(Uint8List encryptedData, RSAPrivateKey privateKey) {
    try {
      final rsaEngine = RSAEngine()
        ..init(
            false,
            PrivateKeyParameter<RSAPrivateKey>(
                privateKey)); // Use same OAEP padding here

      // Debugging: Log the length of the encrypted data
      print("Encrypted Data Length: ${encryptedData.length}");

      final decryptedData = rsaEngine.process(encryptedData);

      // Debugging: Log the length of the decrypted data
      print("Decrypted Data Length: ${decryptedData.length}");
      print("Raw Decrypted Data: $decryptedData");


      // Decode and return the decrypted data as a string
      return utf8.decode(decryptedData, allowMalformed: true);
    } catch (e,stacktrace) {
      print("Decryption failed: $e");
      print("Stacktrace: $stacktrace");

      rethrow; // Rethrow the error to handle it elsewhere if needed
    }
  }

  // Hybrid encryption
  static Map<String, dynamic> hybridEncrypt(String plainText, RSAPublicKey publicKey) {
    print("Plain Text: $plainText");

    // Generate a random AES key
    final aesKey = _generateRandomAESKeyBytes(); // Byte array
    print("AES Key (bytes): $aesKey");

    // Encrypt the message using AES
    final aesEncrypted = encryptWithAES(plainText, base64Encode(aesKey));
    print("AES Encryption Complete");

    // Encrypt the AES key using RSA
    final encryptedAESKey = encryptWithRSA(base64Encode(aesKey), publicKey);
    print("RSA Encryption Complete");

    return {
      'encryptedAESKey': base64Encode(encryptedAESKey), // Store as Base64
      'cipherText': aesEncrypted['cipherText'], // Already encoded
      'iv': aesEncrypted['iv'], // Store IV for decryption
    };
  }
// Hybrid decryption
  static String hybridDecrypt(Map<String, dynamic> encryptedData, RSAPrivateKey privateKey) {
    try {
      // Decrypt the AES key using RSA
      final encryptedAESKey = base64Decode(encryptedData['encryptedAESKey']); // Decode Base64

      print("Encrypted AES Key (Base64 Decoded): $encryptedAESKey");

      // Decrypt the AES key using RSA
      final aesKey = decryptWithRSA(encryptedAESKey, privateKey);
      print("Decrypted AES Key: $aesKey");

      // Decrypt the message using AES
      final decryptedMessage = decryptWithAES(encryptedData['cipherText'], aesKey, encryptedData['iv']);
      print("Decrypted Message: $decryptedMessage");

      return decryptedMessage;
    } catch (e) {
      print("Error during hybrid decryption: $e");
      rethrow; // Re-throw the error to handle it upstream if needed
    }
  }

// Utility to generate a secure random AES key as bytes
  static Uint8List _generateRandomAESKeyBytes({int length = 16}) {
    final random = _secureRandom();
    final key = Uint8List(length);
    for (int i = 0; i < length; i++) {
      key[i] = random.nextUint8();
    }
    return key; // Byte array, no need for Base64 encoding
  }

// Secure random generator
  static pc.SecureRandom _secureRandom() {
    final secureRandom = FortunaRandom();
    final random = Random.secure();
    final seed = List<int>.generate(32, (_) => random.nextInt(256));
    secureRandom.seed(KeyParameter(Uint8List.fromList(seed)));
    return secureRandom;
  }

  static String encodePublicKeyToPem(RSAPublicKey publicKey) {
    final asn1Sequence = ASN1Sequence();
    asn1Sequence.add(ASN1Integer(publicKey.modulus!));
    asn1Sequence.add(ASN1Integer(publicKey.exponent!));

    final publicKeyBytes = asn1Sequence.encodedBytes;
    final publicKeyBase64 = base64Encode(publicKeyBytes);

    return '-----BEGIN PUBLIC KEY-----\n${_chunk(base64Encode(publicKeyBytes))}\n-----END PUBLIC KEY-----';
  }

  static String encodePrivateKeyToPem(RSAPrivateKey privateKey) {
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

  static String _chunk(String str, {int size = 64}) =>
      str.replaceAllMapped(RegExp('.{1,$size}'), (match) => '${match.group(0)}\n');

  static RSAPublicKey decodePublicKeyFromPem(String pem) {
    try {
      // Step 1: Print the original PEM string for debugging
      print("Original PEM:\n$pem");

      // Step 2: Clean the PEM string
      final cleanedPem = pem
          .replaceAll('-----BEGIN PUBLIC KEY-----', '')
          .replaceAll('-----END PUBLIC KEY-----', '')
          .replaceAll('\n', '')
          .replaceAll('\r', '')
          .trim();
      print("Cleaned PEM:\n$cleanedPem");

      // Step 3: Re-chunk the string to ensure proper formatting
      final formattedPem = _chunk(cleanedPem);
      print("Formatted PEM:\n$formattedPem");

      // Step 4: Decode the Base64 string
      final publicKeyBytes = base64Decode(cleanedPem);
      print("Decoded Public Key Bytes:\n$publicKeyBytes");

      // Step 5: Parse ASN.1 structure
      final asn1Parser = ASN1Parser(publicKeyBytes);
      print("ASN.1 Parser initialized.");

      final sequence = asn1Parser.nextObject() as ASN1Sequence;
      print("ASN.1 Sequence parsed:\n$sequence");

      // Step 6: Extract modulus and exponent
      final modulus = (sequence.elements![0] as ASN1Integer).valueAsBigInteger!;
      print("Modulus:\n$modulus");

      final exponent = (sequence.elements![1] as ASN1Integer).valueAsBigInteger!;
      print("Exponent:\n$exponent");

      // Step 7: Create and return RSAPublicKey
      final rsaPublicKey = RSAPublicKey(modulus, exponent);
      print("RSAPublicKey created successfully.");
      return rsaPublicKey;

    } catch (e, stacktrace) {
      // Log error and stack trace
      print("Error during PEM decoding: $e");
      print("Stacktrace:\n$stacktrace");
      throw FormatException("Failed to decode PEM public key: $e");
    }
  }

  static RSAPrivateKey decodePrivateKeyFromPem(String pem) {
    try {
      // Clean the PEM input
      final cleanedPem = pem
          .replaceAll('-----BEGIN PRIVATE KEY-----', '')
          .replaceAll('-----END PRIVATE KEY-----', '')
          .replaceAll('\n', '')
          .replaceAll('\r', '')
          .trim();
      print("Cleaned PEM: $cleanedPem");

      // Decode the Base64 string
      final privateKeyBytes = base64Decode(cleanedPem);
      print("Decoded Private Key Bytes: $privateKeyBytes");

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
      print("Modulus (n): $modulus");
      print("Prime P: $p");
      print("Prime Q: $q");
      print("Public Exponent (e): $publicExponent");
      print("Private Exponent (d): $privateExponent");

      // Validate that modulus matches p * q
      print("Hello ${modulus != (p * q)}");

      if (modulus != (p * q)) {
        throw ArgumentError("Modulus is inconsistent with P and Q");
      }

      // Create and return the RSAPrivateKey
      final rsaPrivateKey = RSAPrivateKey(modulus, privateExponent, p, q,publicExponent);
      print("RSAPrivateKey created successfully.");
      return rsaPrivateKey;

    } catch (e, stacktrace) {
      print("Error during PEM decoding: $e");
      print("Stacktrace:\n$stacktrace");
      throw FormatException("Failed to decode PEM private key: $e");
    }
  }


  // static String encodePublicKeyToPem(RSAPublicKey publicKey) {
  //   final modulus = publicKey.modulus;
  //   final exponent = publicKey.exponent;
  //
  //   final publicKeyBytes = [
  //     ..._encodeInteger(modulus!),
  //     ..._encodeInteger(exponent!),
  //   ];
  //
  //   final publicKeyBase64 = base64Encode(publicKeyBytes);
  //   return '-----BEGIN PUBLIC KEY-----\n$publicKeyBase64\n-----END PUBLIC KEY-----';
  // }
  //
  // // Encode private key to PEM format
  // static String encodePrivateKeyToPem(RSAPrivateKey privateKey) {
  //   final modulus = privateKey.modulus;
  //   final privateExponent = privateKey.privateExponent;
  //   final publicExponent = privateKey.publicExponent;
  //   final p = privateKey.p;
  //   final q = privateKey.q;
  //
  //   final privateKeyBytes = [
  //     ..._encodeInteger(modulus!),
  //     ..._encodeInteger(privateExponent!),
  //     ..._encodeInteger(publicExponent!),
  //     ..._encodeInteger(p!),
  //     ..._encodeInteger(q!),
  //   ];
  //
  //   final privateKeyBase64 = base64Encode(privateKeyBytes);
  //   return '-----BEGIN PRIVATE KEY-----\n$privateKeyBase64\n-----END PRIVATE KEY-----';
  // }
  //
  // // Utility to encode integer values (modulus, exponents, etc.)
  // static List<int> _encodeInteger(BigInt integer) {
  //   if (integer == BigInt.zero) {
  //     return [0];
  //   }
  //
  //   final bytes = <int>[];
  //   BigInt temp = integer;
  //
  //   // Convert the BigInt to bytes
  //   while (temp > BigInt.zero) {
  //     bytes.insert(0, (temp & BigInt.from(0xFF)).toInt());
  //     temp = temp >> 8; // Shift right by 8 bits
  //   }
  //
  //   return bytes;
  // }

  // // Decode PEM format public key to RSAPublicKey
  // static RSAPublicKey decodePublicKeyFromPem(String pem) {
  //   final publicKeyBytes = base64Decode(pem.replaceAll('-----BEGIN PUBLIC KEY-----', '').replaceAll('-----END PUBLIC KEY-----', '').trim());
  //   final modulus = _decodeInteger(publicKeyBytes.sublist(0, 128));
  //   final exponent = _decodeInteger(publicKeyBytes.sublist(128));
  //   // print("RSAPublicKey ${RSAPublicKey(modulus, exponent)}");
  //
  //   return RSAPublicKey(modulus, exponent);
  // }
  //
  // // Decode PEM format private key to RSAPrivateKey
  // static RSAPrivateKey decodePrivateKeyFromPem(String pem) {
  //   try {
  //     final privateKeyBytes = base64Decode(
  //         pem.replaceAll('-----BEGIN PRIVATE KEY-----', '').replaceAll(
  //             '-----END PRIVATE KEY-----', '').trim());
  //     final modulus = _decodeInteger(privateKeyBytes.sublist(0, 128));
  //
  //     final privateExponent = _decodeInteger(privateKeyBytes.sublist(128, 192));
  //     final publicExponent = _decodeInteger(privateKeyBytes.sublist(192, 256));
  //     final p = _decodeInteger(privateKeyBytes.sublist(256, 320));
  //     final q = _decodeInteger(privateKeyBytes.sublist(320, 384));
  //
  //     // print("privateExponent $privateExponent,modulus $modulus,publicExponent $publicExponent, p $p, q $q");
  //     print("RSAPrivateKey${RSAPrivateKey(
  //         privateExponent, modulus, publicExponent, p, q)}");
  //     return RSAPrivateKey(privateExponent, modulus, publicExponent, p, q);
  //   }catch (e) {
  //     print("Error decoding private key: $e");
  //     rethrow;
  //   }
  // }
  //
  //
  //
  // // Utility to decode an integer from a byte array
  // static BigInt _decodeInteger(List<int> bytes) {
  //   return BigInt.parse(bytes.fold<String>('', (prev, byte) => prev + byte.toRadixString(16)), radix: 16);
  // }


}