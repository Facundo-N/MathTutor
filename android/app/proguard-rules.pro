# =============================
# Google ML Kit - Text Recognition
# =============================
-keep class com.google.mlkit.** { *; }
-keep class com.google.android.gms.internal.mlkit_vision_text_common.** { *; }
-dontwarn com.google.mlkit.**

# =============================
# Flutter & Dart runtime
# =============================
-keep class io.flutter.** { *; }
-keep class io.flutter.plugin.** { *; }
-dontwarn io.flutter.embedding.**

# =============================
# Speech to Text (speech_to_text)
# =============================
-keep class com.csdcorp.speech_to_text.** { *; }
-dontwarn com.csdcorp.speech_to_text.**

# =============================
# Flutter TTS
# =============================
-keep class com.tundralabs.fluttertts.** { *; }
-dontwarn com.tundralabs.fluttertts.**

# =============================
# Image Picker
# =============================
-keep class io.flutter.plugins.imagepicker.** { *; }
-dontwarn io.flutter.plugins.imagepicker.**

# =============================
# just_audio
# =============================
-keep class com.ryanheise.just_audio.** { *; }
-dontwarn com.ryanheise.just_audio.**

# =============================
# General - keep annotations & reflection
# =============================
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes InnerClasses
-keepattributes EnclosingMethod

# Keep all native JNI methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Suppress notes about missing references in external libraries
-dontnote **
