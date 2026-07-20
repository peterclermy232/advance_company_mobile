# Flutter's own engine/embedding classes are covered by Flutter's default
# consumer rules; the entries below cover this app's plugins that touch
# reflection, JNI, or native crash symbolication.

# Firebase Crashlytics needs stack traces to stay attributable to real files/lines.
-keepattributes SourceFile,LineNumberTable
-keep public class * extends java.lang.Exception

# local_auth: FragmentActivity + biometric prompt callbacks
-keep class androidx.biometric.** { *; }
-keep class io.flutter.plugins.localauth.** { *; }

# flutter_secure_storage: AndroidX Security crypto (EncryptedSharedPreferences)
-keep class androidx.security.crypto.** { *; }

# dio / okhttp — used via method channels & reflection for platform adapters
-keep class okhttp3.** { *; }
-keep interface okhttp3.** { *; }
-dontwarn okhttp3.**
-dontwarn okio.**

# Play-core deferred components (referenced by Flutter's engine even when unused)
-dontwarn com.google.android.play.core.**
