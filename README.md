# Universal TV Remote (iOS)

Application iOS de télécommande universelle pour TV/box via réseau local.

## Objectif

- **Une seule app** pour contrôler Roku, Google Cast et autres TV compatibles.
- **Découverte LAN** (SSDP + mDNS/Bonjour).
- **Télécommande complète** (navigation, volume, lecture, etc.).
- **Casting média** avec fallback AirPlay.
- **Commandes vocales** (Speech framework).
- **Architecture modulaire** via drivers/adapters.

## Pré-requis

- iOS 16+
- Xcode 15+
- Accès réseau local (LAN Wi-Fi)

## Configuration Xcode

1. Ouvre `UniversalTVRemote.xcodeproj` dans Xcode (la racine contient le projet et le README).
2. Vérifie l’identifiant de bundle et l’équipe de signature si besoin.
3. Les sources sont organisées dans `UniversalTVRemote/` et les tests dans `UniversalTVRemoteTests/` (structure Xcode classique).
4. Les frameworks système requis sont utilisés via `import` (Speech, AVFoundation, PhotosUI, Network).

## Permissions iOS (Info.plist)

Ajoute les clés suivantes :

- `NSLocalNetworkUsageDescription`: "Découverte et contrôle des appareils TV sur le réseau local."
- `NSBonjourServices`: `[_roku._tcp, _googlecast._tcp]`
- `NSMicrophoneUsageDescription`: "Commandes vocales."
- `NSSpeechRecognitionUsageDescription`: "Reconnaissance des commandes vocales."
- `NSPhotoLibraryUsageDescription`: "Sélection de photos/vidéos à caster."

## Architecture

```
App/
Core/
  Discovery/
  Models/
  Networking/
  Persistence/
  Remote/
  Casting/
Drivers/
Tests/
```

### Interfaces clés

- `TVDriver` : contrat commun pour chaque marque/protocole.
- `DeviceDiscoveryService` : scan LAN (SSDP + Bonjour).
- `DriverRegistry` : sélection automatique d’un driver.
- `CommandRouter` : point d’entrée unique pour les commandes.

## Drivers implémentés

### Réel
- **Roku (ECP HTTP)** : navigation, volume, lecture, texte, launch apps.

### Intégrations à compléter (stubs)
- **Google Cast** : nécessite Google Cast iOS SDK (GCKSessionManager, etc.).
- **LG webOS** : pairing via websocket (`ws://<ip>:3000`).
- **Samsung Tizen** : websocket (`wss://<ip>:8002`).
- **Sony Bravia** : JSON-RPC `/sony/system` + pairing par PIN.
- **DLNA/UPnP** : SOAP AVTransport.

## Casting

- **Chromecast** via SDK officiel (à intégrer).
- **Roku** : nécessite une app channel compatible (TODO).
- **Fallback** : AirPlay via feuille de partage iOS.

## Tests unitaires (XCTest)

- `VoiceCommandRouterTests`
- `DriverRegistryTests`
- `SSDPParsingTests`
- `RemoteViewModelTests`
- `DeviceDiscoveryViewModelTests`

## Ajouter un driver

1. Créer un type `MyBrandDriver` conforme à `TVDriver`.
2. Définir `capabilities`.
3. Implémenter `connect`, `send`, `sendText`, `launch`, `castMedia`.
4. Enregistrer dans `DefaultDriverRegistry`.

## Limitations connues

- Certaines marques exigent des API cloud (SmartThings, etc.).
- Les intégrations Cast/webOS/Tizen/Bravia sont structurées mais nécessitent pairing + endpoints officiels.

---

> Tout le code est documenté en français et extensible pour des intégrations supplémentaires.
