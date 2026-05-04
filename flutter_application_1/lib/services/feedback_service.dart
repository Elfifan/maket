import 'package:flutter/foundation.dart';
import '../models/feedback_model.dart';
import 'supabase_service.dart';

class FeedbackService {
  /// Получить отзывы курса
  static Future<List<FeedbackModel>> getCourseFeedbacks(int courseId) async {
    try {
      final supabase = SupabaseService();
      
      final response = await supabase.client
          .from('feedback')
          .select('*, users(name, email)')
          .eq('id_courses', courseId)
          .eq('status', true)
          .order('id', ascending: false);

      return List<Map<String, dynamic>>.from(response)
          .map((json) => FeedbackModel.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Error loading feedbacks: $e');
      return [];
    }
  }

  /// Добавить отзыв
  static Future<bool> addFeedback({
    required int userId,
    required int courseId,
    required double rating,
    required String description,
  }) async {
    try {
      final supabase = SupabaseService();
      await supabase.initialize();
      
      await supabase.client.from('feedback').insert({
        'id_user': userId,
        'id_courses': courseId,
        'estimation': rating,
        'description': description,
        'status': true,
      });
      return true;
    } catch (e) {
      debugPrint('Error adding feedback: $e');
      return false;
    }
  }

  /// Проверить, оставлял ли пользователь отзыв
  static Future<bool> hasUserFeedback(int userId, int courseId) async {
    try {
      final supabase = SupabaseService();
      await supabase.initialize();
      
      final response = await supabase.client
          .from('feedback')
          .select('id')
          .eq('id_user', userId)
          .eq('id_courses', courseId)
          .maybeSingle();
      return response != null;
    } catch (e) {
      return false;
    }
  }

  /// Получить средний рейтинг
  static Future<double> getAverageRating(int courseId) async {
    try {
      final supabase = SupabaseService();
      await supabase.initialize();
      
      final response = await supabase.client
          .from('feedback')
          .select('estimation')
          .eq('id_courses', courseId)
          .eq('status', true);

      if (response.isEmpty) return 0.0;

      double sum = 0;
      for (var item in response) {
        sum += (item['estimation'] as num).toDouble();
      }
      return sum / response.length;
    } catch (e) {
      return 0.0;
    }
  }
}