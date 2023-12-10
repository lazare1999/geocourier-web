class UserCards {
  UserCards({
    this.userId,
    this.cardNumber,
    this.validThru,
    this.cardHolder,
    this.cvv,
  });

  factory UserCards.fromJson(Map<String, dynamic> json) =>
      UserCards(
        userId: json['userId'],
        cardNumber: json['cardNumber'],
        validThru: json['validThru'],
        cardHolder: json['cardHolder'],
        cvv: json['cvv']
      );

  final int? userId;
  final String? cardNumber;
  final String? validThru;
  final String? cardHolder;
  final String? cvv;

}