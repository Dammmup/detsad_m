import 'package:dio/dio.dart';
import '../constants/api_constants.dart';
import '../../models/menu_model.dart';
import '../utils/logger.dart';

class KitchenService {
  final Dio _dio = Dio(BaseOptions(baseUrl: ApiConstants.baseUrl));

  Future<DailyMenu?> getTodayMenu() async {
    try {
      final response = await _dio.get('/daily-menu/today');
      if (response.statusCode == 200 && response.data != null) {
        return DailyMenu.fromJson(response.data);
      }
      return null;
    } catch (e) {
      AppLogger.error('KitchenService | Error fetching today menu: $e');
      return null;
    }
  }

  Future<DailyMenu?> serveMeal(String menuId, String mealType, int childCount) async {
    try {
      final response = await _dio.post(
        '/daily-menu/$menuId/serve/$mealType',
        data: {'childCount': childCount},
      );

      if (response.statusCode == 200) {
        return DailyMenu.fromJson(response.data);
      }
      return null;
    } catch (e) {
      AppLogger.error('KitchenService | Error serving meal $mealType: $e');
      rethrow;
    }
  }

  Future<DailyMenu?> cancelMeal(String menuId, String mealType) async {
    try {
      final response = await _dio.post('/daily-menu/$menuId/cancel/$mealType');
      if (response.statusCode == 200) {
        return DailyMenu.fromJson(response.data);
      }
      return null;
    } catch (e) {
      AppLogger.error('KitchenService | Error cancelling meal $mealType: $e');
      rethrow;
    }
  }
}
