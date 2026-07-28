class ReceiptPayment {
  const ReceiptPayment({
    required this.id,
    required this.amount,
    required this.periodCovered,
    required this.paymentDate,
  });

  factory ReceiptPayment.fromJson(Map<String, dynamic> json) {
    return ReceiptPayment(
      id: json['id'] as int,
      amount: (json['amount'] as num).toDouble(),
      periodCovered: json['period_covered'] as String,
      paymentDate: DateTime.parse(json['payment_date'] as String),
    );
  }

  final int id;
  final double amount;
  final String periodCovered;
  final DateTime paymentDate;
}

class Receipt {
  const Receipt({
    required this.id,
    required this.receiptNumber,
    required this.payment,
    required this.propertyTitle,
    required this.tenantName,
    required this.pdfUrl,
    required this.generatedAt,
  });

  factory Receipt.fromJson(Map<String, dynamic> json) {
    final tenant = json['tenant'] as Map<String, dynamic>;

    return Receipt(
      id: json['id'] as int,
      receiptNumber: json['receipt_number'] as String,
      payment: ReceiptPayment.fromJson(json['payment'] as Map<String, dynamic>),
      propertyTitle: json['property_title'] as String,
      tenantName: tenant['name'] as String,
      pdfUrl: json['pdf_url'] as String,
      generatedAt: DateTime.parse(json['generated_at'] as String),
    );
  }

  final int id;
  final String receiptNumber;
  final ReceiptPayment payment;
  final String propertyTitle;
  final String tenantName;
  final String pdfUrl;
  final DateTime generatedAt;
}
