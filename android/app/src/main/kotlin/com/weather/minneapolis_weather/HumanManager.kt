package com.weather.minneapolis_weather

import android.app.Application
import com.humansecurity.mobile_sdk.HumanSecurity
import com.humansecurity.mobile_sdk.main.policy.HSPolicy
import com.humansecurity.mobile_sdk.main.policy.HSAutomaticInterceptorType
import com.humansecurity.mobile_sdk.main.HSBotDefenderChallengeResult
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import org.json.JSONObject

class HumanManager {

    companion object {
        private const val APP_ID = "<APPID>"

        fun start(application: Application) {
            try {
                val policy = HSPolicy()
                policy.automaticInterceptorPolicy.interceptorType = HSAutomaticInterceptorType.NONE
                HumanSecurity.start(application, APP_ID, policy)
            } catch (exception: Exception) {
                println("HumanSecurity start exception: ${exception.message}")
            }
        }

        fun handleEvent(call: MethodCall, result: MethodChannel.Result) {
            if (call.method == "humanGetHeaders") {
                try {
                    val headers = HumanSecurity.BD.headersForURLRequest(APP_ID)
                    val json = JSONObject(headers as Map<*, *>)
                    result.success(json.toString())
                } catch (e: Exception) {
                    result.success("{}")
                }
            } else if (call.method == "humanHandleResponse") {
                val body = when (val args = call.arguments) {
                    is String -> args
                    is Map<*, *> -> args["body"] as? String
                    else -> null
                }
                if (body == null) {
                    result.success("false")
                    return
                }
                val handled = HumanSecurity.BD.handleResponse(body) { challengeResult: HSBotDefenderChallengeResult ->
                    result.success(if (challengeResult == HSBotDefenderChallengeResult.SOLVED) "solved" else "cancelled")
                    null
                }
                if (!handled) {
                    result.success("false")
                }
            } else {
                result.notImplemented()
            }
        }
    }
}
