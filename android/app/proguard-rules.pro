# Flutter
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Google Sign-In
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**

# Google APIs (googleapis)
-keep class com.google.api.** { *; }
-dontwarn com.google.api.**

# Google Play Core (referenced by Flutter deferred components)
-dontwarn com.google.android.play.core.**

# Gson (used internally by Google libs)
-keepattributes Signature
-keepattributes *Annotation*
-keep class sun.misc.Unsafe { *; }

# Flutter Secure Storage
-keep class com.it_nomads.fluttersecurestorage.** { *; }

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}
