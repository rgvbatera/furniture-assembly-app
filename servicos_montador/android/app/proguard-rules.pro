# Regras do ProGuard para o aplicativo Serviços Montador

# Flutter
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Manter classes do seu pacote
-keep class com.carminatti.servicos_montador.** { *; }

# Regras para plugins comuns
# SQLite
-keep class org.sqlite.** { *; }
-keep class org.sqlite.database.** { *; }

# PDF
-keep class com.tom_roush.pdfbox.** { *; }

# Ignorar dependências do Play Core (nós não estamos usando)
-dontwarn com.google.android.play.core.splitcompat.**
-dontwarn com.google.android.play.core.splitinstall.**
-dontwarn com.google.android.play.core.tasks.**