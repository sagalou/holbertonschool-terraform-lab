# Task 2, point 8 : symboles de plan, rôle de l'état, et suppression de l'état

## Les symboles de plan Terraform

- `+` : Terraform va **créer** une ressource qui n'existe pas encore dans l'état. C'est ce qu'on voit dans le plan initial avec `docker_image.nginx` et `docker_container.web`, tous les deux marqués `+`.
- `~` : Terraform va **modifier en place** une ressource existante, sans la détruire. Ça arrive quand l'attribut changé peut être mis à jour sur l'objet réel sans le recréer, par exemple certains labels ou certaines variables.
- `-` : Terraform va **détruire** une ressource qui existe dans l'état mais qui a été retirée de la configuration.
- `-/+` : Terraform va **détruire puis recréer** la ressource. Ça se produit quand un attribut modifié ne peut pas être appliqué en place par l'API sous-jacente, par exemple changer l'image d'un conteneur peut forcer son remplacement complet plutôt qu'une mise à jour.

## Pourquoi Terraform a besoin d'un état

La configuration seule (`main.tf`) décrit une intention : "je veux une image nginx et un conteneur nommé devops-lab-web". Mais Terraform a aussi besoin de savoir quel objet réel, précis, correspond à cette intention. C'est le rôle du fichier d'état : il fait le lien entre le bloc de ressource déclaré dans le code et l'identifiant réel de l'objet créé (l'ID du conteneur Docker, son adresse IP, l'ID de l'image).

Sans état, Terraform ne pourrait pas savoir si une ressource déclarée existe déjà ou non. Il devrait soit tout recréer à chaque run, soit interroger l'intégralité de l'infrastructure à chaque fois pour deviner ce qui correspond à quoi, ce qui n'est ni fiable ni performant.

## Ce qui se passerait si le fichier d'état était supprimé alors que le conteneur existe toujours

Si `terraform.tfstate` disparaît mais que `devops-lab-web` continue de tourner sur le daemon Docker, Terraform perd toute trace de ce conteneur. À son point de vue, plus rien n'existe.

Au prochain `terraform plan`, Terraform compare sa configuration (qui déclare toujours l'image et le conteneur) à un état vide. Il va donc planifier une **création** (`+`) pour les deux ressources, pensant repartir de zéro.

Si ce plan est appliqué, deux scénarios sont possibles selon le comportement du provider Docker :
- soit la création échoue à cause d'un conflit de nom, puisqu'un conteneur nommé `devops-lab-web` existe déjà sur le daemon ;
- soit un nouveau conteneur est créé sous un nom ou une configuration légèrement différente, laissant l'ancien conteneur orphelin, toujours en cours d'exécution mais totalement invisible et non géré par Terraform.

Dans les deux cas, c'est exactement le type de conflit qu'on a vu avec la coexistence Terraform/Compose sur une même ressource : deux vérités qui divergent parce que l'outil de suivi (ici l'état) ne correspond plus à la réalité du terrain. C'est aussi pour cette raison que le sujet insiste sur le fait de traiter l'état comme sensible et de ne jamais le modifier ou le supprimer à la main.
