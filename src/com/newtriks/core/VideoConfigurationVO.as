/** @author: Simon Bailey <simon@newtriks.com> */
package com.newtriks.core
{
    public class VideoConfigurationVO
    {
        public function VideoConfigurationVO(baseType:String)
        {
            _baseType=baseType;
        }

        private var _baseType:String;
        public function get baseType():String
        {
            return _baseType;
        }

        internal var _aspectRatio:String=VideoBase.STRETCH_SCREEN;

        public function aspectRatio(value:String):VideoConfigurationVO
        {
            _aspectRatio=value;
            return this;
        }

        internal var _client:Object;

        public function client(value:Object):VideoConfigurationVO
        {
            _client=value;
            return this;
        }

        internal var _layoutCallbackHandler:Function;

        public function layoutCallbackHandler(value:Function):VideoConfigurationVO
        {
            _layoutCallbackHandler=value;
            return this;
        }

        internal var _logCallbackHandler:Function;

        public function logCallbackHandler(value:Function):VideoConfigurationVO
        {
            _logCallbackHandler=value;
            return this;
        }

        internal var _bandwidth:uint;

        public function bandwidth(value:uint):VideoConfigurationVO
        {
            _bandwidth=value;
            return this;
        }

        internal var _quality:uint;

        public function quality(value:uint):VideoConfigurationVO
        {
            _quality=value;
            return this;
        }

        internal var _fps:uint;

        public function fps(value:uint):VideoConfigurationVO
        {
            _fps=value;
            return this;
        }

        internal var _microphoneRate:uint;

        public function microphoneRate(value:uint):VideoConfigurationVO
        {
            _microphoneRate=value;
            return this;
        }

        internal var _microphoneSilenceLevel:uint;

        public function microphoneSilenceLevel(value:uint):VideoConfigurationVO
        {
            _microphoneSilenceLevel=value;
            return this;
        }

        internal var _metaDataReceived:Function;

        public function metaDataReceived(value:Function):VideoConfigurationVO
        {
            _metaDataReceived=value;
            return this;
        }
    }
}