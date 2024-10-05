import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text('Arama ve Liste Uygulaması'),
        ),
        body: MyHomePage(),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedItem = "";
  List<Map<String, dynamic>> _dropdownItems = [];
  List<Map<String, dynamic>> _gridData = [];
  List<Map<String, dynamic>> _filteredGridData = [];

  int _start = 0; // Başlangıç değeri
  int _length = 100; // Her sayfada gösterilecek ürün sayısı
  bool _isLastPage = false; // Son sayfa olup olmadığını kontrol etmek için
  int _currentPage = 1; // Şu anki sayfa numarası

  // Dropdowndaki itemların sadece text kısmını döndüren metot
  List<String> getDropdownTexts() {
    return _dropdownItems.map((item) => item['text'] as String).toList();
  }

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Center(
          child: CircularProgressIndicator(),
        );
      },
    );
  }

  Future<void> _updateDropdown() async {
    _showLoadingDialog();

    var headers = {
      'Accept': 'application/json, text/javascript, */*; q=0.01',
      'Accept-Language': 'tr,tr-TR;q=0.9,en-US;q=0.8,en;q=0.7',
      'Connection': 'keep-alive',
      'User-Agent':
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/129.0.0.0 Safari/537.36',
      'X-Requested-With': 'XMLHttpRequest'
    };
    var request = http.Request(
        'GET',
        Uri.parse(
            'https://guvenilirgida.tarimorman.gov.tr/UrunGrup/AjaxAra?limit=0&&key='));

    request.headers.addAll(headers);

    http.StreamedResponse response = await request.send();

    if (response.statusCode == 200) {
      String responseData = await response.stream.bytesToString();
      List<dynamic> jsonData = jsonDecode(responseData);

      setState(() {
        _dropdownItems = jsonData
            .map<Map<String, dynamic>>((item) => {
          'id': item['id'],
          'text': item['text'],
          'description': item['description']
        })
            .toList();
      });

      // Ürün kategorileri güncellendi mesajı göster
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Ürün kategorileri güncellendi")),
      );
    } else {
      print(response.reasonPhrase);
    }

    Navigator.pop(context);
  }

  // Tarihi /Date(...) formatından okunabilir formata dönüştürme metodu
  String formatDate(String dateString) {
    int millisecondsSinceEpoch = int.parse(
        dateString.replaceAll(RegExp(r'[^0-9]'), '')); // Sadece sayı olan kısmı al
    DateTime date = DateTime.fromMillisecondsSinceEpoch(millisecondsSinceEpoch);
    return "${date.day}/${date.month}/${date.year}";
  }

  Future<void> _queryData({bool isNextPage = false, bool isPreviousPage = false}) async {
    _showLoadingDialog();

    // Geçici bir sayfa numarası
    int tempPage = _currentPage;

    // Eğer sonraki sayfa yükleniyorsa start parametresini güncelle
    if (isNextPage) {
      if (_isLastPage) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Sayfa sonuna geldiniz")),
        );
        return;
      } else {
        _start += _length;
        tempPage++; // Sayfa numarasını geçici olarak artır
      }
    } else if (isPreviousPage) {
      if (_start > 0) {
        _start -= _length; // Önceki sayfaya gitmek için start değerini düşür
        tempPage--; // Sayfa numarasını geçici olarak düşür
      } else {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("İlk sayfadasınız")),
        );
        return;
      }
    } else {
      _start = 0; // İlk sorgu yapıldığında start 0'dan başlar
      tempPage = 1; // İlk sayfadaysak sayfa numarasını 1 yap
    }

    String? urunGrupIdParam;
    String? urunGrupAdiParam;
    if (_selectedItem.isNotEmpty) {
      var selectedItem = _dropdownItems
          .firstWhere((element) => element['text'] == _selectedItem);
      urunGrupIdParam = selectedItem['id'];
      urunGrupAdiParam = Uri.encodeComponent(selectedItem['text']);
    }

    var body = '''
draw=1&columns%5B0%5D%5Bdata%5D=DuyuruTarihi&columns%5B0%5D%5Bname%5D=&columns%5B0%5D%5Bsearchable%5D=true&columns%5B0%5D%5Borderable%5D=true&columns%5B0%5D%5Bsearch%5D%5Bvalue%5D=&columns%5B0%5D%5Bsearch%5D%5Bregex%5D=false&columns%5B1%5D%5Bdata%5D=FirmaAdi&columns%5B1%5D%5Bname%5D=&columns%5B1%5D%5Bsearchable%5D=true&columns%5B1%5D%5Borderable%5D=true&columns%5B1%5D%5Bsearch%5D%5Bvalue%5D=&columns%5B1%5D%5Bsearch%5D%5Bregex%5D=false&columns%5B2%5D%5Bdata%5D=Marka&columns%5B2%5D%5Bname%5D=&columns%5B2%5D%5Bsearchable%5D=true&columns%5B2%5D%5Borderable%5D=true&columns%5B2%5D%5Bsearch%5D%5Bvalue%5D=&columns%5B2%5D%5Bsearch%5D%5Bregex%5D=false&columns%5B3%5D%5Bdata%5D=UrunAdi&columns%5B3%5D%5Bname%5D=&columns%5B3%5D%5Bsearchable%5D=true&columns%5B3%5D%5Borderable%5D=true&columns%5B3%5D%5Bsearch%5D%5Bvalue%5D=&columns%5B3%5D%5Bsearch%5D%5Bregex%5D=false&columns%5B4%5D%5Bdata%5D=Uygunsuzluk&columns%5B4%5D%5Bname%5D=&columns%5B4%5D%5Bsearchable%5D=true&columns%5B4%5D%5Borderable%5D=true&columns%5B4%5D%5Bsearch%5D%5Bvalue%5D=&columns%5B4%5D%5Bsearch%5D%5Bregex%5D=false&start=$_start&length=$_length&search%5Bvalue%5D=&search%5Bregex%5D=false''';

    if (urunGrupIdParam != null && urunGrupAdiParam != null) {
      body +=
      "&_KamuoyuDuyuruAra_UrunGrupId=$urunGrupAdiParam&KamuoyuDuyuruAra.UrunGrupId=$urunGrupIdParam";
    }

    var headers = {
      'Accept': 'application/json, text/javascript, */*; q=0.01',
      'Accept-Language': 'tr,tr-TR;q=0.9,en-US;q=0.8,en;q=0.7',
      'Connection': 'keep-alive',
      'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8',
      'Origin': 'https://guvenilirgida.tarimorman.gov.tr',
      'User-Agent':
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/129.0.0.0 Safari/537.36',
      'X-Requested-With': 'XMLHttpRequest'
    };

    var request = http.Request(
        'POST',
        Uri.parse(
            'https://guvenilirgida.tarimorman.gov.tr/GuvenilirGida/GKD/DataTablesList'));
    request.body = body;
    request.headers.addAll(headers);

    http.StreamedResponse response = await request.send();

    if (response.statusCode == 200) {
      String responseData = await response.stream.bytesToString();
      Map<String, dynamic> jsonResponse = jsonDecode(responseData);
      List<dynamic> newData = jsonResponse['data'];

      setState(() {
        if (newData.isEmpty) {
          // Veri yoksa sayfa numarası artmasın/düşmesin ve eski sayfa numarasına dön
          _start = isNextPage ? _start - _length : _start + _length;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Sayfa sonuna geldiniz")),
          );
        } else {
          // Yeni veriyi ekle ve sayfa numarasını güncelle
          _gridData = newData
              .map((item) => {
            'DuyuruTarihi': formatDate(item['DuyuruTarihi']),
            'FirmaAdi': item['FirmaAdi'],
            'Marka': item['Marka'],
            'UrunAdi': item['UrunAdi'],
            'Uygunsuzluk': item['Uygunsuzluk'],
          })
              .toList();
          _filteredGridData = _gridData;
          _currentPage = tempPage; // Geçici sayfa numarasını onayla
          _isLastPage = false; // Geri gidildiğinde son sayfa bilgisi sıfırlanır
        }
      });
    } else {
      print(response.reasonPhrase);
    }

    Navigator.pop(context);
  }

  // Firma adına göre yerel arama
  void _filterGridData(String searchQuery) {
    setState(() {
      if (searchQuery.isEmpty) {
        _filteredGridData = _gridData; // Arama kutusu boşsa tüm verileri göster
      } else {
        _filteredGridData = _gridData
            .where((item) => item['FirmaAdi']
            .toString()
            .toLowerCase()
            .contains(searchQuery.toLowerCase()))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // En üstte dropdown ve güncelleme butonu
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              // Açılır liste
              Expanded(
                flex: 3,
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: getDropdownTexts().contains(_selectedItem)
                      ? _selectedItem
                      : null,
                  hint: Text('Bir öğe seçin'),
                  items: getDropdownTexts().map((String item) {
                    return DropdownMenuItem<String>(
                      value: item,
                      child: Text(
                        item,
                        overflow: TextOverflow.ellipsis,
                        softWrap: false,
                      ),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      if (newValue != null) {
                        _selectedItem = newValue;
                      }
                    });
                  },
                ),
              ),
              SizedBox(width: 8),
              // Yenileme butonu sadece ikon ile
              Expanded(
                flex: 1,
                child: ElevatedButton(
                  onPressed: _updateDropdown,
                  child: Icon(Icons.refresh),
                ),
              ),
            ],
          ),
        ),
        // Arama kutusu ve sorgu butonu
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              // Arama kutusu
              Expanded(
                flex: 3,
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: 'Firma Adına Göre Ara',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    _filterGridData(value); // Yerel filtreleme
                  },
                ),
              ),
              SizedBox(width: 8),
              // Sorgu butonu
              Expanded(
                flex: 1,
                child: ElevatedButton(
                  onPressed: () => _queryData(isNextPage: false), // İlk sorgu
                  child: Icon(Icons.search),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 16),
        // Grid alanı
        Expanded(
          child: SfDataGrid(
            source: MyDataGridSource(_filteredGridData),
            columnWidthMode: ColumnWidthMode.fitByColumnName, // Kolon genişliğini içeriğe göre ayarlar
            allowSwiping: false,
            onQueryRowHeight: (RowHeightDetails details) {
              return details.getIntrinsicRowHeight(details.rowIndex); // Satır yüksekliğini içeriğe göre ayarlar
            },
            columns: [
              GridColumn(
                columnName: 'DuyuruTarihi',
                label: Container(
                  padding: EdgeInsets.all(8.0),
                  alignment: Alignment.center,
                  child: Text('Duyuru Tarihi'),
                ),
              ),
              GridColumn(
                columnName: 'FirmaAdi',
                label: Container(
                  padding: EdgeInsets.all(8.0),
                  alignment: Alignment.center,
                  child: Text('Firma Adı', softWrap: true, // Metni sar
                    overflow: TextOverflow.visible,),
                ),
              ),
              GridColumn(
                columnName: 'Marka',
                label: Container(
                  padding: EdgeInsets.all(8.0),
                  alignment: Alignment.center,
                  child: Text('Marka'),
                ),
              ),
              GridColumn(
                columnName: 'UrunAdi',
                label: Container(
                  padding: EdgeInsets.all(8.0),
                  alignment: Alignment.center,
                  child: Text('Ürün Adı'),
                ),
              ),
              GridColumn(
                columnName: 'Uygunsuzluk',
                label: Container(
                  padding: EdgeInsets.all(8.0),
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Uygunsuzluk',
                    softWrap: true, // Metni sar
                    overflow: TextOverflow.visible, // Taşmayı engelle
                  ),
                ),
              ),
            ],
          ),
        ),
        // Sonraki ve önceki sayfa butonları
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ElevatedButton(
                onPressed: () => _queryData(isPreviousPage: true), // Önceki sayfa
                child: Text("Geri"),
              ),
              Text("Sayfa $_currentPage"), // Sayfa numarası
              ElevatedButton(
                onPressed: () => _queryData(isNextPage: true), // Sonraki sayfa
                child: Text("Sonraki"),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// MyDataGridSource olarak yeniden adlandırıldı
class MyDataGridSource extends DataGridSource {
  final List<Map<String, dynamic>> _data;

  MyDataGridSource(this._data);

  @override
  List<DataGridRow> get rows => _data
      .map<DataGridRow>((data) => DataGridRow(cells: [
    DataGridCell<String>(
        columnName: 'DuyuruTarihi', value: data['DuyuruTarihi']),
    DataGridCell<String>(columnName: 'FirmaAdi', value: data['FirmaAdi']),
    DataGridCell<String>(columnName: 'Marka', value: data['Marka']),
    DataGridCell<String>(columnName: 'UrunAdi', value: data['UrunAdi']),
    DataGridCell<String>(
        columnName: 'Uygunsuzluk', value: data['Uygunsuzluk']),
  ]))
      .toList();

  @override
  DataGridRowAdapter buildRow(DataGridRow row) {
    return DataGridRowAdapter(
      cells: row.getCells().map<Widget>((cell) {
        return Container(
          alignment: Alignment.centerLeft, // Metni sola hizala
          padding: EdgeInsets.all(8.0),
          child: Text(
            cell.value.toString(),
            softWrap: true, // Metni sar
            overflow: TextOverflow.visible, // Taşmayı önle
            maxLines: null, // Satır sınırı olmadan genişlesin
          ),
        );
      }).toList(),
    );
  }
}
