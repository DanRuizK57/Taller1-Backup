#!/bin/bash
echo 'Bienvenido, selecciona una opción para respaldar tu información con tar:'
echo '1) Hacer un respaldo de tipo completo'
echo '2) Hacer un respaldo de tipo diferencial'

read option

echo 'Seleccionaste la opción' $option

# Variables necesarias para realizar el backup
remote_user='ubuntu2'
remote_host='192.168.1.14'

# Rutas
local_path='/home/ubuntu/taller1/backups/files'
origin_path=$local_path'/tar_files'
destination_path='/home/'$remote_user'/taller1/backups/tar_backups'

# Obtener fecha y hora actual para colocar nombre a los backups diferenciales
timestamp=$(date "+%Y%m%d_%H%M%S")

# Lógica de los backups
if [[ $option -eq 1 ]]; then

	# Backup de tipo completo
	echo 'Seleccionaste la opción 1'

	# Nombre del archivo
	file_name='complete_backup_'$timestamp'.tar.gz'

	# Primero se comprime los archivos de forma local
	tar -cvpzf $local_path/$file_name $origin_path

	# Crea la carpeta complete_backup si no existe
	ssh $remote_user@$remote_host mkdir -p $destination_path/complete_backup

	# Se envía el backup completo a una máquina remota
	scp $local_path/$file_name $remote_user@$remote_host:$destination_path/complete_backup

elif [[ $option -eq 2 ]]; then

	# Backup de tipo diferencial
	echo 'Seleccionaste la opción 2'

	# Se comprueba si existe un backup completo hecho previamente
	if ssh $remote_user@$remote_host "[[ -d $destination_path/complete_backup ]]"; then

		# En caso de existir, se crea el backup diferencial
		differential_backups_dir=$destination_path/differential_backups/diff_$timestamp
		ssh $remote_user@$remote_host mkdir -p $differential_backups_dir

		# Obtener el último backup completo
		last_backup=$(ls -t $local_path/complete_backup_*.tar.gz | head -n 1)
		echo 'Último backup: '$last_backup

		# Obtener fecha más reciente
		last_timestamp=$(echo $last_backup | sed -r 's/.*complete_backup_([0-9]{8}_[0-9]{6}).tar.gz/\1/')

		# Cambio de formato de timestamp para que tar lo pueda entender
		formatted_timestamp=$(echo $last_timestamp | sed -r 's/([0-9]{4})([0-9]{2})([0-9]{2})_([0-9]{2})([0-9]{2})([0-9]{2})/\1-\2-\3 \4:\5:\6/')
		
		#Nombre del archivo
		file_name='diff_backup_'$timestamp'.tar.gz'

		# Comprimir archivo de forma local
		tar -cvpzf $local_path/$file_name --newer-mtime="$formatted_timestamp" $origin_path

		# Backup diferencial remoto
		scp $local_path/$file_name $remote_user@$remote_host:$differential_backups_dir/

	else 
		# En caso de que no exista, se lanza un error
		echo 'Error: Debes hacer un backup completo para poder realizar un backup diferencial'
	fi
fi
