class BalanceModel {

  String? parcelsAsCourier;
  String? parcelsAsSender;
  String? servicePrice;
  String? serviceParcelPriceSender;
  String? serviceParcelPriceCourier;
  String? ourShare;
  String? cardDebt;
  String? depositDebt;

  BalanceModel({
    this.parcelsAsCourier, this.parcelsAsSender, this.servicePrice, this.serviceParcelPriceSender,this. serviceParcelPriceCourier, this.ourShare, this.cardDebt, this.depositDebt
  });


  void updateBalanceModel(var body) {

    if (body == null) {
      return;
    }
    if (body.containsKey("parcelsAsCourier")) {
      this.parcelsAsCourier = body["parcelsAsCourier"];
    }
    if (body.containsKey("parcelsAsSender")) {
      this.parcelsAsSender = body["parcelsAsSender"];
    }
    if (body.containsKey("servicePrice")) {
      this.servicePrice = body["servicePrice"];
    }
    if (body.containsKey("serviceParcelPriceSender")) {
      this.serviceParcelPriceSender = body["serviceParcelPriceSender"];
    }
    if (body.containsKey("serviceParcelPriceCourier")) {
      this.serviceParcelPriceCourier = body["serviceParcelPriceCourier"];
    }
    if (body.containsKey("ourShare")) {
      this.ourShare = body["ourShare"];
    }
    if (body.containsKey("cardDebt")) {
      this.cardDebt = body["cardDebt"];
    }
    if (body.containsKey("depositDebt")) {
      this.depositDebt = body["depositDebt"];
    }
  }
}