# Task 4, point 7 : definir le drift, ses causes, ses risques, et le verrouillage d'etat

## Definition du drift

Le drift (derive de configuration) apparait quand l'infrastructure reelle change sans passer par un changement correspondant dans la configuration declaree. L'etat de Terraform continue de decrire une version passee de l'objet, pendant que l'objet reel a evolue autrement, en dehors du controle de l'outil.

## Deux causes realistes de drift, observees directement dans ce lab

1. Une intervention manuelle directe sur l'infrastructure. Dans ce lab, docker rm -f devops-lab-web a supprime le conteneur en dehors de Terraform, simulant un operateur qui intervient en urgence lors d'un depannage, sans repasser par la configuration declaree ensuite.

2. Une modification en direct via un autre outil ou une autre interface. docker update --restart=no devops-lab-web a change un attribut du conteneur directement via l'API Docker, simulant par exemple un script de maintenance, une action d'un collegue, ou un changement fait depuis une interface de supervision, sans passer par le fichier de configuration Terraform.

D'autres causes realistes existent en dehors de ce lab : un service cloud qui applique automatiquement une mise a jour de securite sur une ressource, une politique d'auto-scaling qui modifie le nombre d'instances, ou un incident qui force une intervention manuelle rapide sur l'infrastructure de production.

## Le risque de laisser le drift non detecte

Si le drift n'est jamais detecte, l'etat de Terraform et l'infrastructure reelle continuent de diverger silencieusement. La prochaine personne qui consulte la configuration croit avoir une image fidele de l'infrastructure, alors que ce n'est plus le cas. Un apply ulterieur, base sur cette fausse image, peut alors provoquer des effets inattendus : ecraser une correction d'urgence legitime, recreer une ressource qu'on croyait a jour, ou masquer un probleme de securite, par exemple un restart policy affaibli qui empecherait un service de redemarrer apres un crash. Le drift non detecte erode la confiance qu'on peut accorder a la configuration comme source de verite, ce qui va a l'encontre du principe meme de l'Infrastructure as Code.

## Pourquoi les equipes utilisent un etat partage avec verrouillage plutot que des etats locaux separes

Un fichier d'etat local, comme celui utilise dans ce lab, ne fonctionne que pour une seule personne travaillant seule sur son poste. Des qu'une equipe travaille sur la meme infrastructure, chaque membre aurait sa propre copie de l'etat, qui divergerait rapidement de celle des autres, chacun pensant avoir la vue la plus a jour.

Un etat partage, stocke par exemple dans un backend distant comme un bucket cloud ou un service dedie, garantit que tout le monde travaille a partir de la meme source de verite. Le verrouillage empeche en plus que deux personnes lancent un apply en meme temps sur le meme etat : sans lui, deux applies concurrents pourraient corrompre l'etat ou produire des resultats incoherents, un peu comme deux personnes qui modifieraient le meme document en meme temps sans savoir que l'autre est en train d'ecrire. Le verrouillage garantit qu'une seule operation d'ecriture a lieu a la fois, ce qui protege l'integrite de l'etat pour toute l'equipe.
