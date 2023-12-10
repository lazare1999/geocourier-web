class ParcelAndOrdersInfoModel {

  String? todayParcels;
  String? inActiveParcels;
  String? parcelsWithOutJob;
  String? madeParcels;
  String? activeParcels;
  String? allParcels;

  String? todayJobs;
  String? activeJobs;
  String? onHoldJobs;
  String? doneJobs;
  String? allJobs;

  ParcelAndOrdersInfoModel({
    this.todayParcels, this.inActiveParcels, this.parcelsWithOutJob, this.madeParcels, this.activeParcels,
    this.allParcels, this.todayJobs, this.activeJobs, this.onHoldJobs, this.doneJobs, this.allJobs
  });


  void updateParcelAndOrdersInfo(var body) {

    if (body == null) {
      return;
    }
    if (body.containsKey("todayParcels")) {
      this.todayParcels = body["todayParcels"];
    }
    if (body.containsKey("inActiveParcels")) {
      this.inActiveParcels = body["inActiveParcels"];
    }
    if (body.containsKey("parcelsWithOutJob")) {
      this.parcelsWithOutJob = body["parcelsWithOutJob"];
    }
    if (body.containsKey("madeParcels")) {
      this.madeParcels = body["madeParcels"];
    }
    if (body.containsKey("activeParcels")) {
      this.activeParcels = body["activeParcels"];
    }
    if (body.containsKey("allParcels")) {
      this.allParcels = body["allParcels"];
    }
    if (body.containsKey("todayJobs")) {
      this.todayJobs = body["todayJobs"];
    }
    if (body.containsKey("activeJobs")) {
      this.activeJobs = body["activeJobs"];
    }
    if (body.containsKey("onHoldJobs")) {
      this.onHoldJobs = body["onHoldJobs"];
    }
    if (body.containsKey("doneJobs")) {
      this.doneJobs = body["doneJobs"];
    }
    if (body.containsKey("allJobs")) {
      this.allJobs = body["allJobs"];
    }
  }
}