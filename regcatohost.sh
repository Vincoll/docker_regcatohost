#!/bin/bash
# BY Vincoll > https://github.com/Vincoll
# WHAT: Fetch CA certificates  from a Docker registry => Install properly the cert in the docker library
# INFO: Restarting the docker registry is mandatory to take effect of the news certificates
# HOW TO USE: 
	# ARGn: fqdn:port  (Space as seperator for multiples values)
	# Last ARG: yes|restart (restart docker daemon) || no|norestart (do not restart docker daemon) 
# EXEMPLE:	
	# ./regcatohost.sh fqdn:port restart
    # ./regcatohost.sh fqdn:port fqdn:port yes	
	# ./regcatohost.sh fqdn:port no

# DOC https://docs.docker.com/engine/security/certificates/


# {   Registry Docker ( fqdn:port ) }
#                    ||
#	          GET CA certificate
#                    \/
# {_________Node docker_________}
# /etc/docker/certs.d/   <-- Certificate directory
# └── fqdn:port          <-- Hostname:port directory
# 	 └── ca.crt   <-- CA that signed the registry certificate



#TODO
#Check CA Validity

# ARGUMENTS
DOCKER_REGISTRY=$1
DOCKER_RESTART=${!#}
#GLOBAL VAR
DOCKER_DIR_CERT_LIBRARY="/etc/docker/certs.d"


usage()
{
	echo "Usage:"
	echo "         DOCKER_REGISTRY: fqdn:port  Ex: dev.registry.domain.tld:443"  # MANDATORY
	echo "         DOCKER_RESTART: Restart daemon Docker"  #
	echo "Exemple:"
	echo "./add-reg-ca.sh dev.registry.domain.tld:443 noreboot"
	exit 1
}

testregistry()
{
# {1} Registry
#  Test registry docker port
if [ $(echo "${1}" | grep -c ":") -eq 0 ]; then
	echo -e ">ERROR: Port is missing for ${1} \n \t Valid form is: fqdn:port  Ex: dev.registry.domain.tld:443"
	return 1
else
	# Reg is OK
	return 0
fi
}


getcafromreg()
{
# {1} Registry
# Get CACERT from Docker registry server
echo ">INFO: Get registry certificat from $DOCKER_REGISTRY"
echo | openssl s_client -showcerts -connect ${1} 2>&1 | sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' > ${1}.crt

if [ ! -s ${1}.crt ]; then
	echo ">ERROR: Null file."
	exit 1
fi
}


installca()
{
# {1} Registry
# Copy certificat into docker certificat folder
if [ ! -f "$DOCKER_DIR_CERT_LIBRARY/${1}/ca.crt" ]; then
	echo -e  ">INFO: New certificate create in \n \t $DOCKER_DIR_CERT_LIBRARY/${1}/ca.crt"
	mkdir -p $DOCKER_DIR_CERT_LIBRARY/${1}/
	cp -f ${1}.crt $DOCKER_DIR_CERT_LIBRARY/${1}/ca.crt
	rm ./${1}.crt
else
	# Get sha256 for test
	DL_crtsha256=$(sha256sum < ./${1}.crt)
	Existing_crtsha256=$(sha256sum < $DOCKER_DIR_CERT_LIBRARY/${1}/ca.crt)
	if [[ "${DL_crtsha256}" == "${Existing_crtsha256}" ]]; then
		echo -e  ">INFO: No difference between $DOCKER_DIR_CERT_LIBRARY/${1}/ca.crt and the new one. \n \t No Modification !"
		rm ./${1}.crt
	else
		cp -f ${1}.crt $DOCKER_DIR_CERT_LIBRARY/${1}/ca.crt
		echo -e  ">INFO: $DOCKER_DIR_CERT_LIBRARY/${1}/ca.crt Already exist but is different from the new one. \n ${crtsha256} is overwriting the old ca.crt !"
		rm ./${1}.crt
	fi
fi
}
# TESTS ____________________________________________________

#  User Tests
if [ $(id -u) != 0 ]; then
	echo ">ERROR: Root access is required."
	exit 1
fi

# Test reboot Option
 if [ "${DOCKER_RESTART}" == "restart" ] || [ "${DOCKER_RESTART}" == "yes" ] || [ "${DOCKER_RESTART}" == "norestart" ] || [ "${DOCKER_RESTART}" == "no" ]; then
 :
 else 	
	echo -e ">ERROR: Restart options is not set (restart || norestart)."
	 exit 1
 fi
 

# LOOP ON ARGS _____________________________________________

for (( i=1; i<$#; i++ )); do

	# Test arg registry docker
	testregistry ${!i}
	resultreg=$?
	if [ ${resultreg} -eq 0 ]; then
	{
	  echo ">INFO: Processing ${!i}"
	# Get CACERT from Docker registry server
		getcafromreg  ${!i}
	# Copy certificat into docker certificat folder
		installca ${!i}
	}
	fi
		
done

# RESTART Docker _________________________________________

 if [ "${DOCKER_RESTART}" == "norestart" ] || [ "${DOCKER_RESTART}" == "no" ]; then
	 echo -e ">INFO: Docker daemon HAS **NOT** BEEN restarted. A docker restart is MANDATORY to applied the new registry."
 fi

 if [ "${DOCKER_RESTART}" == "restart" ] || [ "${DOCKER_RESTART}" == "yes" ]; then
	echo -e ">INFO: Docker Daemon WILL BE restarted. The added CA should be applied."
	systemctl stop docker ;systemctl start docker ; systemctl status docker -l
 fi


echo -e "END"
exit 0
