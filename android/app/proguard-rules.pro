# === Flutter / R8 Fix ===
-dontwarn com.google.errorprone.annotations.**
-dontwarn javax.annotation.**
-dontwarn javax.annotation.concurrent.**

# Keep url_launcher plugin
-keep class io.flutter.plugins.urllauncher.** { *; }
-keep class io.flutter.plugins.** { *; }

