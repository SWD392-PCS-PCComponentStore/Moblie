class ApiConstants {
  // Đổi thành URL server thật khi deploy
  // Khi chạy trên Chrome/emulator dùng localhost
  // Khi chạy trên điện thoại thật dùng IP máy tính (vd: http://192.168.1.x:5000)
  static const String baseUrl = 'https://pccomponentstore-cne8dndef4f0gthx.southeastasia-01.azurewebsites.net/api';

  // Auth
  static const String register = '/auth/register';
  static const String login = '/auth/login';

  // Users
  static const String users = '/users';
  static String userById(String id) => '/users/$id';

  // Categories
  static const String categories = '/categories';
  static String categoryById(String id) => '/categories/$id';

  // Products
  static const String products = '/products';
  static String productById(String id) => '/products/$id';
  static String productsByCategory(String categoryId) =>
      '/products/category/$categoryId';

  // Cart
  static String cart(String userId) => '/cart/$userId';
  static String cartTotal(String userId) => '/cart/$userId/total';
  static String cartAdd(String userId) => '/cart/$userId/add';
  static String cartUpdate(String cartId) => '/cart/$cartId/update';
  static String cartRemove(String cartId) => '/cart/$cartId/remove';
  static String cartClear(String userId) => '/cart/$userId/clear';

  // Orders
  static const String orders = '/orders';
  static const String myOrders = '/orders/me';
  static String orderById(String id) => '/orders/$id';

  // Checkout
  static const String checkout = '/checkout';

  // Promotions
  static const String promotions = '/promotions';
  static String promotionByCode(String code) => '/promotions/code/$code';

  // PC Builds
  static const String pcBuilds = '/pc-builds';
  static String pcBuildById(String id) => '/pc-builds/$id';

  // AI
  static const String aiBuild = '/ai/build';
  static const String aiRecommendations = '/ai/recommendations';
}
