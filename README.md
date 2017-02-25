# docker_regcatohost
Fetch a CA Certificate from a Docker Registry to the Docker Host

## HOW TO USE:
* **ARGn:** fqdn:port  (Space as seperator for multiples values)
* **Last ARG:** yes|restart (restart docker daemon) || no|norestart (do not restart docker daemon)

## EXEMPLE:	
* regcatohost.sh fqdn:port restart
* regcatohost.sh fqdn:port fqdn:port yes	
* regcatohost.sh fqdn:port no

**Docker Documentation:**
https://docs.docker.com/engine/security/certificates/

```
 {   Registry Docker ( fqdn:port ) }
                    ||
	          GET CA certificate
                    \/
 {_________Node docker_________}
 /etc/docker/certs.d/   <-- Certificate directory
 └── fqdn:port          <-- Hostname:port directory
 	 └── ca.crt   <-- CA that signed the registry certificate
```
