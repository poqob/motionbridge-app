package com.motionbridge.app

import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.content.pm.ResolveInfo
import android.os.Bundle
import android.speech.RecognitionListener
import android.speech.RecognitionService
import android.speech.RecognizerIntent
import android.speech.SpeechRecognizer
import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class DictationManager(private val context: Context) : MethodChannel.MethodCallHandler, EventChannel.StreamHandler, RecognitionListener {
    private var speechRecognizer: SpeechRecognizer? = null
    private var eventSink: EventChannel.EventSink? = null
    private val mainHandler = Handler(Looper.getMainLooper())

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "getEngines" -> {
                val list = context.packageManager.queryIntentServices(Intent(RecognitionService.SERVICE_INTERFACE), 0)
                val engines = list.map {
                    mapOf(
                        "packageName" to it.serviceInfo.packageName,
                        "name" to it.loadLabel(context.packageManager).toString()
                    )
                }
                result.success(engines)
            }
            "startDictation" -> {
                val enginePackage = call.argument<String>("enginePackage")
                val locale = call.argument<String>("locale") ?: "en-US"
                
                mainHandler.post {
                    try {
                        speechRecognizer?.destroy()
                        
                        var componentName: ComponentName? = null
                        if (!enginePackage.isNullOrEmpty()) {
                            val list = context.packageManager.queryIntentServices(Intent(RecognitionService.SERVICE_INTERFACE), 0)
                            val resolveInfo = list.find { it.serviceInfo.packageName == enginePackage }
                            if (resolveInfo != null) {
                                componentName = ComponentName(resolveInfo.serviceInfo.packageName, resolveInfo.serviceInfo.name)
                            }
                        }

                        speechRecognizer = if (componentName != null) {
                            SpeechRecognizer.createSpeechRecognizer(context, componentName)
                        } else {
                            SpeechRecognizer.createSpeechRecognizer(context)
                        }

                        speechRecognizer?.setRecognitionListener(this)
                        val intent = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
                            putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL, RecognizerIntent.LANGUAGE_MODEL_FREE_FORM)
                            putExtra(RecognizerIntent.EXTRA_LANGUAGE, locale)
                            putExtra(RecognizerIntent.EXTRA_PARTIAL_RESULTS, true)
                        }
                        speechRecognizer?.startListening(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("ERR", e.message, null)
                    }
                }
            }
            "stopDictation" -> {
                mainHandler.post {
                    speechRecognizer?.stopListening()
                    result.success(true)
                }
            }
            else -> result.notImplemented()
        }
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
    }

    // RecognitionListener
    override fun onReadyForSpeech(params: Bundle?) {}
    override fun onBeginningOfSpeech() {}
    override fun onRmsChanged(rmsdB: Float) {}
    override fun onBufferReceived(buffer: ByteArray?) {}
    override fun onEndOfSpeech() {}
    
    override fun onError(error: Int) {
        mainHandler.post {
            eventSink?.success(mapOf("status" to "error", "code" to error))
            speechRecognizer?.destroy()
            speechRecognizer = null
        }
    }
    
    override fun onResults(results: Bundle?) {
        val matches = results?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
        if (!matches.isNullOrEmpty()) {
            mainHandler.post {
                eventSink?.success(mapOf("status" to "final", "text" to matches[0]))
                speechRecognizer?.destroy()
                speechRecognizer = null
            }
        }
    }
    
    override fun onPartialResults(partialResults: Bundle?) {
        val matches = partialResults?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
        if (!matches.isNullOrEmpty()) {
            mainHandler.post {
                eventSink?.success(mapOf("status" to "partial", "text" to matches[0]))
            }
        }
    }
    
    override fun onEvent(eventType: Int, params: Bundle?) {}
}
