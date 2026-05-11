import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../models/cliente.dart';

class PdfService {
  static const String nomeEmpresa = 'Nome da Empresa';
  static const String cnpjEmpresa = '00.000.000/0000-00';
  static const String cidadeEmpresa = 'Cidade - UF - CEP';
  static const String telefoneEmpresa = '(00) 00000-0000';
  static const String emailEmpresa = 'contato@example.com';

  Future<void> gerarNotaFiscal(Cliente cliente) async {
    final pdf = pw.Document();

    // Número da nota fiscal (baseado no ID do cliente e timestamp)
    final numeroNota = 'NF-${cliente.id.toString().padLeft(6, '0')}';
    final dataEmissao = DateTime.now();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Cabeçalho
              _buildCabecalho(),
              pw.SizedBox(height: 20),

              // Informações da Nota Fiscal
              _buildInfoNotaFiscal(numeroNota, dataEmissao),
              pw.SizedBox(height: 20),

              // Dados do Cliente
              _buildDadosCliente(cliente),
              pw.SizedBox(height: 20),

              // Serviços Prestados
              _buildServicosPrestados(cliente),
              pw.SizedBox(height: 20),

              // Totais
              _buildTotais(cliente),
              pw.SizedBox(height: 30),

              // Observações
              _buildObservacoes(cliente),

              pw.Spacer(),

              // Rodapé
              _buildRodape(),
            ],
          );
        },
      ),
    );

    // Salvar e compartilhar o PDF
    await _salvarECompartilharPdf(pdf, numeroNota, cliente);
  }

  pw.Widget _buildCabecalho() {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey),
        color: PdfColors.grey100,
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            nomeEmpresa,
            style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 5),
          pw.Text('CNPJ: $cnpjEmpresa'),
          //pw.Text(enderecoEmpresa),
          pw.Text(cidadeEmpresa),
          pw.Text('Tel: $telefoneEmpresa | E-mail: $emailEmpresa'),
        ],
      ),
    );
  }

  pw.Widget _buildInfoNotaFiscal(String numeroNota, DateTime dataEmissao) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'NOTA FISCAL DE SERVIÇO',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),
            pw.Text('Número: $numeroNota'),
          ],
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text('Data de Emissão:'),
            pw.Text(
              DateFormat('dd/MM/yyyy HH:mm').format(dataEmissao),
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildDadosCliente(Cliente cliente) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'DADOS DO CLIENTE',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 10),
          pw.Text('Nome: ${cliente.nomeCompleto}'),
          pw.Text('Endereço: ${cliente.endereco}'),
          pw.Text(
            'Data do Serviço: ${DateFormat('dd/MM/yyyy').format(cliente.dataAgendada)}',
          ),
          if (cliente.dataConclusao != null)
            pw.Text(
              'Data de Conclusão: ${DateFormat('dd/MM/yyyy').format(cliente.dataConclusao!)}',
            ),
        ],
      ),
    );
  }

  pw.Widget _buildServicosPrestados(Cliente cliente) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'SERVIÇOS PRESTADOS',
          style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 10),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey),
          children: [
            // Cabeçalho da tabela
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey100),
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text(
                    'Descrição',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text(
                    'Qtd',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text(
                    'Valor Unit.',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    textAlign: pw.TextAlign.right,
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text(
                    'Valor Total',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    textAlign: pw.TextAlign.right,
                  ),
                ),
              ],
            ),
            // Linha do serviço
            pw.TableRow(
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text('Serviço de Montagem de Móveis'),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text('1', textAlign: pw.TextAlign.center),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text(
                    'R\$ ${cliente.valor.toStringAsFixed(2)}',
                    textAlign: pw.TextAlign.right,
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text(
                    'R\$ ${cliente.valor.toStringAsFixed(2)}',
                    textAlign: pw.TextAlign.right,
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildTotais(Cliente cliente) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey),
        color: PdfColors.grey50,
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'VALOR TOTAL DOS SERVIÇOS:',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.Text(
            'R\$ ${cliente.valor.toStringAsFixed(2)}',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.green700,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildObservacoes(Cliente cliente) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'OBSERVAÇÕES:',
          style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 5),
        pw.Container(
          width: double.infinity,
          height: 60,
          padding: const pw.EdgeInsets.all(8),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey),
          ),
          child: pw.Text(
            'Serviço de montagem realizado conforme solicitado.\n'
            'Garantia de 90 dias para defeitos de montagem.\n'
            'Agradecemos a preferência!',
            style: const pw.TextStyle(fontSize: 10),
          ),
        ),
      ],
    );
  }

  pw.Widget _buildRodape() {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(10),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: PdfColors.grey)),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            'Esta nota fiscal foi gerada automaticamente pelo sistema.',
            style: const pw.TextStyle(fontSize: 10),
            textAlign: pw.TextAlign.center,
          ),
          pw.SizedBox(height: 5),
          pw.Text(
            'Para dúvidas ou esclarecimentos, entre em contato conosco.',
            style: const pw.TextStyle(fontSize: 10),
            textAlign: pw.TextAlign.center,
          ),
        ],
      ),
    );
  }

  Future<void> _salvarECompartilharPdf(
    pw.Document pdf,
    String numeroNota,
    Cliente cliente,
  ) async {
    try {
      // Obter diretório para salvar o arquivo
      final directory = await getApplicationDocumentsDirectory();
      final fileName =
          'NotaFiscal_${numeroNota}_${cliente.nome.replaceAll(' ', '_')}.pdf';
      final file = File('${directory.path}/$fileName');

      // Salvar o PDF
      await file.writeAsBytes(await pdf.save());

      // Compartilhar o arquivo
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Nota Fiscal - $numeroNota\nCliente: ${cliente.nomeCompleto}',
        subject: 'Nota Fiscal de Serviço - $numeroNota',
      );
    } catch (e) {
      // Se não conseguir salvar/compartilhar, pelo menos tenta imprimir
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
      );
    }
  }

  // Método para visualizar o PDF antes de salvar
  Future<void> visualizarNotaFiscal(Cliente cliente) async {
    final pdf = pw.Document();
    final numeroNota = 'NF-${cliente.id.toString().padLeft(6, '0')}';
    final dataEmissao = DateTime.now();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildCabecalho(),
              pw.SizedBox(height: 20),
              _buildInfoNotaFiscal(numeroNota, dataEmissao),
              pw.SizedBox(height: 20),
              _buildDadosCliente(cliente),
              pw.SizedBox(height: 20),
              _buildServicosPrestados(cliente),
              pw.SizedBox(height: 20),
              _buildTotais(cliente),
              pw.SizedBox(height: 30),
              _buildObservacoes(cliente),
              pw.Spacer(),
              _buildRodape(),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }
}
