class TemplateItem {
  const TemplateItem({
    required this.templateId,
    required this.documentId,
    required this.sortOrder,
  });

  final String templateId;
  final String documentId;
  final int sortOrder;

  factory TemplateItem.fromMap(Map<String, dynamic> map) {
    return TemplateItem(
      templateId: map['template_id'] as String,
      documentId: map['document_id'] as String,
      sortOrder: map['sort_order'] as int,
    );
  }
}
