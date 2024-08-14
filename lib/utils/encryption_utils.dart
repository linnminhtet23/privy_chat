import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:pointycastle/asn1/asn1_object.dart';
import 'package:pointycastle/asn1/primitives/asn1_bit_string.dart';
import 'package:pointycastle/asn1/primitives/asn1_integer.dart';
import 'package:pointycastle/asn1/primitives/asn1_octet_string.dart';
import 'package:pointycastle/asn1/primitives/asn1_sequence.dart';
import 'package:pointycastle/export.dart' as crypto;

class EncryptionUtils {
 static Future<crypto.AsymmetricKeyPair<crypto.RSAPublicKey, crypto.RSAPrivateKey>> generateKeyPair() async {
    // Define RSA key parameters
    var keyParams = crypto.RSAKeyGeneratorParameters(BigInt.from(65537), 2048, 5);
    
    // Create a secure random generator
    var secureRandom = crypto.FortunaRandom();
    var random = Random.secure();
    var seed = List<int>.generate(32, (_) => random.nextInt(255));
    secureRandom.seed(crypto.KeyParameter(Uint8List.fromList(seed)));
    
    // Initialize RSA key generator
    var keyGenerator = crypto.RSAKeyGenerator();
    keyGenerator.init(crypto.ParametersWithRandom(keyParams, secureRandom));
    
    // Generate key pair
    var pair = keyGenerator.generateKeyPair();
    
    // Cast the keys to RSAPublicKey and RSAPrivateKey
    var publicKey = pair.publicKey as crypto.RSAPublicKey;
    var privateKey = pair.privateKey as crypto.RSAPrivateKey;
    
    return crypto.AsymmetricKeyPair<crypto.RSAPublicKey, crypto.RSAPrivateKey>(publicKey, privateKey);
  }


  static String encodePublicKeyToPem(crypto.RSAPublicKey publicKey) {
    var algorithmSeq = ASN1Sequence()
      ..add(ASN1Object.fromBytes(Uint8List.fromList(
          [0x06, 0x09, 0x2A, 0x86, 0x48, 0x86, 0xF7, 0x0D, 0x01, 0x01, 0x01])))
      ..add(ASN1Object.fromBytes(Uint8List.fromList([0x05, 0x00])));

    var publicKeySeq = ASN1Sequence()
      ..add(ASN1Integer(publicKey.modulus)) // Ensure modulus is not null
      ..add(ASN1Integer(publicKey.exponent)); // Ensure exponent is not null

    var publicKeySeqBitString = ASN1BitString(stringValues: Uint8List.fromList(publicKeySeq.encode()));
    var topLevelSeq = ASN1Sequence()
      ..add(algorithmSeq)
      ..add(publicKeySeqBitString);

    var dataBase64 = base64.encode(topLevelSeq.encode());

    return '''-----BEGIN PUBLIC KEY-----\n$dataBase64\n-----END PUBLIC KEY-----''';
  }

  static String encodePrivateKeyToPem(crypto.RSAPrivateKey privateKey) {
    var version = ASN1Integer(BigInt.from(0));
    var algorithmSeq = ASN1Sequence()
      ..add(ASN1Object.fromBytes(Uint8List.fromList(
          [0x06, 0x09, 0x2A, 0x86, 0x48, 0x86, 0xF7, 0x0D, 0x01, 0x01, 0x01])))
      ..add(ASN1Object.fromBytes(Uint8List.fromList([0x05, 0x00])));

    var privateKeySeq = ASN1Sequence()
      ..add(ASN1Integer(privateKey.n ?? BigInt.zero)) // Ensure modulus is not null
      ..add(ASN1Integer(privateKey.exponent)) // Use if available or required
      ..add(ASN1Integer(privateKey.privateExponent)) // Use this for private exponent
      ..add(ASN1Integer(privateKey.p ?? BigInt.zero)) // Use if available
      ..add(ASN1Integer(privateKey.q ?? BigInt.zero)) // Use if available
      ..add(ASN1Integer(BigInt.zero)); // Placeholder for missing fields

    var privateKeySeqOctetString = ASN1OctetString(octets: Uint8List.fromList(privateKeySeq.encode()));
    var topLevelSeq = ASN1Sequence()
      ..add(version)
      ..add(algorithmSeq)
      ..add(privateKeySeqOctetString);

    var dataBase64 = base64.encode(topLevelSeq.encode());

    return '''-----BEGIN PRIVATE KEY-----\n$dataBase64\n-----END PRIVATE KEY-----''';
  }
  
}
