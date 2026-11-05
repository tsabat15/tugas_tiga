import 'dart:io';

/// Satu mata kuliah pada Kartu Hasil Studi.
typedef MataKuliah = ({String nama, int sks, String nilai});

/// Bobot nilai huruf. Skala contoh modul; sesuaikan dengan pedoman akademik.
const Map<String, double> tabelBobot = {'A': 4, 'B': 3, 'C': 2, 'D': 1, 'E': 0};

/// Lebar kolom tabel KHS.
const int lebarNama = 26;
const int lebarSks = 4;

/// Bobot di bawah nilai ini dianggap perlu diperbaiki.
const double batasPerbaikan = 2;

void main() {
  final List<MataKuliah> data = [];
  print('Masukkan data mata kuliah. Kosongkan nama untuk selesai.\n');

  // Input diulang sampai nama dikosongkan.
  var lanjut = true;
  while (lanjut) {
    final nama = baca('Nama MK');
    if (nama.isEmpty) {
      lanjut = false;
      continue;
    }
    try {
      // Validasi melempar FormatException; ditangkap di sini agar data yang
      // salah diabaikan tanpa menghentikan program.
      final sks = validasiSks(baca('SKS    '));
      final nilai = validasiNilai(baca('Nilai  '));
      data.add((nama: nama, sks: sks, nilai: nilai));
    } on FormatException catch (e) {
      print('Data diabaikan: ${e.message}');
    }
  }

  if (data.isEmpty) {
    print('\nTidak ada data mata kuliah.');
    return;
  }

  print('');
  cetakKhs(data, urutkan: true);
}

String baca(String label) {
  stdout.write('$label : ');
  return (stdin.readLineSync() ?? '').trim();
}

/// Mengubah teks menjadi SKS 1-6, atau melempar FormatException.
int validasiSks(String teks) {
  final sks = int.tryParse(teks);
  if (sks == null || sks < 1 || sks > 6) {
    throw FormatException('SKS harus berupa angka 1-6, bukan "$teks".');
  }
  return sks;
}

/// Menormalkan nilai huruf, atau melempar FormatException bila tidak dikenal.
String validasiNilai(String teks) {
  final huruf = teks.toUpperCase();
  if (!tabelBobot.containsKey(huruf)) {
    throw FormatException('Nilai harus A, B, C, D, atau E, bukan "$teks".');
  }
  return huruf;
}

/// Bobot nilai huruf; huruf tak dikenal sudah ditolak validasiNilai.
double bobot(String huruf) => tabelBobot[huruf] ?? 0;

/// IP = jumlah (SKS x bobot) dibagi jumlah SKS, keduanya dihitung dengan fold.
double hitungIp(List<MataKuliah> data) {
  final totalSks = hitungTotalSks(data);
  if (totalSks == 0) return 0;
  final totalMutu = data.fold<double>(
    0,
    (jumlah, mk) => jumlah + mk.sks * bobot(mk.nilai),
  );
  return totalMutu / totalSks;
}

int hitungTotalSks(List<MataKuliah> data) =>
    data.fold<int>(0, (jumlah, mk) => jumlah + mk.sks);

/// Predikat dari IP memakai switch expression dengan relational pattern.
String predikat(double ip) => switch (ip) {
  >= 3.51 => 'Dengan Pujian',
  >= 3.01 => 'Sangat Memuaskan',
  >= 2.76 => 'Memuaskan',
  >= 2.00 => 'Cukup',
  _ => 'Kurang',
};

/// Mata kuliah dengan bobot di bawah [batasPerbaikan], disaring dengan where.
List<MataKuliah> perluDiperbaiki(List<MataKuliah> data) =>
    data.where((mk) => bobot(mk.nilai) < batasPerbaikan).toList();

/// Mencetak KHS; [urutkan] menyusun dari nilai tertinggi.
void cetakKhs(List<MataKuliah> data, {bool urutkan = false}) {
  final baris = data.toList();
  if (urutkan) {
    // Fungsi pembanding: bobot terbesar lebih dulu.
    baris.sort((a, b) => bobot(b.nilai).compareTo(bobot(a.nilai)));
  }

  final garis = '-' * (lebarNama + lebarSks + 7);
  print(
    '${'Mata Kuliah'.padRight(lebarNama)}'
    '${'SKS'.padLeft(lebarSks)}  Nilai',
  );
  print(garis);
  for (final mk in baris) {
    final sks = mk.sks.toString().padLeft(lebarSks);
    print('${mk.nama.padRight(lebarNama)}$sks  ${mk.nilai}');
  }
  print(garis);

  final ip = hitungIp(data);
  print('Total SKS : ${hitungTotalSks(data)}');
  print('IP        : ${ip.toStringAsFixed(2)} (${predikat(ip)})');

  final perbaikan = perluDiperbaiki(data);
  if (perbaikan.isNotEmpty) {
    print('Perlu diperbaiki: ${perbaikan.map((mk) => mk.nama).join(', ')}');
  }
}
