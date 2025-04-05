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
      
      // Skip bucket creation entirely - it's not necessary for startup
      // The bucket should be created by the backend team
    } catch (e) {
      print('Error initializing Supabase: $e');
      // Don't rethrow, allow app to continue even if Supabase fails
      // This prevents app from crashing if there's no internet
    }
  }
  
  // Only call this method when actually uploading an image
  Future<void> ensureBucketExists() async {
    if (!_initialized) return;
    
    try {
      final bucketName = supabase_config.PROFILE_IMAGES_BUCKET;
      
      // Check if bucket exists
      final buckets = await _supabaseClient.storage.listBuckets();
      final bucketExists = buckets.any((bucket) => bucket.name == bucketName);
      
      if (!bucketExists) {
        // Create bucket if it doesn't exist
        print('Creating storage bucket: $bucketName');
        await _supabaseClient.storage.createBucket(
          bucketName,
          const BucketOptions(
            public: true, // Make bucket publicly accessible
          ),
        );
        print('Storage bucket created successfully');
      } else {
        print('Storage bucket already exists: $bucketName');
      }
    } catch (e) {
      print('Error ensuring storage bucket exists: $e');
      // Don't rethrow, we want to continue even if this fails
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
      print('Supabase not initialized, skipping upload');
      return null;
    }

    try {
      print('Starting image upload to Supabase...');
      
      // Ensure bucket exists before upload
      await ensureBucketExists();
      
      // Generate a unique name for the image
      final uuid = const Uuid();
      final fileExtension = _getFileExtension(imageSource);
      final fileName = 'profile_${userId}_${uuid.v4()}$fileExtension';
      
      print('Generated filename: $fileName');
      
      // Upload the image to Supabase Storage
      final String bucketName = supabase_config.PROFILE_IMAGES_BUCKET;
      print('Uploading to bucket: $bucketName');
      
      // Handle different image source types
      if (kIsWeb && imageSource is String) {
        // Web platform with data URL
        print('Uploading web image (data URL)...');
        await _supabaseClient.storage
          .from(bucketName)
          .uploadBinary(
            fileName,
            _dataUriToBytes(imageSource),
            fileOptions: FileOptions(contentType: 'image/jpeg', cacheControl: '3600'),
          );
      } else if (imageSource is File) {
        // Mobile platform with File
        print('Uploading mobile file image...');
        await _supabaseClient.storage
          .from(bucketName)
          .upload(
            fileName,
            imageSource,
            fileOptions: FileOptions(contentType: 'image/jpeg', cacheControl: '3600'),
          );
      } else if (imageSource is Uint8List) {
        // Binary data
        print('Uploading binary image data...');
        await _supabaseClient.storage
          .from(bucketName)
          .uploadBinary(
            fileName,
            imageSource,
            fileOptions: FileOptions(contentType: 'image/jpeg', cacheControl: '3600'),
          );
      } else {
        throw Exception('Unsupported image source type');
      }

      // Get the public URL
      final imageUrl = _supabaseClient.storage
        .from(bucketName)
        .getPublicUrl(fileName);
      
      print('Image uploaded successfully. Public URL: $imageUrl');
        
      // Save the URL to SharedPreferences for quick access
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('profile_image_url', imageUrl);
      
      return imageUrl;
    } catch (e) {
      print('Error uploading image: $e');
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