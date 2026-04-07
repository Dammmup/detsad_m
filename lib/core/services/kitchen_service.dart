import '../constants/api_constants.dart';
import '../../models/menu_model.dart';
import '../utils/logger.dart';
import 'api_service.dart';

class KitchenService {
  final ApiService _apiService = ApiService();

  Future<DailyMenu?> getTodayMenu() async {
    try {
      final response = await _apiService.get(ApiConstants.dailyMenuToday);
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
      final response = await _apiService.post(
        ApiConstants.dailyMenuServe(menuId, mealType),
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
      final response = await _apiService.post(ApiConstants.dailyMenuCancel(menuId, mealType));
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
