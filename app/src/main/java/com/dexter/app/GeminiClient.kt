package com.dexter.app

import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.RequestBody.Companion.toRequestBody
import org.json.JSONArray
import org.json.JSONObject
import java.util.concurrent.TimeUnit

object GeminiClient {
    private val http = OkHttpClient.Builder()
        .connectTimeout(20, TimeUnit.SECONDS)
        .readTimeout(60, TimeUnit.SECONDS)
        .build()

    suspend fun reply(history: List<Pair<String, String>>, mode: String): String = withContext(Dispatchers.IO) {
        val key = BuildConfig.GEMINI_API_KEY
        require(key.isNotBlank()) { "Gemini API key is missing. Add the GitHub Actions secret named Dexv2api." }

        val contents = JSONArray()
        history.takeLast(24).forEach { (role, text) ->
            contents.put(JSONObject()
                .put("role", if (role == "assistant") "model" else "user")
                .put("parts", JSONArray().put(JSONObject().put("text", text))))
        }

        val instruction = when (mode) {
            "Teaching" -> "You are Dexter, a patient but demanding tutor. Explain step by step, ask the learner to reason, check understanding, and correct mistakes clearly."
            "Sparring" -> "You are Dexter, an intellectual sparring partner. Challenge assumptions, test reasoning, offer counterarguments, and prioritize truth over agreement."
            else -> "You are Dexter, a natural, witty, friendly male AI companion. Speak casually and concisely. Avoid over-the-top hype, filler, and unnecessary follow-up questions. Never pretend to perform actions you cannot perform."
        }

        val body = JSONObject()
            .put("system_instruction", JSONObject().put("parts", JSONArray().put(JSONObject().put("text", instruction))))
            .put("contents", contents)
            .put("generationConfig", JSONObject().put("temperature", 0.85).put("maxOutputTokens", 1024))
            .toString()

        val url = "https://generativelanguage.googleapis.com/v1beta/models/" + BuildConfig.GEMINI_MODEL + ":generateContent"
        val request = Request.Builder().url(url)
            .header("x-goog-api-key", key)
            .post(body.toRequestBody("application/json; charset=utf-8".toMediaType()))
            .build()

        http.newCall(request).execute().use { response ->
            val raw = response.body?.string().orEmpty()
            if (!response.isSuccessful) {
                val message = runCatching {
                    JSONObject(raw).optJSONObject("error")?.optString("message")
                }.getOrNull().orEmpty()
                throw IllegalStateException("HTTP " + response.code + ": " + message.ifBlank { raw.take(400) })
            }
            val json = JSONObject(raw)
            json.optJSONArray("candidates")?.optJSONObject(0)
                ?.optJSONObject("content")?.optJSONArray("parts")
                ?.optJSONObject(0)?.optString("text")
                ?.takeIf { it.isNotBlank() }
                ?: throw IllegalStateException("Gemini returned an empty response.")
        }
    }
}
