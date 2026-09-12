import '../models/prescription.dart';
import '../util/localized_text.dart';

/// The hospital formulary: the medicines the pharmacy stocks.
///
/// ATC codes are the real WHO codes, so students can look the products up and
/// see how a formulary maps onto an international classification. The internal
/// `MED-nnnn` codes stand in for the Belgian CNK numbers.
const List<Medication> seedFormulary = <Medication>[
  Medication(
    code: 'MED-0101',
    name: LocalizedText(en: 'Paracetamol', fr: 'Paracétamol', nl: 'Paracetamol'),
    form: LocalizedText(en: 'Tablet', fr: 'Comprimé', nl: 'Tablet'),
    strength: '500 mg',
    atcCode: 'N02BE01',
  ),
  Medication(
    code: 'MED-0102',
    name: LocalizedText(en: 'Ibuprofen', fr: 'Ibuprofène', nl: 'Ibuprofen'),
    form: LocalizedText(en: 'Tablet', fr: 'Comprimé', nl: 'Tablet'),
    strength: '400 mg',
    atcCode: 'M01AE01',
  ),
  Medication(
    code: 'MED-0103',
    name: LocalizedText(en: 'Amoxicillin', fr: 'Amoxicilline', nl: 'Amoxicilline'),
    form: LocalizedText(en: 'Capsule', fr: 'Gélule', nl: 'Capsule'),
    strength: '500 mg',
    atcCode: 'J01CA04',
  ),
  Medication(
    code: 'MED-0104',
    name: LocalizedText(
      en: 'Amoxicillin / clavulanic acid',
      fr: 'Amoxicilline / acide clavulanique',
      nl: 'Amoxicilline / clavulaanzuur',
    ),
    form: LocalizedText(
      en: 'Powder for solution for injection',
      fr: 'Poudre pour solution injectable',
      nl: 'Poeder voor oplossing voor injectie',
    ),
    strength: '1 g / 200 mg',
    atcCode: 'J01CR02',
  ),
  Medication(
    code: 'MED-0105',
    name: LocalizedText(en: 'Enoxaparin', fr: 'Énoxaparine', nl: 'Enoxaparine'),
    form: LocalizedText(
      en: 'Prefilled syringe',
      fr: 'Seringue préremplie',
      nl: 'Voorgevulde spuit',
    ),
    strength: '4000 IU / 0.4 mL',
    atcCode: 'B01AB05',
  ),
  Medication(
    code: 'MED-0106',
    name: LocalizedText(en: 'Bisoprolol', fr: 'Bisoprolol', nl: 'Bisoprolol'),
    form: LocalizedText(en: 'Tablet', fr: 'Comprimé', nl: 'Tablet'),
    strength: '5 mg',
    atcCode: 'C07AB07',
  ),
  Medication(
    code: 'MED-0107',
    name: LocalizedText(en: 'Furosemide', fr: 'Furosémide', nl: 'Furosemide'),
    form: LocalizedText(en: 'Tablet', fr: 'Comprimé', nl: 'Tablet'),
    strength: '40 mg',
    atcCode: 'C03CA01',
  ),
  Medication(
    code: 'MED-0108',
    name: LocalizedText(en: 'Perindopril', fr: 'Périndopril', nl: 'Perindopril'),
    form: LocalizedText(en: 'Tablet', fr: 'Comprimé', nl: 'Tablet'),
    strength: '5 mg',
    atcCode: 'C09AA04',
  ),
  Medication(
    code: 'MED-0109',
    name: LocalizedText(en: 'Atorvastatin', fr: 'Atorvastatine', nl: 'Atorvastatine'),
    form: LocalizedText(en: 'Tablet', fr: 'Comprimé', nl: 'Tablet'),
    strength: '40 mg',
    atcCode: 'C10AA05',
  ),
  Medication(
    code: 'MED-0110',
    name: LocalizedText(en: 'Metformin', fr: 'Metformine', nl: 'Metformine'),
    form: LocalizedText(en: 'Tablet', fr: 'Comprimé', nl: 'Tablet'),
    strength: '850 mg',
    atcCode: 'A10BA02',
  ),
  Medication(
    code: 'MED-0111',
    name: LocalizedText(
      en: 'Insulin aspart',
      fr: 'Insuline asparte',
      nl: 'Insuline aspart',
    ),
    form: LocalizedText(
      en: 'Solution for injection, pen',
      fr: 'Solution injectable, stylo',
      nl: 'Oplossing voor injectie, pen',
    ),
    strength: '100 IU/mL',
    atcCode: 'A10AB05',
  ),
  Medication(
    code: 'MED-0112',
    name: LocalizedText(en: 'Salbutamol', fr: 'Salbutamol', nl: 'Salbutamol'),
    form: LocalizedText(
      en: 'Pressurised inhalation',
      fr: 'Inhalation pressurisée',
      nl: 'Inhalatie onder druk',
    ),
    strength: '100 µg/dose',
    atcCode: 'R03AC02',
  ),
  Medication(
    code: 'MED-0113',
    name: LocalizedText(en: 'Omeprazole', fr: 'Oméprazole', nl: 'Omeprazol'),
    form: LocalizedText(
      en: 'Gastro-resistant capsule',
      fr: 'Gélule gastro-résistante',
      nl: 'Maagsapresistente capsule',
    ),
    strength: '20 mg',
    atcCode: 'A02BC01',
  ),
  Medication(
    code: 'MED-0114',
    name: LocalizedText(en: 'Morphine', fr: 'Morphine', nl: 'Morfine'),
    form: LocalizedText(
      en: 'Solution for injection',
      fr: 'Solution injectable',
      nl: 'Oplossing voor injectie',
    ),
    strength: '10 mg/mL',
    atcCode: 'N02AA01',
    isControlled: true,
  ),
  Medication(
    code: 'MED-0115',
    name: LocalizedText(en: 'Midazolam', fr: 'Midazolam', nl: 'Midazolam'),
    form: LocalizedText(
      en: 'Solution for injection',
      fr: 'Solution injectable',
      nl: 'Oplossing voor injectie',
    ),
    strength: '5 mg/mL',
    atcCode: 'N05CD08',
    isControlled: true,
  ),
  Medication(
    code: 'MED-0116',
    name: LocalizedText(en: 'Ceftriaxone', fr: 'Ceftriaxone', nl: 'Ceftriaxon'),
    form: LocalizedText(
      en: 'Powder for solution for injection',
      fr: 'Poudre pour solution injectable',
      nl: 'Poeder voor oplossing voor injectie',
    ),
    strength: '2 g',
    atcCode: 'J01DD04',
  ),
  Medication(
    code: 'MED-0117',
    name: LocalizedText(
      en: 'Sodium chloride 0.9%',
      fr: 'Chlorure de sodium 0,9 %',
      nl: 'Natriumchloride 0,9%',
    ),
    form: LocalizedText(
      en: 'Solution for infusion',
      fr: 'Solution pour perfusion',
      nl: 'Oplossing voor infusie',
    ),
    strength: '500 mL',
    atcCode: 'B05CB01',
  ),
  Medication(
    code: 'MED-0118',
    name: LocalizedText(en: 'Amlodipine', fr: 'Amlodipine', nl: 'Amlodipine'),
    form: LocalizedText(en: 'Tablet', fr: 'Comprimé', nl: 'Tablet'),
    strength: '5 mg',
    atcCode: 'C08CA01',
  ),
  Medication(
    code: 'MED-0119',
    name: LocalizedText(
      en: 'Acetylsalicylic acid',
      fr: 'Acide acétylsalicylique',
      nl: 'Acetylsalicylzuur',
    ),
    form: LocalizedText(en: 'Tablet', fr: 'Comprimé', nl: 'Tablet'),
    strength: '80 mg',
    atcCode: 'B01AC06',
  ),
  Medication(
    code: 'MED-0120',
    name: LocalizedText(en: 'Levothyroxine', fr: 'Lévothyroxine', nl: 'Levothyroxine'),
    form: LocalizedText(en: 'Tablet', fr: 'Comprimé', nl: 'Tablet'),
    strength: '75 µg',
    atcCode: 'H03AA01',
  ),
];

/// Looks a product up by its formulary code.
Medication? formularyByCode(String code) {
  for (final medication in seedFormulary) {
    if (medication.code == code) return medication;
  }
  return null;
}
