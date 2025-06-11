enum FriendRequestStatus {
  sent,
  received,
  none;

  static FriendRequestStatus fromString(String? status) {
    switch (status?.toLowerCase()) {
      case 'sent':
        return FriendRequestStatus.sent;
      case 'received':
        return FriendRequestStatus.received;
      default:
        return FriendRequestStatus.none;
    }
  }

  bool get isSent => this == FriendRequestStatus.sent;
  bool get isReceived => this == FriendRequestStatus.received;
  bool get isNone => this == FriendRequestStatus.none;
} 