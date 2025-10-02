class Project {
  final int? id;
  final String projectName;
  final String companyName;
  final String companyAddress;
  final String projectType;
  final List<Specification> specifications;
  final List<Rfi> rfis;
  final String? status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Project({
    this.id,
    required this.projectName,
    required this.companyName,
    required this.companyAddress,
    required this.projectType,
    this.specifications = const [],
    this.rfis = const [],
    this.status,
    this.createdAt,
    this.updatedAt,
  });

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: json['project_id'] ?? json['id'],
      projectName: json['project_name'] ?? json['projectName'] ?? '',
      companyName: json['company_name'] ?? json['companyName'] ?? '',
      companyAddress: json['company_address'] ?? json['companyAddress'] ?? '',
      projectType: json['project_type'] ?? json['projectType'] ?? '',
      specifications: (json['specifications'] as List<dynamic>?)
          ?.map((spec) => Specification.fromJson(spec))
          .toList() ?? [],
      rfis: (json['rfis'] as List<dynamic>?)
          ?.map((rfi) => Rfi.fromJson(rfi))
          .toList() ?? [],
      status: json['project_status'] ?? json['status'],
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : null,
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    final json = {
      'id': id,
      'project_name': projectName,
      'company_name': companyName,
      'company_address': companyAddress,
      'project_type': projectType,
      'specifications': specifications.map((spec) => spec.toJson()).toList(),
      'status': status,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
    
    // Only include rfis if there are any RFIs
    if (rfis.isNotEmpty) {
      json['rfis'] = rfis.map((rfi) => rfi.toJson()).toList();
    }
    
    return json;
  }

  @override
  String toString() {
    return 'Project(id: $id, projectName: $projectName, companyName: $companyName)';
  }
}

class Specification {
  final int? id;
  final int versionNo;
  final String colour;
  final String ironmongery;
  final double uValue;
  final double gValue;
  final String vents;
  final String acoustics;
  final String sbd;
  final String pas24;
  final String restrictors;
  final String specialComments;
  final String? attachmentUrl;

  Specification({
    this.id,
    required this.versionNo,
    required this.colour,
    required this.ironmongery,
    required this.uValue,
    required this.gValue,
    required this.vents,
    required this.acoustics,
    required this.sbd,
    required this.pas24,
    required this.restrictors,
    required this.specialComments,
    this.attachmentUrl,
  });

  factory Specification.fromJson(Map<String, dynamic> json) {
    return Specification(
      id: json['specification_id'] ?? json['id'],
      versionNo: json['version_no'] ?? 1,
      colour: json['colour'] ?? '',
      ironmongery: json['ironmongery'] ?? '',
      uValue: (json['u_value'] ?? 0.0).toDouble(),
      gValue: (json['g_value'] ?? 0.0).toDouble(),
      vents: json['vents'] ?? '',
      acoustics: json['acoustics'] ?? '',
      sbd: json['sbd']?.toString() ?? '',
      pas24: json['pas24']?.toString() ?? '',
      restrictors: json['restrictors']?.toString() ?? '',
      specialComments: json['special_comments'] ?? '',
      attachmentUrl: json['attachment_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'version_no': versionNo,
      'colour': colour,
      'ironmongery': ironmongery,
      'u_value': uValue,
      'g_value': gValue,
      'vents': vents,
      'acoustics': acoustics,
      'sbd': sbd,
      'pas24': pas24,
      'restrictors': restrictors,
      'special_comments': specialComments,
      'attachment_url': attachmentUrl,
    };
  }
}

class Rfi {
  final int? id;
  final String questionText;
  final String? answer;
  final String? answerValue;
  final String? status;
  final DateTime? createdAt;
  final DateTime? answeredAt;

  Rfi({
    this.id,
    required this.questionText,
    this.answer,
    this.answerValue,
    this.status,
    this.createdAt,
    this.answeredAt,
  });

  factory Rfi.fromJson(Map<String, dynamic> json) {
    return Rfi(
      id: json['rfi_id'] ?? json['id'],
      questionText: json['question_text'] ?? '',
      answer: json['answer'],
      answerValue: json['answer_value'],
      status: json['status'],
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : null,
      answeredAt: json['answered_at'] != null 
          ? DateTime.parse(json['answered_at']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question_text': questionText,
      'answer': answer,
      'answer_value': answerValue,
      'status': status,
      'created_at': createdAt?.toIso8601String(),
      'answered_at': answeredAt?.toIso8601String(),
    };
  }
}
