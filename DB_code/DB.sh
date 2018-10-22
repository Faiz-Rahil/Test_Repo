FLYWAY_HOME=/home/centos/flyway-5.1.4



###
#Configuration definition
#ENVIRONMENT    APPLICATION user_owner		usr_owner_pwd 		user_app01 			user_app01_pwd		user_ro 		user_ro_pwd
cat > dbcreds.$$ <<EOF

EOF

CONFIG_FOUND=false

#Protect against Jenkins config changes including trailing white spaces
JENKINS_ENV="${environment%"${environment##*[![:space:]]}"}" 
JENKINS_APP="${application%"${application##*[![:space:]]}"}" 

## Extract the needed data
declare -a row     # Create an indexed array (necessary for the read command).                                                                                 
while read -ra row; do
    loopenv=${row[0]}
    loopapp=${row[1]}

	echo "checking Jenkins V Config - Env [${JENKINS_ENV}] v [${loopenv}] AND App [${JENKINS_APP}] v [${loopapp}]"

    if [[ "${JENKINS_ENV}" = "${loopenv}" && "${JENKINS_APP}" = "${loopapp}" ]]
    then
    	CONFIG_FOUND=true
	    owner=${row[2]}
	    owner_pwd=${row[3]}
    	owner_schema=${owner^^}
	    app01=${row[4]}
	    app01_pwd=${row[5]}
    	app01_schema=${app01^^}
	    ro=${row[6]}
	    ro_pwd=${row[7]}
    	ro_schema=${ro^^}
    fi

done < dbcreds.$$


## Remove the temporary file
rm dbcreds.$$

if [ "${CONFIG_FOUND}" = "false" ]
then
 echo "Login parameter lookup failed, exit -1"
 exit -1
fi


placeholder_schema="unset"
if [ "${environment}" = "integration" ]
then
	DB_URI=jdbc:oracle:thin:@//orasgx01.c95bmepyhidf.eu-west-1.rds.amazonaws.com:1521/orasgx01
    placeholder_schema="int"
else
	if [ "${environment}" = "staging" ]
	then
		DB_URI=jdbc:oracle:thin:@//passtage01.cd2x8ef0eshc.us-east-1.rds.amazonaws.com:1521/passtg01
        placeholder_schema="stg"
    else
		if [ "${environment}" = "production" ]
		then
			DB_URI=jdbc:oracle:thin:@//pasprod01.cd2x8ef0eshc.us-east-1.rds.amazonaws.com:1521/pasprd01
            placeholder_schema="prd"
    	fi
    fi
fi

#Variabels are now set as follows for execution
echo "###########################################"
echo "Environment ${env}"
echo " Owner 	 is ${owner} with Password is ${owner_pwd} Schema is ${owner_schema}"
echo " APP01 	 is ${app01} with Password is ${app01_pwd} Schema is ${app01_schema}"
echo " READONLY	 is ${ro} with Password is ${ro_pwd} Schema is ${ro_schema}"
echo " PlaceHolder"
echo " Schema    is ${placeholder_schema}"
echo " DB URI ${DB_URI}"
echo "###########################################"

BASEDIR="${BUILD_NUMBER}-${JENKINS_APP}-${JENKINS_ENV}"

mkdir ${BASEDIR}

cd ${BASEDIR}
pwd

rc=`curl -u admin:AP2zxRR1U22dNivF \
	-O "http://54.87.251.238:8081/artifactory/PROD-APP-SQL/${zipflle}" \
	-w "%{http_code}"`
    
if [ "$rc" != "200" ]
then
  echo "Failed to download artifact ${zipfile}, please check name"
  exit -2
fi

unzip ${zipflle}


if [ "${user_owner}" = "true" ]
then
    $FLYWAY_HOME/flyway  \
 		-user=${owner} \
        -password=${owner_pwd} \
        -schemas=${owner_schema} \
        -url=$DB_URI \
        -locations=filesystem:./db/sql/user_owner \
        -placeholders.schema=${placeholder_schema} \
        ${action}

fi



if [ "${user_app01}" = "true" ]
then
    $FLYWAY_HOME/flyway  \
 		-user=${app01} \
        -password=${app01_pwd} \
        -schemas=${app01_schema} \
        -url=$DB_URI \
        -locations=filesystem:./db/sql/user_app01 \
        -placeholders.schema=${placeholder_schema} \
        ${action}


fi

if [ "${user_ro}" = "true" ]
then
    $FLYWAY_HOME/flyway  \
 		-user=${ro} \
        -password=${ro_pwd} \
        -schemas=${ro_schema} \
        -url=$DB_URI \
        -locations=filesystem:./db/sql/user_ro \
        -placeholders.schema=${placeholder_schema} \
        ${action}


fi


cd ..

echo "Tidy up and remove ${BASEDIR}"

#rm -rf ${BASEDIR}