# Task 1 : Distinguish Terraform from Docker Compose

## 1. Choix d'outil par scénario

### a) Un développeur doit démarrer une API, une base de données et un proxy comme une seule application locale

**Outil : Docker Compose**

Compose modélise une application entière comme un ensemble de services liés entre eux (réseaux, volumes, configuration, secrets). C'est exactement le cas ici : plusieurs conteneurs qui doivent démarrer ensemble, se parler sur un même réseau, et être gérés comme un tout cohérent avec `docker compose up`, `logs`, `down`. Terraform n'apporte rien de plus ici, il ajouterait de la complexité (état, plan) pour un besoin qui est avant tout applicatif et local.

### b) Une équipe plateforme a besoin de plans revus, d'état et de détection de drift pour des ressources à travers plusieurs API d'infrastructure

**Outil : Terraform**

C'est le cas d'usage central de Terraform : gérer des ressources déclarées à travers différentes API (pas seulement Docker, potentiellement du cloud, du DNS, etc.), avec un fichier d'état qui garde la trace de ce qui existe, un `plan` qui montre les changements avant de les appliquer, et une détection de drift si l'infrastructure réelle diverge de l'état enregistré. Compose n'a pas cette notion d'état persistant ni de detection de drift entre plusieurs API.

### c) Un opérateur doit inspecter un conteneur en cours d'exécution pendant un dépannage

**Outil : Docker CLI**

Une inspection ponctuelle et directe (`docker inspect`, `docker logs`, `docker exec`) ne nécessite ni la notion d'application multi-service de Compose, ni le cycle plan/state de Terraform. C'est une opération directe contre le daemon Docker, rapide et sans déclaration de ressource.

## 2. Pourquoi un provider est un adaptateur, pas une syntaxe alternative à Compose

Un provider Terraform (ici `kreuzwerker/docker`) traduit les blocs de ressources déclarés en HCL vers des appels réels à une API d'infrastructure, dans ce cas l'API Docker. Son rôle est de permettre à Terraform de parler à Docker, pas de redéfinir ce qu'est une application containerisée.

Compose, lui, définit un modèle applicatif complet : quels services existent, comment ils communiquent, quels volumes et réseaux ils partagent. Un provider Terraform n'a pas ce niveau de modélisation applicative, il expose des types de ressources individuelles (`docker_image`, `docker_container`) que Terraform gère une par une à travers son cycle plan/état/apply.

Autrement dit : le provider est la porte d'entrée technique vers une API, alors que Compose est un modèle métier pour une application multi-conteneurs. Ce ne sont pas deux façons d'écrire la même chose, ce sont deux couches différentes qui répondent à des besoins différents.

## 3. Que se passerait-il si un projet Compose et un état Terraform tentaient de posséder le même conteneur nommé

Chaque outil garde son propre système de suivi de ce qu'il croit posséder :

- Compose s'appuie sur les labels qu'il pose sur le conteneur et sur son fichier `docker-compose.yml`
- Terraform s'appuie sur son fichier d'état `terraform.tfstate`

Si les deux tentent de gérer le même conteneur nommé, chacun va agir sans connaissance de l'autre :

1. Un `docker compose up` modifie le conteneur (par exemple une variable d'environnement)
2. Un `terraform apply` ultérieur compare son état enregistré à l'état réel, détecte une différence qu'il n'a pas décidée lui même, l'interprète comme du drift, et tente de remettre le conteneur dans l'état qu'il a en mémoire, écrasant potentiellement ce que Compose venait de faire
3. Le prochain `docker compose up` repart de sa propre vision, sans savoir que Terraform est intervenu entre temps

Le résultat est un conflit silencieux et répété entre deux sources de vérité qui s'ignorent mutuellement, avec un risque réel de perte de configuration ou de destruction accidentelle. C'est pour cette raison que la règle du projet est stricte : un conteneur donné doit être possédé par un seul outil à la fois.