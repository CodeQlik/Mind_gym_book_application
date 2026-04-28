import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

void main() {
  var controller = PdfViewerController();
  controller.nonExistentMethod();
  
  var details = PdfTextSelectionChangedDetails(null, null);
  details.nonExistentMethod();
}
