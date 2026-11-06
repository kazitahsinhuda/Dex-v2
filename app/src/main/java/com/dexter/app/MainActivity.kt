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
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.ArrowUpward
import androidx.compose.material.icons.filled.DeleteOutline
import androidx.compose.material.icons.filled.Menu
import androidx.compose.material.icons.filled.Mic
import androidx.compose.material.icons.filled.Tune
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

private val AppBg = Color(0xFF212121)
private val Panel = Color(0xFF2F2F2F)
private val UserBubble = Color(0xFF303030)
private val MainText = Color(0xFFECECEC)
private val MutedText = Color(0xFF9A9A9A)

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
    val messages = remember { mutableStateListOf(ChatMessage("Hey. I'm Dexter. What's on your mind?", false)) }
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
        val prompt = input.trim()
        if (prompt.isEmpty() || sending) return
        messages.add(ChatMessage(prompt, true))
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
        background = AppBg, surface = AppBg, surfaceVariant = Panel,
        primary = Color(0xFFECECEC), onBackground = MainText, onSurface = MainText
    )) {
        Scaffold(
            containerColor = AppBg,
            topBar = {
                TopAppBar(
                    title = {
                        Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(9.dp)) {
                            Text("Dexter", fontSize = 18.sp, color = MainText)
                            Text("▾", color = MutedText, fontSize = 15.sp)
                        }
                    },
                    navigationIcon = {
                        IconButton(onClick = { menu = true }) {
                            Icon(Icons.Default.Menu, contentDescription = "Menu", tint = MainText)
                        }
                    },
                    actions = {
                        IconButton(onClick = {
                            messages.clear()
                            messages.add(ChatMessage("New chat. I'm listening.", false))
                        }) {
                            Icon(Icons.Default.Add, contentDescription = "New chat", tint = MainText)
                        }
                    },
                    colors = TopAppBarDefaults.topAppBarColors(containerColor = AppBg)
                )
            },
            bottomBar = {
                Column(Modifier.fillMaxWidth().background(AppBg).padding(horizontal = 12.dp, vertical = 8.dp)) {
                    Row(
                        modifier = Modifier.fillMaxWidth()
                            .background(Panel, RoundedCornerShape(28.dp))
                            .padding(horizontal = 8.dp, vertical = 7.dp),
                        verticalAlignment = Alignment.Bottom
                    ) {
                        Box {
                            IconButton(onClick = { menu = true }) {
                                Icon(Icons.Default.Add, contentDescription = "More options", tint = MainText)
                            }
                        }
                        BasicTextField(
                            value = input,
                            onValueChange = { input = it },
                            modifier = Modifier.weight(1f).padding(horizontal = 8.dp, vertical = 13.dp),
                            textStyle = TextStyle(color = MainText, fontSize = 16.sp),
                            cursorBrush = androidx.compose.ui.graphics.SolidColor(MainText),
                            decorationBox = { inner ->
                                if (input.isEmpty()) Text("Message Dexter", color = MutedText, fontSize = 16.sp)
                                inner()
                            }
                        )
                        IconButton(onClick = {
                            val intent = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
                                putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL, RecognizerIntent.LANGUAGE_MODEL_FREE_FORM)
                                putExtra(RecognizerIntent.EXTRA_LANGUAGE, Locale.getDefault())
                            }
                            runCatching { speechLauncher.launch(intent) }
                        }) {
                            Icon(Icons.Default.Mic, contentDescription = "Voice input", tint = MainText)
                        }
                        IconButton(
                            onClick = { sendMessage() },
                            enabled = input.isNotBlank() && !sending,
                            modifier = Modifier.size(42.dp).background(
                                if (input.isNotBlank() && !sending) Color.White else Color(0xFF555555),
                                CircleShape
                            )
                        ) {
                            Icon(Icons.Default.ArrowUpward, contentDescription = "Send", tint = Color(0xFF171717))
                        }
                    }
                    Text(
                        "Dexter can make mistakes. Check important information.",
                        modifier = Modifier.fillMaxWidth().padding(top = 7.dp),
                        color = MutedText, fontSize = 10.sp,
                        textAlign = androidx.compose.ui.text.style.TextAlign.Center
                    )
                }
            }
        ) { padding ->
            Box(Modifier.fillMaxSize().padding(padding)) {
                if (messages.size == 1 && !messages[0].fromUser) {
                    Column(
                        Modifier.fillMaxSize().padding(horizontal = 28.dp),
                        verticalArrangement = Arrangement.Center,
                        horizontalAlignment = Alignment.CenterHorizontally
                    ) {
                        Text("D", color = MainText, fontSize = 34.sp,
                            modifier = Modifier.background(Panel, CircleShape).padding(18.dp))
                        Spacer(Modifier.height(18.dp))
                        Text("What can I help with?", color = MainText, fontSize = 23.sp)
                        Spacer(Modifier.height(8.dp))
                        Text("Chat, learn, plan, or challenge an idea.", color = MutedText, fontSize = 14.sp)
                    }
                }
                LazyColumn(
                    modifier = Modifier.fillMaxSize().padding(horizontal = 16.dp),
                    state = listState,
                    contentPadding = PaddingValues(top = 18.dp, bottom = 18.dp),
                    verticalArrangement = Arrangement.spacedBy(22.dp)
                ) {
                    items(messages) { msg ->
                        if (msg.fromUser) {
                            Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.End) {
                                Text(
                                    msg.text,
                                    modifier = Modifier.widthIn(max = 300.dp)
                                        .background(UserBubble, RoundedCornerShape(22.dp))
                                        .padding(horizontal = 16.dp, vertical = 12.dp),
                                    color = MainText, fontSize = 15.sp, lineHeight = 22.sp
                                )
                            }
                        } else {
                            Row(Modifier.fillMaxWidth(), verticalAlignment = Alignment.Top) {
                                Text(
                                    "D",
                                    modifier = Modifier.padding(end = 11.dp)
                                        .background(Panel, CircleShape).padding(horizontal = 9.dp, vertical = 6.dp),
                                    color = MainText, fontSize = 13.sp
                                )
                                Text(
                                    msg.text,
                                    modifier = Modifier.weight(1f).padding(top = 4.dp),
                                    color = MainText, fontSize = 15.sp, lineHeight = 23.sp
                                )
                            }
                        }
                    }
                    if (sending) item {
                        Text("Dexter is thinking…", color = MutedText, fontSize = 13.sp,
                            modifier = Modifier.padding(start = 42.dp))
                    }
                }
                LaunchedEffect(messages.size) {
                    if (messages.isNotEmpty()) listState.animateScrollToItem(messages.lastIndex)
                }
                DropdownMenu(expanded = menu, onDismissRequest = { menu = false }) {
                    DropdownMenuItem(
                        text = { Text("New chat") },
                        leadingIcon = { Icon(Icons.Default.Add, null) },
                        onClick = {
                            messages.clear()
                            messages.add(ChatMessage("New chat. What's on your mind?", false))
                            menu = false
                        }
                    )
                    DropdownMenuItem(
                        text = { Text("Clear conversation") },
                        leadingIcon = { Icon(Icons.Default.DeleteOutline, null) },
                        onClick = {
                            messages.clear()
                            messages.add(ChatMessage("Conversation cleared.", false))
                            menu = false
                        }
                    )
                    DropdownMenuItem(
                        text = { Text("Mode: $mode") },
                        leadingIcon = { Icon(Icons.Default.Tune, null) },
                        onClick = { mode = when (mode) {
                            "Companion" -> "Teaching"
                            "Teaching" -> "Sparring"
                            else -> "Companion"
                        }; menu = false }
                    )
                }
            }
        }
    }
}
