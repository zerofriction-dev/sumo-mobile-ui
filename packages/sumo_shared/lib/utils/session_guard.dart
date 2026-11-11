class SessionGuard {
  SessionGuard._();

  static bool expiredInProgress = false;
}

enum SessionEndReason { expired, replaced }
