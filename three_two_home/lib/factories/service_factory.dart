// Abstract Factory pattern — creates families of related service objects
import '../services/auth_facade.dart';
import '../adapters/notification_adapter.dart';

abstract class ServiceFactory {
  AuthFacade createAuthFacade();
  NotificationService createNotificationService();
}

// Concrete factory for the production environment
class ProductionServiceFactory implements ServiceFactory {
  @override
  AuthFacade createAuthFacade() => AuthFacade.instance;

  @override
  NotificationService createNotificationService() =>
      LoggingNotificationDecorator(FlutterSnackBarAdapter());
}
