package com.dexter.app

import android.content.Intent
import android.os.Bundle
import android.speech.RecognizerIntent
import android.speech.tts.TextToSpeech
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Mic
import androidx.compose.material.icons.filled.Send
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import kotlinx.coroutines.launch
import java.util.Locale

private data class ChatMessage(val text: String, val fromUser: Boolean)

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent { DexterScreen() }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun DexterScreen() {
    val context = androidx.compose.ui.platform.LocalContext.current
    val messages = remember { mutableStateListOf(ChatMessage("Hey. I'm Dexter.", false)) }
    var input by remember { mutableStateOf("") }
    var mode by remember { mutableStateOf("Companion") }
    var sending by remember { mutableStateOf(false) }
    var menu by remember { mutableStateOf(false) }
    var voiceReply by remember { mutableStateOf(false) }
    val scope = rememberCoroutineScope()
    val listState = rememberLazyListState()
    var tts by remember { mutableStateOf<TextToSpeech?>(null) }

    DisposableEffect(Unit) {
        val engine = TextToSpeech(context) { status ->
            if (status == TextToSpeech.SUCCESS) tts?.language = Locale.US
        }
        tts = engine
        onDispose { engine.stop(); engine.shutdown() }
    }

    val speechLauncher = rememberLauncherForActivityResult(ActivityResultContracts.StartActivityForResult()) { result ->
        val spoken = result.data?.getStringArrayListExtra(RecognizerIntent.EXTRA_RESULTS)?.firstOrNull()
        if (!spoken.isNullOrBlank()) {
            input = spoken
            voiceReply = true
        }
    }

    fun sendMessage() {
        val text = input.trim()
        if (text.isEmpty() || sending) return
        messages.add(ChatMessage(text, true))
        input = ""
        sending = true
        scope.launch {
            try {
                val history = messages.map { (if (it.fromUser) "user" else "assistant") to it.text }
                val answer = GeminiClient.reply(history, mode)
                messages.add(ChatMessage(answer, false))
                if (voiceReply) tts?.speak(answer, TextToSpeech.QUEUE_FLUSH, null, "dexter-reply")
            } catch (e: Exception) {
                messages.add(ChatMessage(e.message ?: "Something went wrong.", false))
            } finally {
                sending = false
                voiceReply = false
            }
        }
    }

    MaterialTheme(colorScheme = darkColorScheme(
        background = Color(0xFF101114),
        surface = Color(0xFF191B20),
        primary = Color(0xFFB6C7FF),
        onBackground = Color(0xFFF1F0F7),
        onSurface = Color(0xFFF1F0F7)
    )) {
        Scaffold(
            containerColor = Color(0xFF101114),
            topBar = {
                TopAppBar(
                    title = {
                        Column {
                            Text("DEXTER", fontSize = 17.sp)
                            Text(mode, fontSize = 11.sp, color = Color.LightGray)
                        }
                    },
                    actions = {
                        Box {
                            TextButton(onClick = { menu = true }) { Text("Mode") }
                            DropdownMenu(expanded = menu, onDismissRequest = { menu = false }) {
                                listOf("Companion", "Teaching", "Sparring").forEach { option ->
                                    DropdownMenuItem(text = { Text(option) }, onClick = {
                                        mode = option
                                        menu = false
                                    })
                                }
                            }
                        }
                    },
                    colors = TopAppBarDefaults.topAppBarColors(containerColor = Color(0xFF101114))
                )
            },
            bottomBar = {
                Row(
                    Modifier.fillMaxWidth().background(Color(0xFF191B20)).padding(horizontal = 10.dp, vertical = 9.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    IconButton(onClick = { menu = true }) { Icon(Icons.Default.Add, "More") }
                    BasicTextField(
                        value = input,
                        onValueChange = { input = it },
                        modifier = Modifier.weight(1f).padding(horizontal = 8.dp)
                            .background(Color(0xFF282B32), RoundedCornerShape(22.dp))
                            .padding(horizontal = 16.dp, vertical = 13.dp),
                        textStyle = TextStyle(color = Color.White, fontSize = 15.sp),
                        cursorBrush = androidx.compose.ui.graphics.SolidColor(Color.White),
                        decorationBox = { inner ->
                            if (input.isEmpty()) Text("Message Dexter...", color = Color.Gray)
                            inner()
                        }
                    )
                    IconButton(onClick = {
                        val intent = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
                            putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL, RecognizerIntent.LANGUAGE_MODEL_FREE_FORM)
                            putExtra(RecognizerIntent.EXTRA_LANGUAGE, Locale.getDefault())
                        }
                        runCatching { speechLauncher.launch(intent) }
                    }) { Icon(Icons.Default.Mic, "Voice input") }
                    IconButton(onClick = { sendMessage() }, enabled = !sending) {
                        Icon(Icons.Default.Send, "Send", tint = if (sending) Color.Gray else Color(0xFFB6C7FF))
                    }
                }
            }
        ) { padding ->
            LazyColumn(
                modifier = Modifier.fillMaxSize().padding(padding).padding(horizontal = 14.dp),
                state = listState,
                contentPadding = PaddingValues(vertical = 16.dp),
                verticalArrangement = Arrangement.spacedBy(10.dp)
            ) {
                items(messages) { msg ->
                    Row(
                        Modifier.fillMaxWidth(),
                        horizontalArrangement = if (msg.fromUser) Arrangement.End else Arrangement.Start
                    ) {
                        Text(
                            msg.text,
                            modifier = Modifier.widthIn(max = 310.dp)
                                .background(
                                    if (msg.fromUser) Color(0xFF303846) else Color(0xFF1C1F25),
                                    RoundedCornerShape(18.dp)
                                )
                                .padding(horizontal = 14.dp, vertical = 11.dp),
                            color = Color(0xFFF2F2F5),
                            fontSize = 15.sp
                        )
                    }
                }
                if (sending) item { Text("Dexter is thinking…", color = Color.Gray, fontSize = 12.sp) }
            }
            LaunchedEffect(messages.size) {
                listState.animateScrollToItem(messages.lastIndex.coerceAtLeast(0))
            }
        }
    }
}
