class Debts {
  Debts({
    this.debtId,
    this.userId,
    this.jobId,
    this.parcelId,
    this.cardDebt,
    this.depositDebt,
    this.paid,
    this.addDate,
  });

  factory Debts.fromJson(Map<String, dynamic> json) =>
      Debts(
        debtId: json['debtId'],
        userId: json['userId'],
        jobId: json['jobId'],
        parcelId: json['parcelId'],
        cardDebt: json['cardDebt'],
        depositDebt: json['depositDebt'],
        paid: json['paid'],
        addDate: json['addDate'],
      );

  final int? debtId;
  final int? userId;
  final int? jobId;
  final int? parcelId;
  final double? cardDebt;
  final double? depositDebt;
  final bool? paid;
  final String? addDate;

}