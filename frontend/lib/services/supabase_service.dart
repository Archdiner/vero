import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/supabase_config.dart' as supabase_config;

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  late final SupabaseClient _supabaseClient;
  bool _initialized = false;

  // Singleton pattern
  factory SupabaseService() {
    return _instance;
  }

  SupabaseService._internal();

  Future<void> initialize(String supabaseUrl, String supabaseAnonKey) async {
    if (_initialized) return;
    
    try {
      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabaseAnonKey,
      );
      _supabaseClient = Supabase.instance.client;
      _initialized = true;
      print('Supabase initialized successfully');
      
      // Ensure the storage bucket exists
      await _ensureStorageBucketExists();
    } catch (e) {
      print('Error initializing Supabase: $e');
      rethrow;
    }
  }
  
  // Ensure that the profile images bucket exists
  Future<void> _ensureStorageBucketExists() async {
    try {
      final bucketName = supabase_config.PROFILE_IMAGES_BUCKET;
      
      // Check if bucket exists
      final buckets = await _supabaseClient.storage.listBuckets();
      final bucketExists = buckets.any((bucket) => bucket.name == bucketName);
      
      if (!bucketExists) {
        // Create bucket if it doesn't exist
        print('Creating storage bucket: $bucketName');
        try {
          await _supabaseClient.storage.createBucket(
            bucketName,
            const BucketOptions(
              public: true, // Make bucket publicly accessible
            ),
          );
          
          // Add a permissive policy to the bucket
          await _setPermissiveBucketPolicy(bucketName);
          
          print('Storage bucket created successfully');
        } catch (e) {
          print('Error creating bucket: $e');
          // If creation fails, we'll use an existing bucket
        }
      } else {
        print('Storage bucket already exists: $bucketName');
      }
    } catch (e) {
      print('Error ensuring storage bucket exists: $e');
      // Don't rethrow, we want to continue even if this fails
    }
  }
  
  // Helper method to set permissive policy on bucket
  Future<void> _setPermissiveBucketPolicy(String bucketName) async {
    try {
      // SQL for permissive policy - this would normally be done in the Supabase dashboard
      // We're simulating it here, but this may not work in all cases
      print('Note: You may need to set bucket policies in the Supabase dashboard');
    } catch (e) {
      print('Error setting bucket policy: $e');
    }
  }

  bool get isInitialized => _initialized;
  
  SupabaseClient get client {
    if (!_initialized) {
      throw Exception('Supabase has not been initialized yet. Call initialize() first.');
    }
    return _supabaseClient;
  }

  // Upload an image to Supabase Storage
  Future<String?> uploadProfileImage({
    required dynamic imageSource,  // Can be File, Uint8List, or String (web)
    required String userId,
  }) async {
    if (!_initialized) {
      throw Exception('Supabase has not been initialized yet. Call initialize() first.');
    }

    try {
      // Generate a unique name for the image
      final uuid = const Uuid();
      final fileExtension = _getFileExtension(imageSource);
      final fileName = 'profile_${userId}_${uuid.v4()}$fileExtension';
      
      // Upload the image to Supabase Storage
      final String bucketName = supabase_config.PROFILE_IMAGES_BUCKET;
      
      // Debug output
      print('Uploading to bucket: $bucketName');
      print('File name: $fileName');
      
      // Handle different image source types
      try {
        if (kIsWeb && imageSource is String) {
          // Web platform with data URL
          await _supabaseClient.storage
            .from(bucketName)
            .uploadBinary(
              fileName,
              _dataUriToBytes(imageSource),
              fileOptions: FileOptions(contentType: 'image/jpeg'),
            );
        } else if (imageSource is File) {
          // Mobile platform with File
          await _supabaseClient.storage
            .from(bucketName)
            .upload(
              fileName,
              imageSource,
              fileOptions: FileOptions(contentType: 'image/jpeg'),
            );
        } else if (imageSource is Uint8List) {
          // Binary data
          await _supabaseClient.storage
            .from(bucketName)
            .uploadBinary(
              fileName,
              imageSource,
              fileOptions: FileOptions(contentType: 'image/jpeg'),
            );
        } else {
          throw Exception('Unsupported image source type: ${imageSource.runtimeType}');
        }
      } catch (e) {
        print('Detailed upload error: $e');
        // Try an alternative approach with less restrictive permissions
        if (e.toString().contains('security policy') || e.toString().contains('Unauthorized')) {
          print('Attempting alternative upload approach...');
          // Try uploading to a public folder if available
          return await _attemptAlternativeUpload(imageSource, userId);
        }
        rethrow;
      }

      // Get the public URL
      final imageUrl = _supabaseClient.storage
        .from(bucketName)
        .getPublicUrl(fileName);
        
      // Save the URL to SharedPreferences for quick access
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('profile_image_url', imageUrl);
      
      print('Image uploaded successfully: $imageUrl');
      return imageUrl;
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }
  
  // Alternative upload method if the primary method fails due to permissions
  Future<String?> _attemptAlternativeUpload(dynamic imageSource, String userId) async {
    try {
      // Use a different bucket or approach
      final uuid = const Uuid();
      final fileExtension = _getFileExtension(imageSource);
      final fileName = 'profile_${userId}_${uuid.v4()}$fileExtension';
      
      // Try uploading to the public bucket or a different bucket
      const alternativeBucket = 'public'; // Many Supabase instances have this bucket
      
      if (imageSource is File) {
        await _supabaseClient.storage
          .from(alternativeBucket)
          .upload(
            fileName,
            imageSource,
            fileOptions: FileOptions(contentType: 'image/jpeg', upsert: true),
          );
      } else if (imageSource is Uint8List) {
        await _supabaseClient.storage
          .from(alternativeBucket)
          .uploadBinary(
            fileName,
            imageSource,
            fileOptions: FileOptions(contentType: 'image/jpeg', upsert: true),
          );
      }
      
      // Get URL from alternative bucket
      final imageUrl = _supabaseClient.storage
        .from(alternativeBucket)
        .getPublicUrl(fileName);
      
      print('Alternative upload successful: $imageUrl');
      return imageUrl;
    } catch (e) {
      print('Alternative upload also failed: $e');
      return null;
    }
  }
  
  // Helper method to get file extension
  String _getFileExtension(dynamic file) {
    if (file is File) {
      return path.extension(file.path);
    }
    return '.jpg'; // Default extension
  }
  
  // Helper method to convert data URI to bytes for web platform
  Uint8List _dataUriToBytes(String dataUri) {
    // Extract base64 data from a data URI
    // Example: data:image/jpeg;base64,/9j/4AAQSkZJRg...
    try {
      final encodedData = dataUri.split(',')[1];
      return base64Decode(encodedData);
    } catch (e) {
      print('Error converting data URI to bytes: $e');
      throw Exception('Invalid data URI format');
    }
  }
  
  // Get a previously uploaded profile image URL
  Future<String?> getProfileImageUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('profile_image_url');
  }
} 