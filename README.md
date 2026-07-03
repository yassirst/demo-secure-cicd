# Démo : chaîne CI/CD sécurisée

Ce mini-projet sert de support pratique pour le rapport de stage (Partie 3 et 4 du plan).
Il s'agit volontairement d'une application minimale : l'objectif n'est pas l'application
elle-même, mais d'avoir un pipeline réel et fonctionnel à montrer, capturer en
screenshots et expliquer.

## Structure du projet

```
demo-secure-cicd/
├── app.py                          # Application Flask minimale
├── requirements.txt                # Dépendances de production (épinglées)
├── requirements-dev.txt            # Dépendances de dev/test (séparées du runtime)
├── test_app.py                     # Tests unitaires
├── Dockerfile                      # Image conteneurisée, durcie
├── .dockerignore                   # Exclut les fichiers sensibles/inutiles du build
└── .github/
    ├── dependabot.yml              # Mises à jour automatiques des dépendances (pip, Docker, Actions)
    └── workflows/
        └── secure-pipeline.yml     # Le pipeline CI/CD lui-même
```

## Architecture du pipeline

```
Push / Pull Request
        │
        ▼
┌───────────────────┐
│ Lint + Tests       │  flake8, pytest
│ unitaires          │
└─────────┬──────────┘
          │
          ├──────────────┬──────────────┐
          ▼               ▼
┌──────────────┐   ┌──────────────────┐
│ SAST          │   │ SCA               │   analyse du code source
│ (Semgrep)     │   │ (pip-audit)       │   et des dépendances, en parallèle
└───────┬───────┘   └────────┬─────────┘
        └───────────┬─────────┘
                     ▼
          ┌────────────────────────┐
          │ Build image Docker      │
          │ + Scan (Trivy)          │
          └───────────┬────────────┘
                       ▼
          ┌────────────────────────┐
          │ Déploiement (staging)   │  uniquement depuis main,
          │ environnement protégé   │  uniquement si tout est vert
          └────────────────────────┘
```

## Ce que chaque étape apporte (à réutiliser en Partie 3)

| Étape | Outil | Rôle sécurité |
|---|---|---|
| Lint & tests | flake8, pytest | Détecte les erreurs le plus tôt possible (shift-left) |
| SAST | Semgrep | Analyse statique du code source à la recherche de failles (injections, secrets en dur, etc.) |
| SCA | pip-audit | Vérifie que les dépendances (bibliothèques tierces) n'ont pas de CVE connues |
| Build + Scan image | Docker, Trivy | Vérifie que l'image (y compris l'OS et les paquets système) ne contient pas de vulnérabilités critiques |
| Déploiement | GitHub Environments | Le déploiement est bloqué tant que les étapes précédentes n'ont pas réussi, et peut exiger une validation manuelle |

## Bonnes pratiques de sécurité déjà présentes dans ce projet

- **Image de base épinglée** (`python:3.12-slim`, jamais `:latest`) pour avoir des builds reproductibles
- **Utilisateur non-root** dans le conteneur (`USER app`) : principe du moindre privilège
- **Séparation des dépendances** runtime / dev (`requirements.txt` vs `requirements-dev.txt`) pour ne pas embarquer d'outils de test en production
- **`.dockerignore`** pour ne pas envoyer de fichiers sensibles (`.env`, `.git`) dans le contexte de build
- **`permissions: contents: read`** dans le workflow : le pipeline n'a que les droits minimum nécessaires
- **Pipeline qui échoue volontairement** (`exit-code: 1`) si Trivy détecte une faille critique/haute — la sécurité bloque le déploiement, elle n'est pas juste informative
- **Secrets jamais en dur** : le déploiement utiliserait `secrets.*` (stockage chiffré GitHub), jamais une valeur écrite dans le YAML
- **Déploiement conditionné à la branche `main`** et à un environnement protégé (`environment: staging`), qui peut exiger une approbation manuelle dans les paramètres du repo
- **Dependabot** (`.github/dependabot.yml`) : ouvre automatiquement des PR de mise à jour pour les dépendances Python, l'image Docker de base et les Actions GitHub utilisées — complète le SCA ponctuel (pip-audit) par une veille continue

## Comment l'utiliser

1. Crée un dépôt GitHub et pousse ce dossier tel quel (la structure `.github/workflows/` doit rester exactement à cet emplacement)
2. Va dans l'onglet **Actions** du repo : le pipeline se lance automatiquement au push
3. (Optionnel) Dans **Settings > Environments**, crée un environnement `staging` avec une règle d'approbation, pour illustrer le contrôle des accès en Partie 3
4. Fais volontairement échouer une étape (ex. casser un test, ou ajouter une dépendance avec une CVE connue) pour capturer une capture d'écran de pipeline "rouge" — utile pour montrer que les contrôles fonctionnent réellement

## Adapter pour GitLab CI

Si l'entreprise où tu es en stage utilise GitLab plutôt que GitHub, la logique reste
identique (mêmes étapes, même ordre) mais la syntaxe change : un fichier `.gitlab-ci.yml`
à la racine, avec des `stages:` et des `jobs:` plutôt que des `on:`/`jobs:` façon GitHub
Actions. Dis-le-moi si tu veux la version GitLab CI équivalente.
