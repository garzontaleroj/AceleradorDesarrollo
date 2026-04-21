# Escenario 3: Active Directory externo por NAT + WSO2 IS 7.2.0 (TST + PRIMARY)

Este escenario documenta la configuracion validada para integrar un AD externo publicado por NAT en WSO2 IS 7.2.0, manteniendo funcionales ambos dominios:

- PRIMARY (JDBC interno): usuarios y grupos por defecto, incluyendo admin.
- TST (AD secundario): usuarios y grupos del dominio externo.

---

## Objetivo

Evitar regresiones cruzadas de claims SCIM entre PRIMARY y TST.  
En este tipo de integracion, cambios globales en claims pueden dejar un dominio funcional y el otro sin Resources en las respuestas SCIM.

---

## Sintoma observado

Durante la integracion se presento este patron:

- TST devolvia totalResults pero sin Resources para Users.
- PRIMARY dejaba de mostrar admin cuando se cambiaba userid global hacia objectGuid.

Causa raiz: conflicto entre mapeos globales de claims (aplican a todos los userstores) y atributos reales de cada backend (JDBC vs AD).

---

## Configuracion validada

### 1) Userstore secundario TST

Archivo: userstores/TST.xml (o ruta equivalente en tu instalacion)

Valores clave validados:

- Manager: org.wso2.carbon.user.core.ldap.UniqueIDActiveDirectoryUserStoreManager
- ConnectionURL: ldap://192.168.1.4:389
- DomainName: TST
- UserSearchBase: DC=tst,DC=axacolpatria,DC=co
- GroupSearchBase: OU=Grupos,DC=tst,DC=axacolpatria,DC=co
- UserNameAttribute: sAMAccountName
- UserIDAttribute: objectGuid
- UserIdSearchFilter: (&(objectClass=person)(objectGuid=?))
- UserNameSearchFilter: (&(objectCategory=person)(objectClass=user)(sAMAccountName=?))
- UserNameListFilter: (&(objectCategory=person)(objectClass=user))
- GroupNameSearchFilter: (&(objectClass=group)(cn=?))
- transformObjectGUIDToUUID: true
- java.naming.ldap.attributes.binary: objectGuid
- Referral: ignore
- LDAPConnectionTimeout: 30000
- ReadTimeout: 30000
- ConnectionRetryCount: 5
- MaxSearchQueryTime: 0
- SCIMEnabled: true
- ReadOnly: true
- ReadGroups: true
- WriteGroups: false

Notas:

- Referral=ignore evita fallas por resolucion de referrals en dominios AD externos.
- SCIMEnabled debe estar activo para respuesta SCIM completa del userstore secundario.

### 2) Claims globales (compatibles con PRIMARY)

Archivo: repository/conf/claim-config.xml

Mantener estable para coexistencia con PRIMARY:

- http://wso2.org/claims/userid -> scimId

Mapeos locales usados en esta configuracion:

- http://wso2.org/claims/username -> sAMAccountName
- http://wso2.org/claims/userprincipal -> uid

Importante:

- El claim userid no debe moverse globalmente a objectGuid si deseas conservar PRIMARY con Resources completos en SCIM.

### 3) Mapeo por userstore (recomendado para coexistencia)

Cuando sea necesario diferenciar PRIMARY y TST sin impacto cruzado, configurar mapeo por userstore para TST en Claim Management:

- username (local claim) para TST -> sAMAccountName
- userid (local claim) para TST -> objectGUID
- userprincipal (local claim) para TST -> userPrincipalName (opcional)

Esto permite mantener userid global en scimId para PRIMARY, y al mismo tiempo resolver correctamente usuarios TST.

---

## Secuencia operativa recomendada

1. Aplicar TST.xml y validar recarga del userstore.
2. Verificar claim-config.xml global con userid en scimId.
3. Reiniciar WSO2 IS para aplicar cambios globales de claims.
4. Aplicar mapeos por userstore para TST (si corresponde).
5. Revalidar endpoints SCIM en ambos dominios.

---

## Validaciones SCIM

### PRIMARY (debe incluir admin con Resources)

GET /scim2/Users?domain=PRIMARY&startIndex=1&count=10

GET /scim2/Users?domain=PRIMARY&filter=userName eq admin&attributes=userName,id&startIndex=1&count=10

Resultado esperado:

- totalResults >= 1
- itemsPerPage >= 1
- Resources contiene admin

### TST (debe incluir usuarios AD)

GET /scim2/Users?domain=TST&startIndex=1&count=10

GET /scim2/Users?domain=TST&filter=userName eq jperez&attributes=userName,id&startIndex=1&count=10

Resultado esperado:

- totalResults >= 1
- itemsPerPage >= 1
- Resources no vacio

### TST grupos

GET /scim2/Groups?domain=TST&startIndex=1&count=10

Resultado esperado:

- totalResults >= 1
- itemsPerPage >= 1
- Resources no vacio

---

## Troubleshooting rapido

Si PRIMARY queda sin admin:

- Revisar userid global; debe ser scimId.
- Reiniciar WSO2 IS.

Si TST users muestra totalResults sin Resources:

- Validar SCIMEnabled=true en TST.xml.
- Validar filtros UserNameSearchFilter/UserNameListFilter para AD.
- Revisar Referral=ignore y timeouts.
- Validar mapeo por userstore para username/userid en TST.

Si TST groups aparece y users no:

- Normalmente es un problema de hidratacion de claims de usuario, no de conectividad LDAP.

---

## Estado final esperado

- PRIMARY operativo con admin visible por SCIM.
- TST operativo con usuarios y grupos AD visibles por SCIM.
- Sin necesidad de comprometer el comportamiento de un dominio para arreglar el otro.

---

## Anexo A: ejemplo completo TST.xml

Usa este ejemplo como base para entornos con AD externo por NAT. Ajusta DN, credenciales y filtros segun tu dominio.

```xml
<?xml version="1.0" encoding="UTF-8"?>
<UserStoreManager class="org.wso2.carbon.user.core.ldap.UniqueIDActiveDirectoryUserStoreManager">
	<Property name="Disabled">false</Property>
	<Property name="ReadOnly">true</Property>

	<Property name="ConnectionURL">ldap://192.168.1.4:389</Property>
	<Property name="ConnectionName">CN=Axaservicewso2Tip,OU=Service_accounts,DC=tst,DC=axacolpatria,DC=co</Property>
	<Property name="ConnectionPassword">REEMPLAZAR_PASSWORD</Property>

	<Property name="UserSearchBase">DC=tst,DC=axacolpatria,DC=co</Property>
	<Property name="UserEntryObjectClass">user</Property>
	<Property name="UserNameAttribute">sAMAccountName</Property>
	<Property name="UserNameSearchFilter">(&amp;(objectCategory=person)(objectClass=user)(sAMAccountName=?))</Property>
	<Property name="UserNameListFilter">(&amp;(objectCategory=person)(objectClass=user))</Property>

	<Property name="UserIDAttribute">objectGuid</Property>
	<Property name="UserIdSearchFilter">(&amp;(objectClass=person)(objectGuid=?))</Property>

	<Property name="GroupSearchBase">OU=Grupos,DC=tst,DC=axacolpatria,DC=co</Property>
	<Property name="GroupEntryObjectClass">group</Property>
	<Property name="GroupNameAttribute">cn</Property>
	<Property name="GroupNameSearchFilter">(&amp;(objectClass=group)(cn=?))</Property>
	<Property name="GroupNameListFilter">(objectClass=group)</Property>

	<Property name="MembershipAttribute">member</Property>
	<Property name="MemberOfAttribute">memberOf</Property>
	<Property name="BackLinksEnabled">true</Property>

	<Property name="SCIMEnabled">true</Property>
	<Property name="ReadGroups">true</Property>
	<Property name="WriteGroups">false</Property>

	<Property name="DomainName">TST</Property>
	<Property name="isADLDSRole">false</Property>

	<Property name="Referral">ignore</Property>
	<Property name="LDAPConnectionTimeout">30000</Property>
	<Property name="ReadTimeout">30000</Property>
	<Property name="ConnectionRetryCount">5</Property>
	<Property name="MaxSearchQueryTime">0</Property>

	<Property name="kdcEnabled">false</Property>
	<Property name="defaultRealmName">TST.AXACOLPATRIA.CO</Property>

	<Property name="transformObjectGUIDToUUID">true</Property>
	<Property name="java.naming.ldap.attributes.binary">objectGuid</Property>
</UserStoreManager>
```

Recomendaciones de uso:

- No mover globalmente userid a objectGuid en claim-config.xml si PRIMARY debe seguir estable.
- Si necesitas diferencias de atributos entre dominios, aplicar mapeo por userstore para TST.
- Reiniciar WSO2 IS despues de cambios globales de claims.
