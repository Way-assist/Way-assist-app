class WrongCredentials implements Exception {}

class InvalidToken implements Exception {}

class ConnectionTimeOut implements Exception {}

class CustomFavoriteError implements Exception {
  final String message;
  final int errorCode;

  CustomFavoriteError(this.message, {this.errorCode = 0});
}
