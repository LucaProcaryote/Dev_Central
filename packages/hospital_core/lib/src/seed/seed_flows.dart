import '../models/integration.dart';
import '../util/localized_text.dart';

/// Four worked integration flows, ready to open on the canvas.
///
/// They are meant to be read before they are run. Between them they cover the
/// patterns the students will need for their own flows: validate then store,
/// route on a field, filter to raise an alert, and translate HL7 v2 to FHIR.
List<IntegrationFlow> buildSeedFlows(DateTime now) => <IntegrationFlow>[
  IntegrationFlow(
    id: 'flow-hl7-adt',
    name: const LocalizedText(
      en: 'HL7 v2 admissions to FHIR',
      fr: 'Admissions HL7 v2 vers FHIR',
      nl: 'HL7 v2-opnames naar FHIR',
    ),
    description: const LocalizedText(
      en:
          'The job an interface engine does all day: an ADT^A01 arrives as a '
          'pipe-delimited v2 message, its segments are parsed, inpatient '
          'admissions are kept, and the visit is translated into a FHIR '
          'Encounter for the record. Open a message and switch between the '
          'two views to see what each format keeps and what it loses.',
      fr:
          "Le travail quotidien d'un moteur d'intégration : un ADT^A01 arrive "
          'en message v2 à barres verticales, ses segments sont analysés, les '
          'admissions hospitalières sont retenues, et le séjour est traduit '
          'en Encounter FHIR pour le dossier. Ouvrez un message et basculez '
          'entre les deux vues pour voir ce que chaque format conserve et ce '
          "qu'il perd.",
      nl:
          'Het dagelijkse werk van een integratiemotor: een ADT^A01 komt '
          'binnen als v2-bericht met pipes, de segmenten worden ontleed, '
          'opnames worden behouden en het verblijf wordt vertaald naar een '
          'FHIR Encounter voor het dossier. Open een bericht en wissel tussen '
          'beide weergaven om te zien wat elk formaat bewaart en verliest.',
    ),
    isEnabled: true,
    updatedAt: now.subtract(const Duration(days: 1)),
    messagesProcessed: 342,
    messagesFailed: 2,
    nodes: const <FlowNode>[
      FlowNode(
        id: 'n-hl7-src',
        type: FlowNodeType.hl7Source,
        label: 'ADT^A01 in',
        x: 60,
        y: 180,
        config: <String, dynamic>{'path': 'hl7'},
      ),
      FlowNode(
        id: 'n-hl7-filter',
        type: FlowNodeType.filter,
        label: 'Inpatient only',
        x: 300,
        y: 180,
        // PV1-2 is the patient class: I for inpatient, O for outpatient, E
        // for emergency. One letter, one position - which is the whole
        // character of v2 in a single field.
        config: <String, dynamic>{
          'path': 'PV1.2',
          'operator': 'equals',
          'value': 'I',
        },
      ),
      FlowNode(
        id: 'n-hl7-fhir',
        type: FlowNodeType.hl7ToFhir,
        label: 'v2 → FHIR',
        x: 540,
        y: 180,
        config: <String, dynamic>{'target': 'encounter'},
      ),
      FlowNode(
        id: 'n-hl7-store',
        type: FlowNodeType.fhirStore,
        label: 'FHIR server',
        x: 800,
        y: 90,
      ),
      FlowNode(
        id: 'n-hl7-ehr',
        type: FlowNodeType.applicationDestination,
        label: 'EHR',
        x: 800,
        y: 270,
        config: <String, dynamic>{'app': 'EHR'},
      ),
    ],
    connections: const <FlowConnection>[
      FlowConnection(
        id: 'c-hl7-1',
        fromNodeId: 'n-hl7-src',
        toNodeId: 'n-hl7-filter',
      ),
      FlowConnection(
        id: 'c-hl7-2',
        fromNodeId: 'n-hl7-filter',
        toNodeId: 'n-hl7-fhir',
      ),
      FlowConnection(
        id: 'c-hl7-3',
        fromNodeId: 'n-hl7-fhir',
        toNodeId: 'n-hl7-store',
      ),
      FlowConnection(
        id: 'c-hl7-4',
        fromNodeId: 'n-hl7-fhir',
        toNodeId: 'n-hl7-ehr',
      ),
    ],
  ),
  IntegrationFlow(
    id: 'flow-vitals',
    name: const LocalizedText(
      en: 'Device vitals to the record',
      fr: 'Signes vitaux vers le dossier',
      nl: 'Vitale functies naar het dossier',
    ),
    description: const LocalizedText(
      en:
          'Takes every reading the connected devices publish, checks it is '
          'valid FHIR, adds the patient demographics, then stores it on the '
          'FHIR server and pushes it to the EHR.',
      fr:
          'Reçoit chaque mesure publiée par les appareils connectés, vérifie '
          "qu'il s'agit de FHIR valide, ajoute les données démographiques du "
          'patient, puis stocke la ressource sur le serveur FHIR et la '
          "transmet à l'EHR.",
      nl:
          'Ontvangt elke meting van de aangesloten apparaten, controleert of '
          'het geldige FHIR is, voegt de demografische gegevens van de patiënt '
          'toe en slaat de resource op de FHIR-server op en stuurt ze naar het '
          'EPD.',
    ),
    isEnabled: true,
    updatedAt: now.subtract(const Duration(days: 3)),
    messagesProcessed: 1284,
    messagesFailed: 6,
    nodes: const <FlowNode>[
      FlowNode(
        id: 'n-vitals-src',
        type: FlowNodeType.deviceSource,
        label: 'Device feed',
        x: 60,
        y: 180,
      ),
      FlowNode(
        id: 'n-vitals-val',
        type: FlowNodeType.validator,
        label: 'Valid FHIR?',
        x: 300,
        y: 180,
      ),
      FlowNode(
        id: 'n-vitals-enr',
        type: FlowNodeType.enricher,
        label: 'Add patient',
        x: 540,
        y: 180,
        config: <String, dynamic>{
          'path': 'subject.reference',
          'target': 'patient',
        },
      ),
      FlowNode(
        id: 'n-vitals-fhir',
        type: FlowNodeType.fhirStore,
        label: 'FHIR server',
        x: 800,
        y: 90,
      ),
      FlowNode(
        id: 'n-vitals-ehr',
        type: FlowNodeType.applicationDestination,
        label: 'EHR',
        x: 800,
        y: 270,
        config: <String, dynamic>{'app': 'EHR'},
      ),
    ],
    connections: const <FlowConnection>[
      FlowConnection(
        id: 'c-vitals-1',
        fromNodeId: 'n-vitals-src',
        toNodeId: 'n-vitals-val',
      ),
      FlowConnection(
        id: 'c-vitals-2',
        fromNodeId: 'n-vitals-val',
        toNodeId: 'n-vitals-enr',
      ),
      FlowConnection(
        id: 'c-vitals-3',
        fromNodeId: 'n-vitals-enr',
        toNodeId: 'n-vitals-fhir',
      ),
      FlowConnection(
        id: 'c-vitals-4',
        fromNodeId: 'n-vitals-enr',
        toNodeId: 'n-vitals-ehr',
      ),
    ],
  ),
  IntegrationFlow(
    id: 'flow-adt',
    name: const LocalizedText(
      en: 'ADT movements fan-out',
      fr: 'Diffusion des mouvements ADT',
      nl: 'Verspreiding van ADT-bewegingen',
    ),
    description: const LocalizedText(
      en:
          'Routes each admission, transfer and discharge to the systems that '
          'care about it. An admission opens the record in the EHR; a '
          'discharge tells the pharmacy to close the prescriptions.',
      fr:
          'Achemine chaque admission, transfert et sortie vers les systèmes '
          "concernés. Une admission ouvre le dossier dans l'EHR ; une sortie "
          'demande à la pharmacie de clôturer les prescriptions.',
      nl:
          'Stuurt elke opname, overplaatsing en ontslag naar de systemen die '
          'ze nodig hebben. Een opname opent het dossier in het EPD; een '
          'ontslag laat de apotheek de voorschriften afsluiten.',
    ),
    isEnabled: true,
    updatedAt: now.subtract(const Duration(days: 1)),
    messagesProcessed: 342,
    messagesFailed: 2,
    nodes: const <FlowNode>[
      FlowNode(
        id: 'n-adt-src',
        type: FlowNodeType.adtSource,
        label: 'ADT events',
        x: 60,
        y: 200,
      ),
      FlowNode(
        id: 'n-adt-route',
        type: FlowNodeType.router,
        label: 'By movement type',
        x: 300,
        y: 200,
        config: <String, dynamic>{
          'path': 'type',
          'routes': <dynamic>[
            <String, dynamic>{'value': 'admission', 'port': 'admission'},
            <String, dynamic>{'value': 'transfer', 'port': 'transfer'},
            <String, dynamic>{'value': 'discharge', 'port': 'discharge'},
          ],
          'defaultPort': 'admission',
        },
      ),
      FlowNode(
        id: 'n-adt-ehr',
        type: FlowNodeType.applicationDestination,
        label: 'EHR: open record',
        x: 600,
        y: 60,
        config: <String, dynamic>{'app': 'EHR'},
      ),
      FlowNode(
        id: 'n-adt-bed',
        type: FlowNodeType.applicationDestination,
        label: 'EHR: update location',
        x: 600,
        y: 200,
        config: <String, dynamic>{'app': 'EHR'},
      ),
      FlowNode(
        id: 'n-adt-pharm',
        type: FlowNodeType.applicationDestination,
        label: 'PHARM: close orders',
        x: 600,
        y: 340,
        config: <String, dynamic>{'app': 'PHARM'},
      ),
    ],
    connections: const <FlowConnection>[
      FlowConnection(
        id: 'c-adt-1',
        fromNodeId: 'n-adt-src',
        toNodeId: 'n-adt-route',
      ),
      FlowConnection(
        id: 'c-adt-2',
        fromNodeId: 'n-adt-route',
        toNodeId: 'n-adt-ehr',
        fromPort: 'admission',
      ),
      FlowConnection(
        id: 'c-adt-3',
        fromNodeId: 'n-adt-route',
        toNodeId: 'n-adt-bed',
        fromPort: 'transfer',
      ),
      FlowConnection(
        id: 'c-adt-4',
        fromNodeId: 'n-adt-route',
        toNodeId: 'n-adt-pharm',
        fromPort: 'discharge',
      ),
    ],
  ),
  IntegrationFlow(
    id: 'flow-spo2-alert',
    name: const LocalizedText(
      en: 'Low SpO2 alert',
      fr: 'Alerte SpO2 basse',
      nl: 'Alarm lage SpO2',
    ),
    description: const LocalizedText(
      en:
          'Watches the oxygen saturation readings and raises an alert when '
          'one drops below 92%. Everything else is dropped, so the alert '
          'channel stays quiet until it matters.',
      fr:
          'Surveille les mesures de saturation en oxygène et déclenche une '
          'alerte lorsque l\'une d\'elles descend sous 92 %. Le reste est '
          'écarté, afin que le canal d\'alerte reste silencieux tant qu\'il '
          'n\'y a rien à signaler.',
      nl:
          'Bewaakt de zuurstofsaturatiemetingen en slaat alarm zodra er een '
          'onder 92% zakt. De rest wordt weggefilterd, zodat het alarmkanaal '
          'stil blijft tot het ertoe doet.',
    ),
    isEnabled: true,
    updatedAt: now.subtract(const Duration(hours: 5)),
    messagesProcessed: 1284,
    messagesFailed: 0,
    nodes: const <FlowNode>[
      FlowNode(
        id: 'n-spo2-src',
        type: FlowNodeType.deviceSource,
        label: 'Device feed',
        x: 60,
        y: 160,
      ),
      FlowNode(
        id: 'n-spo2-is',
        type: FlowNodeType.filter,
        label: 'Is it SpO2?',
        x: 280,
        y: 160,
        config: <String, dynamic>{
          'path': 'code.coding.0.code',
          'operator': 'equals',
          'value': '2708-6',
        },
      ),
      FlowNode(
        id: 'n-spo2-low',
        type: FlowNodeType.filter,
        label: 'Below 92%?',
        x: 520,
        y: 160,
        config: <String, dynamic>{
          'path': 'valueQuantity.value',
          'operator': 'lessThan',
          'value': '92',
        },
      ),
      FlowNode(
        id: 'n-spo2-map',
        type: FlowNodeType.mapper,
        label: 'Build alert',
        x: 760,
        y: 160,
        config: <String, dynamic>{
          'mappings': <dynamic>[
            <String, dynamic>{
              'source': '',
              'target': 'severity',
              'transform': 'constant',
              'argument': 'high',
            },
            <String, dynamic>{
              'source': 'subject.reference',
              'target': 'patient',
              'transform': 'stripPrefix',
              'argument': 'Patient/',
            },
            <String, dynamic>{
              'source': 'valueQuantity.value',
              'target': 'spo2',
              'transform': 'toNumber',
            },
            <String, dynamic>{
              'source': 'effectiveDateTime',
              'target': 'measuredAt',
              'transform': 'none',
            },
            <String, dynamic>{
              'source': 'device.reference',
              'target': 'device',
              'transform': 'stripPrefix',
              'argument': 'Device/',
            },
          ],
        },
      ),
      FlowNode(
        id: 'n-spo2-log',
        type: FlowNodeType.logDestination,
        label: 'Alert log',
        x: 1000,
        y: 160,
      ),
    ],
    connections: const <FlowConnection>[
      FlowConnection(
        id: 'c-spo2-1',
        fromNodeId: 'n-spo2-src',
        toNodeId: 'n-spo2-is',
      ),
      FlowConnection(
        id: 'c-spo2-2',
        fromNodeId: 'n-spo2-is',
        toNodeId: 'n-spo2-low',
      ),
      FlowConnection(
        id: 'c-spo2-3',
        fromNodeId: 'n-spo2-low',
        toNodeId: 'n-spo2-map',
      ),
      FlowConnection(
        id: 'c-spo2-4',
        fromNodeId: 'n-spo2-map',
        toNodeId: 'n-spo2-log',
      ),
    ],
  ),
];
