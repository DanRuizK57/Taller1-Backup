#!/bin/bash
echo 'Bienvenido, selecciona una opción para respaldar tu información con rsync:'
echo '1) Hacer un respaldo de tipo completo'
echo '2) Hacer un respaldo de tipo diferencial'

read option

echo 'Seleccionaste la opción' $option

# Variables necesarias para realizar el backup
remote_user='ubuntu2'
remote_host='192.168.1.14'

# Rutas
origin_path='/home/ubuntu/taller1/backups/files'
destination_path='/home/'$remote_user'/taller1/backups/rsync_backups'

# Obtener fecha y hora actual para colocar nombre a los backups diferenciales
timestamp=$(date "+%Y%m%d_%H%M%S")

# Lógica de los backups
if [[ $option -eq 1 ]]; then

	# Backup de tipo completo
	echo 'Seleccionaste la opción 1'

	# Backup completo remoto
	rsync -av $origin_path/ $remote_user@$remote_host:$destination_path/complete_backup

elif [[ $option -eq 2 ]]; then

	# Backup de tipo diferencial
	echo 'Seleccionaste la opción 2'

	# Se comprueba si existe un backup completo hecho previamente
	if ssh $remote_user@$remote_host "[[ -d $destination_path/complete_backup ]]"; then

		# En caso de existir, se crea el backup diferencial
		differential_backups_dir=$destination_path/differential_backups/diff_$timestamp
		ssh $remote_user@$remote_host mkdir -p $differential_backups_dir

		# Backup diferencial remoto
		rsync -av --compare-dest=$destination_path/complete_backup/ $origin_path/ $remote_user@$remote_host:$differential_backups_dir/

	else 
		# En caso de que no exista, se lanza un error
		echo 'Error: Debes hacer un backup completo para poder realizar un backup diferencial'
	fi
fi
