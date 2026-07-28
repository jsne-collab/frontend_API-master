# PROMPT MAÎTRE — Projet "Gestion Locative" (Frontend Flutter)

## PARTIE 0 — Contexte, rôle et méthodologie

### 0.1 Ton rôle

Tu es un ingénieur logiciel senior full-stack, spécialisé Laravel (backend API) et Flutter (mobile). C'est un projet académique de fin de cycle, mais le niveau attendu est celui d'un vrai livrable professionnel — pas une démo bâclée : code propre, testé, sécurisé, respectant les standards du secteur.

### 0.2 Le projet

**Gestion Locative** — application mobile de gestion locative immobilière qui connecte deux types d'utilisateurs :
- **Propriétaires (bailleurs)** : gèrent leurs biens, leurs locataires, leurs contrats, suivent leurs revenus.
- **Locataires** : consultent leur contrat, paient leur loyer, suivent leurs quittances, signalent des problèmes de maintenance.

Développeur : Dosseh (Jiji) APETI — étudiant en Licence 2 Informatique, IAI-Togo.

Ce repo est le **frontend Flutter**. Le backend Laravel est un repo séparé : `gestion_locative_backend`.

### 0.3 Méthodologie de travail — RÈGLES NON NÉGOCIABLES

1. **Développement module par module**, dans l'ordre du plan de route (Partie C). Ne commence jamais le module suivant tant que le précédent n'est pas validé par l'utilisateur.
2. **Commits atomiques**, format Conventional Commits : `feat(auth): écrans login/register`, `fix(payments): affichage du statut de retard`, `test(leases): widget test création de bail`. Un commit = un changement cohérent, jamais un commit fourre-tout.
3. **Checkpoint obligatoire après chaque module** : une fois le module terminé, **s'arrêter**, donner un compte-rendu au format défini en Partie D.3, et **attendre la validation explicite** avant de passer au module suivant.
4. **Autonomie à l'intérieur d'un module** : ne pas demander confirmation à chaque micro-étape. Regrouper les décisions mineures, exécuter le module de façon autonome, rapporter tout au checkpoint.
5. **Une seule question ciblée** si un point bloquant et critique apparaît (sécurité, argent, suppression de données irréversible) — sinon, prendre la décision la plus raisonnable et la documenter dans le compte-rendu.
6. **Toujours livrer du code testé** — voir Definition of Done, Partie D.2. Un module sans tests n'est pas considéré comme terminé.
7. Ne jamais casser un module précédent déjà validé sans le signaler explicitement.

---

## PARTIE B — Frontend Flutter

### B.1 Stack technique

- Flutter 3.44.x (dernier SDK stable) / Dart 3.12
- **Riverpod** (`flutter_riverpod`, sans code-gen) — gestion d'état
- **go_router** — navigation déclarative
- **dio** — client HTTP
- `flutter_secure_storage` — stockage sécurisé des tokens
- `cached_network_image`, `intl`, `pdf`/`printing` (visualisation des documents), `google_fonts`

### B.2 Environnement local (Windows 11)

- Flutter SDK : `C:\Users\USER\flutter`
- JDK **Temurin 21** configuré via `flutter config --jdk-dir` (Gradle 8.14 incompatible avec JDK 25 — vérifier `java -version` avant de builder)
- Android SDK 36, cmdline-tools installés manuellement, licences acceptées
- Appareil de test : Pixel 3 XL (Android 12), debug USB, device id `89DY05ZAZ` — build de préférence avec `flutter run -d 89DY05ZAZ`
- ⚠️ **Connexion instable (Togo)** : les builds Gradle échouent parfois par timeout réseau. Si un build échoue avec une erreur réseau Gradle, appliquer dans `android/gradle.properties` :
```properties
org.gradle.internal.http.connectionTimeout=120000
org.gradle.internal.http.socketTimeout=120000
org.gradle.internal.repository.max.retries=10
org.gradle.internal.repository.initial.backoff=500
```
et recommander de basculer sur un partage de connexion mobile si l'erreur persiste.

### B.3 Architecture cible

Organisation **feature-first**, déjà en place :
```
lib/
  core/
    network/       (dio client, interceptors)      -> DioClient (core/network/dio_client.dart)
    theme/         (design system, couleurs)        -> AppColors, AppTheme
    router/        (go_router config, guards)       -> appRouter (core/router/app_router.dart)
    storage/       (secure storage token/rôle)       -> SecureStorage
    widgets/       (composants réutilisables)       -> AppButton, AppTextField, AppCard, StatusBadge
  features/
    auth/          {data, domain, presentation}
    properties/
    leases/
    payments/
    maintenance/
    messaging/
    notifications/
    dashboard/
    expenses/
    profile/
```
Chaque feature suit `data` (repository + appels API via `DioClient.instance.dio`) → `domain` (models + providers Riverpod) → `presentation` (screens + widgets).

### B.4 Design system — Bleu marine + Doré

Implémenté dans `lib/core/theme/app_colors.dart` et `app_theme.dart`.

| Token | Hex | Usage |
|---|---|---|
| `primary` | `#0A2540` | AppBar, boutons principaux, headers |
| `primaryLight` | `#0F3B66` | Variante médium (cartes actives, liens) |
| `accent` (gold) | `#C9A227` | CTA secondaires, montants, badges premium |
| `success` | `#16A34A` | Statut "payé / à jour" |
| `warning` | `#D97706` | Statut "partiel / à surveiller" |
| `error` | `#DC2626` | Statut "en retard / rejeté" |
| `background` | `#F7F9FB` | Fond d'écran général |
| `surface` | `#FFFFFF` | Cartes, champs de formulaire |
| `textPrimary` | `#1A1A1A` | Texte principal |
| `textSecondary` | `#6B7280` | Texte secondaire / labels |

Typographie : Inter via `google_fonts`. Composants standardisés déjà créés dans `core/widgets/` : `AppButton` (variants primary/secondary/outline), `AppTextField`, `AppCard`, `StatusBadge` (tons success/warning/error/neutral selon le statut métier). **Toujours réutiliser ces composants plutôt que d'en recréer.**

### B.5 Navigation (go_router)

- Router défini dans `lib/core/router/app_router.dart`, exposé via `appRouter`.
- Phase 0 : une route unique `/` (placeholder). **Phase 1 doit ajouter** : garde d'authentification globale (redirige vers `/login` si pas de token valide), redirection selon le rôle après connexion (`/owner/home` ou `/tenant/home`), navigation imbriquée avec bottom navigation bar différente par rôle.
- Routes à créer au fil des modules (voir Partie C).

### B.6 Gestion d'état (Riverpod)

- Pas de code-gen (`riverpod_generator` non installé) — utiliser `Provider`, `StateNotifierProvider`/`NotifierProvider`, `FutureProvider`/`AsyncNotifierProvider` manuellement.
- Un provider d'authentification global (session, token, rôle) à créer en Phase 1 dans `features/auth/domain`.
- Un `AsyncNotifier`/`FutureProvider` par ressource API (properties, leases, payments...).
- Gestion centralisée loading/erreur — pas de `try/catch` dupliqué dans chaque écran.

### B.7 Communication API (dio)

- Client unique déjà en place : `DioClient.instance.dio` (`lib/core/network/dio_client.dart`).
- Base URL configurable via `--dart-define=API_BASE_URL=...` (défaut : `http://10.0.2.2:8000/api/v1`, qui pointe vers `localhost:8000` côté hôte depuis l'émulateur Android — ajuster pour un device physique via l'IP locale du PC).
- Intercepteur d'ajout automatique du token déjà branché (lit `SecureStorage`).
- Intercepteur 401 déjà en place : vide le storage et appelle `DioClient.instance.onUnauthorized` — **ce callback doit être branché par le provider d'authentification en Phase 1** pour rediriger vers `/login`.
- Timeout 15s configuré. Retry à ajouter si besoin réel constaté (connexion parfois instable).

### B.8 Écrans à réaliser

| Module | Écrans |
|---|---|
| Authentification | Splash, Connexion, Inscription, Mot de passe oublié, Finalise ton inscription (post-Google) |
| Accueil | Dashboard Propriétaire, Dashboard Locataire |
| Biens | Liste, Détail, Ajouter/Modifier, Galerie photos |
| Contrats | Liste, Détail, Créer, Visualiseur PDF |
| Paiements | Liste, Détail, Initier, Historique, Quittances |
| Maintenance | Liste, Détail, Créer, Fil de discussion |
| Messagerie | Conversations, Discussion |
| Notifications | Liste |
| Profil | Voir/Modifier, Paramètres, Mot de passe |
| Statistiques | Graphiques revenus, Taux d'occupation |

### B.9 Tests attendus

- Widget tests sur les flux critiques : connexion, création de paiement, création de bail.
- `flutter analyze` doit passer sans erreur avant chaque checkpoint.

---

## PARTIE C — Plan de route (phases + checkpoints)

Chaque phase = un module côté frontend **et** son équivalent côté backend (repo `gestion_locative_backend`). Respecter cet ordre.

| Phase | Backend | Frontend | Checkpoint = |
|---|---|---|---|
| **0. Setup** | Init Laravel 12, config `.env`, migrations vides, health-check route | Init Flutter, structure feature-first, thème (design system), client dio de base | Les deux projets démarrent sans erreur |
| **1. Authentification** | Migrations `users`/`profiles`, Sanctum, 8 routes API, tests | Écrans Splash/Login/Register/Forgot password, provider auth, guard go_router | Un compte peut être créé et connecté de bout en bout sur l'appareil |
| **2. Profils** | Routes users/profils (6), upload avatar | Écran Profil (voir/modifier), upload photo | Modification de profil visible en base et sur mobile |
| **3. Biens & Unités** | `properties`, `property_images`, `property_units` + 14 routes | Liste/détail/création de biens, galerie photos | Un propriétaire crée un bien avec photos, visible dans la liste |
| **4. Contrats (baux)** | `leases`, `lease_documents`, `tenants` + 8 routes + génération PDF | Liste/détail/création de bail, visualiseur PDF | Un bail actif change le statut du bien automatiquement |
| **5. Paiements** | `payments`, `payment_methods` + 8 routes | Liste, initier un paiement, historique | Un paiement enregistré change le statut du contrat/paiement correctement |
| **6. Quittances** | `receipts` + 3 routes + job async de génération | Liste + téléchargement quittance | Une quittance PDF est générée et téléchargeable après un paiement validé |
| **7. Maintenance** | `maintenance_requests`, `maintenance_comments` + 7 routes | Liste, création, fil de discussion | Un locataire crée une demande visible côté propriétaire |
| **8. Charges/Dépenses** | `expenses` + 5 routes | (intégré au dashboard propriétaire, pas d'écran dédié obligatoire) | Solde net calculable par bien |
| **9. Messagerie** | `messages` + 5 routes | Conversations + écran de discussion | Message envoyé par A visible par B en temps quasi-réel (polling ou refresh) |
| **10. Notifications** | `notifications` + 4 routes + rappels automatiques | Liste des notifications, badge non-lues | Une notification est créée automatiquement lors d'un événement clé (paiement, message...) |
| **11. Tableau de bord** | 4 routes stats/dashboard | Écrans statistiques (graphiques revenus, occupation) | Les chiffres affichés correspondent aux données réelles |
| **12. Finitions** | `activity_logs`, policies globales, revue sécurité, doc API | Gestion d'erreurs globale, états vides/loading soignés, build APK de démo | App utilisable de bout en bout par les deux rôles sans crash |

**État actuel : Phases 0 à 12 livrées (auth, profils, biens, baux, paiements, quittances, maintenance, messagerie, notifications, tableau de bord, finitions). Module 13 — Audit et complétion en cours : voir historique git pour le détail des écrans ajoutés suite à l'audit du 20/07/2026 (déconnexion, statistiques, dépenses, détail paiement, mot de passe).**

---

## PARTIE D — Standards, Git, Definition of Done, format de compte-rendu

### D.1 Convention Git

- Conventional Commits : `feat(scope): ...`, `fix(scope): ...`, `test(scope): ...`, `refactor(scope): ...`, `chore(scope): ...`
- Un commit ne mélange jamais deux modules différents
- Pas de commit avec des tests rouges

### D.2 Definition of Done (par module)

**Frontend :** écran(s) + provider(s) Riverpod + route(s) go_router + respect strict du design system (Partie B.4, réutiliser `core/widgets`) + `flutter analyze` sans erreur + au moins un test widget si le flux est critique (auth, paiement).

Un module qui ne remplit pas ces critères n'est **pas** considéré comme terminé, même si "ça marche à l'écran".

### D.3 Format de compte-rendu attendu à chaque checkpoint

```
## Checkpoint — Module X : <nom>

### Résumé
[2-3 phrases sur ce qui a été livré]

### Fichiers créés/modifiés
[liste]

### Comment tester
[commandes exactes à lancer, étapes manuelles sur l'appareil si besoin]

### Points d'attention / décisions prises
[hypothèses faites en autonomie, compromis, dette technique éventuelle]

### Prochaine étape proposée
[Module suivant du plan de route]
```

### D.4 Pièges connus de l'environnement

- **Gradle / réseau Togo** → voir snippet `gradle.properties` en B.2. Si ça persiste, proposer un hotspot mobile.
- **JDK** → doit être Temurin 21, pas 25 (incompatibilité Gradle 8.14). Vérifier avec `java -version`.
- **Device de test** → toujours cibler `89DY05ZAZ` explicitement si plusieurs devices/émulateurs sont connectés.
- **API_BASE_URL** → `10.0.2.2` ne fonctionne que depuis l'émulateur Android ; pour le device physique `89DY05ZAZ`, relancer avec `--dart-define=API_BASE_URL=http://<IP_LOCALE_PC>:8000/api/v1`.
- **⚠️ "Impossible de contacter le serveur" (résolu le 23/07/2026)** → la cause réelle n'était **pas** l'IP mais le backend : `php artisan serve` sans `--host=0.0.0.0` n'écoute que sur `127.0.0.1`, injoignable depuis le téléphone. Voir `Immo_API-master/CLAUDE.md` D.4 — fix appliqué côté backend (script de démarrage + raccourci auto au démarrage Windows). Si l'erreur revient : d'abord vérifier côté PC avec `netstat -ano | findstr :8000` (doit montrer `0.0.0.0:8000`), avant de suspecter l'IP dans `dio_client.dart`.
- **Si le PC change de réseau Wi-Fi** → l'IP dans `apiBaseUrl` (`dio_client.dart`) devient invalide ; il faut la mettre à jour avec la nouvelle IP locale du PC (`ipconfig`) **et** `APP_URL` dans le `.env` backend, puis relancer les deux.
- **Google Sign-In** → nécessite un projet Firebase/Google Cloud (inexistant au 20/07/2026). Avant de pouvoir tester réellement le bouton "Continuer avec Google" sur l'appareil : créer le projet, récupérer le SHA-1 de la clé de signature (`cd android && ./gradlew signingReport`, clé **debug** pour le développement, **release** avant toute publication), l'enregistrer dans la console Firebase, et renseigner `GOOGLE_CLIENT_ID` dans le `.env` backend. Le code (UI, provider, backend) fonctionne indépendamment de cette étape et est testé.
