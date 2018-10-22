FLYWAY_HOME=/home/centos/flyway-5.1.4



###
#Configuration definition
#ENVIRONMENT    APPLICATION user_owner		usr_owner_pwd 		user_app01 			user_app01_pwd		user_ro 		user_ro_pwd
cat > dbcreds.$$ <<EOF
integration      PROVLOC      provloc_int      pr0vL0c_summ1t26      provloc_int_app01           pr0vL0c_h1LLs1d318           provloc_int_ro           Jaguar_1s_fas2
integration      RECRED       recred_int           Recr3d_ford_Tauru5     recred_int_app01           Recr3d_S3ntra12           recred_int_ro           Recr3d_Ni55an
integration      CMSRM        cmsrm_int           cm0vL0c_int007           cmsrm_int_app01           cm0vL0c_int8pp422           cmsrm_int_ro           CMS7tah_fast3r
integration      ASSET        asset_plat_int      SgxL01a55et_plat08      asset_plat_int_app01      Wat3rguni5saf3                asset_plat_int_ro      Dark8night
integration      VERDIN       verdin_int           v3RDin_plat24           verdin_int_app01           Wat3rguni5saf3_8pp           verdin_int_ro           Dark8night_r00615
staging          PROVLOC      provloc_stg      pr0vL0c_m33t97      provloc_stg_app01           pr0vL0c_m0unta1n           provloc_stg_ro      d33p_sl0p321
staging          CMSRM        cmsrm_stg           unset                     cmsrm_stg_app01           cm0vL0c_int8pp422           cmsrm_stg_ro           CMS789_sp33dier
staging          VERDIN       verdin_stg           v3RDin_plat0615          verdin_stg_app01           Wat3rguni5saf3_8pp0615      verdin_stg_ro           Dark8night_r00
staging          RECRED       recred_stg           Recr3d_Ch3vy_Talibu     	recred_stg_app01           Recr3d_L3xu5           	recred_stg_ro   		Recr3d_T3sl8
production       PROVLOC      provloc_prd      ADD_BEFORE_DEPLOYMENT      	provloc_prd_app01           pr0vL0c_cr33k200           provloc_prd_ro   	sL1pp3ry_sL0pe
production       RECRED       recred_prd       ADD_BEFORE_DEPLOYMENT  		recred_prd_app01           Recr3d_sp8c3craf2           	recred_prd_ro   	Recr3d_ecl1pse
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