import '../models/codes.dart';
import '../models/location.dart';
import '../util/localized_text.dart';

/// The wards of the mini-hospital.
const List<Ward> seedWards = <Ward>[
  Ward(
    id: 'ward-emer',
    code: 'EMER',
    name: LocalizedText(
      en: 'Emergency department',
      fr: 'Service des urgences',
      nl: 'Spoedgevallendienst',
    ),
    floor: 0,
    specialty: LocalizedText(
      en: 'Emergency medicine',
      fr: "Médecine d'urgence",
      nl: 'Spoedeisende geneeskunde',
    ),
    phoneExtension: '1000',
  ),
  Ward(
    id: 'ward-card',
    code: 'CARD',
    name: LocalizedText(en: 'Cardiology', fr: 'Cardiologie', nl: 'Cardiologie'),
    floor: 3,
    specialty: LocalizedText(en: 'Cardiology', fr: 'Cardiologie', nl: 'Cardiologie'),
    phoneExtension: '3100',
  ),
  Ward(
    id: 'ward-int',
    code: 'INT',
    name: LocalizedText(
      en: 'Internal medicine',
      fr: 'Médecine interne',
      nl: 'Interne geneeskunde',
    ),
    floor: 4,
    specialty: LocalizedText(
      en: 'Internal medicine',
      fr: 'Médecine interne',
      nl: 'Interne geneeskunde',
    ),
    phoneExtension: '4100',
  ),
  Ward(
    id: 'ward-surg',
    code: 'SURG',
    name: LocalizedText(en: 'Surgery', fr: 'Chirurgie', nl: 'Chirurgie'),
    floor: 2,
    specialty: LocalizedText(
      en: 'General surgery',
      fr: 'Chirurgie générale',
      nl: 'Algemene heelkunde',
    ),
    phoneExtension: '2100',
  ),
  Ward(
    id: 'ward-icu',
    code: 'ICU',
    name: LocalizedText(
      en: 'Intensive care unit',
      fr: 'Soins intensifs',
      nl: 'Intensieve zorgen',
    ),
    floor: 2,
    specialty: LocalizedText(
      en: 'Critical care',
      fr: 'Soins critiques',
      nl: 'Kritieke zorg',
    ),
    phoneExtension: '2200',
  ),
  Ward(
    id: 'ward-ped',
    code: 'PED',
    name: LocalizedText(en: 'Paediatrics', fr: 'Pédiatrie', nl: 'Pediatrie'),
    floor: 5,
    specialty: LocalizedText(en: 'Paediatrics', fr: 'Pédiatrie', nl: 'Pediatrie'),
    phoneExtension: '5100',
  ),
  Ward(
    id: 'ward-geri',
    code: 'GERI',
    name: LocalizedText(en: 'Geriatrics', fr: 'Gériatrie', nl: 'Geriatrie'),
    floor: 6,
    specialty: LocalizedText(en: 'Geriatrics', fr: 'Gériatrie', nl: 'Geriatrie'),
    phoneExtension: '6100',
  ),
];

/// How many rooms each ward has, and which of them are isolation rooms.
const Map<String, _WardLayout> _layouts = <String, _WardLayout>{
  'ward-emer': _WardLayout(firstRoom: 1, roomCount: 6, isolationRooms: <int>[6]),
  'ward-card': _WardLayout(firstRoom: 301, roomCount: 8, isolationRooms: <int>[308]),
  'ward-int': _WardLayout(firstRoom: 401, roomCount: 8, isolationRooms: <int>[407, 408]),
  'ward-surg': _WardLayout(firstRoom: 201, roomCount: 6, isolationRooms: <int>[]),
  'ward-icu': _WardLayout(firstRoom: 221, roomCount: 6, isolationRooms: <int>[221, 222, 223, 224, 225, 226]),
  'ward-ped': _WardLayout(firstRoom: 501, roomCount: 6, isolationRooms: <int>[506]),
  'ward-geri': _WardLayout(firstRoom: 601, roomCount: 8, isolationRooms: <int>[608]),
};

class _WardLayout {
  const _WardLayout({
    required this.firstRoom,
    required this.roomCount,
    required this.isolationRooms,
  });
  final int firstRoom;
  final int roomCount;
  final List<int> isolationRooms;
}

/// Builds the room list. Room numbering follows the Belgian hospital habit of
/// encoding the floor in the first digit (`301` = third floor, room 1).
List<Room> buildSeedRooms() {
  final rooms = <Room>[];
  for (final ward in seedWards) {
    final layout = _layouts[ward.id]!;
    for (var i = 0; i < layout.roomCount; i++) {
      final number = layout.firstRoom + i;
      rooms.add(Room(
        id: 'room-${ward.code.toLowerCase()}-$number',
        wardId: ward.id,
        number: '$number',
        isIsolation: layout.isolationRooms.contains(number),
      ));
    }
  }
  return rooms;
}

/// Builds the bed list: two beds per room, one in isolation rooms.
List<Bed> buildSeedBeds(List<Room> rooms) {
  final beds = <Bed>[];
  for (final room in rooms) {
    final wardCode = room.id.split('-')[1];
    final letters = room.isIsolation ? <String>['A'] : <String>['A', 'B'];
    for (final letter in letters) {
      beds.add(Bed(
        id: 'bed-$wardCode-${room.number}$letter'.toLowerCase(),
        roomId: room.id,
        wardId: room.wardId,
        label: '${room.number}-$letter',
        status: BedStatus.free,
      ));
    }
  }
  return beds;
}
