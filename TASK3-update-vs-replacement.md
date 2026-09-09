# Task 3 : mise à jour en place vs remplacement forcé

## Ce qui a été observé

### Changement 1 : restart policy (no vers unless-stopped)

restart = "no" -> "unless-stopped"
Plan: 0 to add, 1 to change, 0 to destroy.

Le conteneur a gardé le même ID avant et après l'apply : f6975794cb57a08b098cfd5719c0d434b1dec90bfa25167dcd6bc6411e6fecbc. Docker a confirmé la nouvelle politique avec la commande d'inspection du restart policy, qui a répondu unless-stopped.

### Changement 2 : port externe (8080 vers 8081)

external = 8080 -> 8081 # forces replacement
Plan: 1 to add, 0 to change, 1 to destroy.

Le conteneur a été détruit puis recréé, avec un nouvel ID complètement différent : 8a60db2b57734feec9be4dcf9bdadd077f5fdba8fdec8ed9c40b6ebb1467710c. L'ancien conteneur a disparu, un nouveau est apparu.

## Pourquoi cette différence

Le restart policy est un attribut de comportement du conteneur. Il décrit comment Docker doit réagir si le conteneur s'arrête, mais il ne fait pas partie de la définition structurelle de l'objet lui-même. Docker peut modifier cette politique sur un conteneur déjà en cours d'exécution, sans avoir besoin d'arrêter et de recréer le processus. C'est pour cela que Terraform propose une modification en place, et que Docker a pu l'appliquer sans interruption de service.

Le mapping de port externe, en revanche, fait partie de la configuration réseau figée du conteneur au moment où Docker le crée. Le port publié est lié à l'espace de noms réseau attribué au conteneur dès sa création, ce n'est pas une valeur qu'on peut réassigner à chaud sur un objet déjà existant. L'API Docker ne propose tout simplement pas d'opération pour changer un port publié sans recréer le conteneur, c'est une contrainte de l'infrastructure sous-jacente que Terraform ne fait qu'exposer honnêtement dans son plan grâce au marqueur forces replacement.

C'est aussi ce qui explique pourquoi le second plan affichait des dizaines d'attributs supplémentaires marqués comme changeants, alors qu'on n'avait modifié que le port. Ces attributs sont calculés par Docker à la création de l'objet, donc dès que l'objet entier doit être recréé, tous ses attributs dérivés repartent de zéro, contrairement à la modification isolée du restart policy qui n'a touché qu'un seul champ, sans effet de bord sur le reste.

## Le point clé à retenir

Le plan Terraform ne décide pas arbitrairement entre modification et remplacement. Il reflète une contrainte réelle de l'API du provider concerné : certains attributs sont mutables sur l'objet vivant, d'autres sont figés à la création et nécessitent de détruire l'objet pour en créer un nouveau avec la nouvelle valeur. Lire le plan avant d'appliquer permet justement d'anticiper si un changement va provoquer une interruption de service ou non, ce qui est essentiel avant d'agir sur une infrastructure en production.
