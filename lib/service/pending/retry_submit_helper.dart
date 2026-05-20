typedef RetryProgressCallback = void Function(int attempt, int maxRetry);

class RetrySubmitHelper {
  static Future<bool> run({
    required Future<bool> Function() action,
    required int maxRetry,
    required Duration retryDelay,
    RetryProgressCallback? onProgress,
  }) async {
    for (int attempt = 1; attempt <= maxRetry; attempt++) {
      onProgress?.call(attempt, maxRetry);

      try {
        final ok = await action();
        if (ok) return true;
      } catch (_) {}

      if (attempt < maxRetry) {
        await Future.delayed(retryDelay);
      }
    }

    return false;
  }
}
