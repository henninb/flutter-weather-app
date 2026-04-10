package com.weather.minneapolis_weather

import android.app.Application
import android.util.Base64
import android.util.Log
import kotlin.text.Charsets
import com.humansecurity.mobile_sdk.HumanSecurity
import com.humansecurity.mobile_sdk.main.policy.HSPolicy
import com.humansecurity.mobile_sdk.main.policy.HSAutomaticInterceptorType
import com.humansecurity.mobile_sdk.main.HSBotDefenderChallengeResult
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import org.json.JSONObject

// Per https://docs.humansecurity.com/applications/flutter-integration
// App id is set from Flutter `humanConfigure` — see `lib/config/human_security_app_id.dart`.
class HumanManager {

    companion object {
        private const val TAG = "HumanSecurity"

        private lateinit var application: Application
        private var appId: String = ""
        private var didStartSdk = false

        fun attachApplication(application: Application) {
            this.application = application
        }

        private fun isConfigured(): Boolean =
            appId.isNotEmpty() && appId != "<APPID>"

        fun configureAndStart(appId: String, customParam1: String) {
            if (appId.isEmpty() || appId == "<APPID>") {
                Log.i(TAG, "HumanSecurity.start skipped — invalid appId from Flutter")
                return
            }
            if (!::application.isInitialized) {
                Log.e(TAG, "HumanSecurity.start: Application not attached (MainApplication missing?)")
                return
            }
            this.appId = appId
            Log.i(TAG, "HUMAN_APP_ID=$appId")
            if (didStartSdk) {
                Log.i(TAG, "humanConfigure: SDK already started, appId=$appId")
                return
            }
            try {
                val policy = HSPolicy()
                policy.automaticInterceptorPolicy.interceptorType = HSAutomaticInterceptorType.NONE
                // Flutter: WebView used for challenge is external to app Kotlin — see hybrid-app-integration.
                policy.hybridAppPolicy.supportExternalWebViews = true
                policy.hybridAppPolicy.setWebRootDomains(
                    setOf(".vercel.bhenning.com", ".perimeterx.net"),
                    appId,
                )
                HumanSecurity.start(application, appId, policy)
                didStartSdk = true
                Log.i(TAG, "HUMAN_APP_ID=$appId HumanSecurity.start OK (hybrid webRootDomains)")
                val customParameters = hashMapOf("custom_param1" to customParam1)
                try {
                    HumanSecurity.BD.setCustomParameters(customParameters, appId)
                    Log.i(TAG, "BD.setCustomParameters custom_param1=$customParam1")
                } catch (e: Exception) {
                    Log.e(TAG, "BD.setCustomParameters: ${e.message}", e)
                }
            } catch (exception: Exception) {
                Log.e(TAG, "HumanSecurity.start: ${exception.message}", exception)
            }
        }

        fun handleEvent(call: MethodCall, result: MethodChannel.Result) {
            if (call.method == "humanConfigure") {
                val args = call.arguments as? Map<*, *>
                val id = args?.get("appId") as? String
                if (id != null) {
                    val raw = args["customParam1"] as? String
                    val trimmed = raw?.trim().orEmpty()
                    val customParam1 =
                        if (trimmed.isEmpty()) "flutter-weather-app" else trimmed
                    configureAndStart(id, customParam1)
                    result.success(null)
                } else {
                    result.error("bad_args", "humanConfigure requires appId string", null)
                }
                return
            }
            if (!isConfigured()) {
                when (call.method) {
                    "humanGetHeaders" -> {
                        Log.i(TAG, "humanGetHeaders stub (SDK not configured)")
                        result.success("{}")
                    }
                    "humanHandleResponse" -> {
                        Log.i(TAG, "humanHandleResponse stub (SDK not configured)")
                        result.success("false")
                    }
                    else -> result.notImplemented()
                }
                return
            }
            if (call.method == "humanGetHeaders") {
                Log.i(TAG, "HUMAN_APP_ID=$appId humanGetHeaders → BD.headersForURLRequest")
                try {
                    val headers = HumanSecurity.BD.headersForURLRequest(appId)
                    val map = headers as Map<*, *>
                    val keys = map.keys.mapNotNull { it?.toString() }.sorted()
                    Log.i(TAG, "humanGetHeaders: ${keys.size} key(s): ${keys.joinToString(", ")}")
                    result.success(JSONObject(map).toString())
                } catch (e: Exception) {
                    Log.e(TAG, "humanGetHeaders: ${e.message}", e)
                    result.success("{}")
                }
            } else if (call.method == "humanHandleResponse") {
                val body = when (val args = call.arguments) {
                    is String -> args
                    is Map<*, *> -> {
                        val b64 = args["bodyBase64"] as? String
                        if (b64 != null) {
                            String(Base64.decode(b64, Base64.DEFAULT), Charsets.UTF_8)
                        } else {
                            args["body"] as? String
                        }
                    }
                    else -> null
                }
                if (body == null) {
                    Log.i(TAG, "humanHandleResponse: no body → false")
                    result.success("false")
                    return
                }
                Log.i(TAG, "humanHandleResponse → BD.handleResponse (body only on Android)")
                val handled = HumanSecurity.BD.handleResponse(body) { challengeResult: HSBotDefenderChallengeResult ->
                    val out =
                        if (challengeResult == HSBotDefenderChallengeResult.SOLVED) "solved" else "cancelled"
                    Log.i(TAG, "humanHandleResponse result: $out")
                    result.success(out)
                    null
                }
                if (!handled) {
                    Log.i(TAG, "humanHandleResponse → false (not handled)")
                    result.success("false")
                }
            } else {
                result.notImplemented()
            }
        }
    }
}
