# Add project specific ProGuard rules here.
# You can control the set of applied configuration files using the
# proguardFiles setting in build.gradle.
#
# For more details, see
#   http://developer.android.com/guide/developing/tools/proguard.html

# If your project uses WebView with JS, uncomment the following
# and specify the fully qualified class name to the JavaScript interface
# class:
#-keepclassmembers class fqcn.of.javascript.interface.for.webview {
#   public *;
#}

# Uncomment this to preserve the line number information for
# debugging stack traces.
#-keepattributes SourceFile,LineNumberTable

# If you keep the line number information, uncomment this to
# hide the original source file name.
#-renamesourcefileattribute SourceFile

# Flutter specific rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Keep native methods
-keepclassmembers class * {
    native <methods>;
}

# Keep Gson classes if using Gson
-keepattributes Signature
-keepattributes *Annotation*
-keep class sun.misc.Unsafe { *; }
-keep class com.google.gson.** { *; }

# Keep HTTP classes
-keep class okhttp3.** { *; }
-keep class retrofit2.** { *; }

# Keep Google Play Services
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**

# Keep Google Play Core
-keep class com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**

# Keep location services
-keep class com.google.android.gms.location.** { *; }
-keep class com.google.android.gms.maps.** { *; }

# Keep secure storage classes
-keep class com.it_nomads.fluttersecurestorage.** { *; }

# Keep permission handler classes
-keep class com.baseflow.permissionhandler.** { *; }

# Keep URL launcher classes
-keep class io.flutter.plugins.urllauncher.** { *; }

# Keep share plus classes
-keep class dev.fluttercommunity.plus.share.** { *; }

# Keep package info plus classes
-keep class io.flutter.plugins.packageinfo.** { *; }

# Keep geolocator classes
-keep class com.baseflow.geolocator.** { *; }

# Keep geocoding classes
-keep class com.baseflow.geocoding.** { *; }

# Keep path provider classes
-keep class io.flutter.plugins.pathprovider.** { *; }

# Prevent obfuscation of model classes (if you have any)
-keep class com.example.eazystaff.models.** { *; }

# Keep serialization annotations
-keepattributes *Annotation*,Signature,Exception
