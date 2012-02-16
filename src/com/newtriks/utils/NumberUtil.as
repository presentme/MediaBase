/**
 * User: newtriks
 * Date: 14/11/2011
 */
package com.newtriks.utils {
public class NumberUtil {
    public static function roundNumber(number:Number, decimals:int = 1):Number {
        return Number(parseFloat(number.toFixed(decimals)));
    }
}
}
