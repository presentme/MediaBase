package com.newtriks.utils {
import mx.utils.Base64Encoder;

public class CreateUUID {
    public static function createUUID():String {
        var nonce:String = generateNonce();
        nonce = base64Encode(nonce);
        return nonce.toLowerCase().replace("=", "");
    }

    private static function generateNonce():String {
        var s:String = Math.random().toString();
        return s.replace(".", "");
    }

    internal static function base64Encode(s:String):String {
        var encoder:Base64Encoder = new Base64Encoder();
        encoder.encode(s);
        return encoder.flush();
    }
}
}