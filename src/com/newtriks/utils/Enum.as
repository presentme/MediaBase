/**
 * User: newtriks
 * Date: 11/04/2011
 */
package com.newtriks.utils {
import flash.utils.Dictionary;
import flash.utils.describeType;
import flash.utils.getQualifiedClassName;

public class Enum implements IEnum {
    private static var _index:Dictionary = new Dictionary(true);

    public function Enum() {
    }

    private static function indexEnum(enumClass:Class):Dictionary {
        if (_index[enumClass] == null) {
            var dict:Dictionary = new Dictionary(false);

            for each(var constNode:XML in describeType(enumClass)..constant) {
                var fieldName:String = constNode.@name.toString();

                dict[enumClass[fieldName]] = fieldName;
            }

            _index[enumClass] = dict;
        }

        return _index[enumClass] as Dictionary;
    }

    public static function getNames(enumClass:Class):Array {
        var dict:Dictionary = indexEnum(enumClass);
        var names:Array = new Array();

        for each (var name:String in dict) {
            names.push(name);
        }

        return names;
    }

    public static function getName(enumClass:Class, value:Object):String {
        var dict:Dictionary = indexEnum(enumClass);

        if (dict[value] == null) {
            throw new ArgumentError(getQualifiedClassName(enumClass) + " does not define a name with value: " + value.toString());
        }

        return dict[value] as String;
    }

    public static function isDefined(enumClass:Class, value:Object):Boolean {
        var dict:Dictionary = indexEnum(enumClass);

        return (dict[value] != null);
    }
}
}
