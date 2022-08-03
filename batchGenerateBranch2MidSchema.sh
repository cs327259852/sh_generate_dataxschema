#!/bin/bash
declare -A tableFieldsMap
declare -A tableUpdateFieldsMap
declare -A otherMap
declare -A branchSchemaMap


tableFieldFile=分公司同步到中间库表.txt
dateFieldFile=date类型字段.txt
OLDIFS=$IFS
IFS=$'\n'
tableFieldFileCotentArr=($(cat $tableFieldFile))
dateFieldFileContentArr=($(cat $dateFieldFile))
IFS=$OLDIFS

tableName='null'
fields='null'
updateField=''

tables=()

j=0
for i in "${!tableFieldFileCotentArr[@]}";
do
{
        val=${tableFieldFileCotentArr[$i]}
		firstLetter=${val:0:1}
		if [[ "$firstLetter" == ":" ]]
			then 

			tableFieldsMap["${tableName}"]="${fields}"
			tableUpdateFieldsMap["${tableName}"]="${updateField}"

			tables[$j]=$tableName
			let j+=1
			
			tableName=${val/:/}
			fields=''
			updateField=''
			
		fi


		if [[ "$firstLetter" != ":" ]]
			then 
			fields=$fields","$val

			item="a."$val"=#{values:"$val"}"
			updateField=$updateField","$item
			
		fi

}
done

# 最后一张表处理
tableFieldsMap["${tableName}"]="${fields}"
tableUpdateFieldsMap["${tableName}"]="${updateField}"
tables[$j]=$tableName

otherMap["target_jdbc"]="mid"

tableSuffix="_1X"

declare -A branchJdbcMap
branchIds=(erp_ynmd erp_xj erp_wx erp_tj erp_sz erp_sx erp_sh erp_sd erp_sc erp_qs erp_py erp_nm erp_lz erp_kx erp_kh erp_jx erp_hz erp_hn erp_hlj erp_hlgy erp_hb erp_gz erp_gx erp_fj erp_dl erp_cq erp_cc erp_bj erp_ah erp_ag)

branchJdbcMap["erp_ag"]="erp_ag"
branchJdbcMap["erp_ah"]="erp_ah"
branchJdbcMap["erp_bj"]="erp_bj"
branchJdbcMap["erp_cc"]="erp_cc"
branchJdbcMap["erp_cq"]="erp_cq"
branchJdbcMap["erp_dl"]="erp_dl"
branchJdbcMap["erp_fj"]="erp_fj"
branchJdbcMap["erp_gx"]="erp_gx"
branchJdbcMap["erp_gz"]="erp_gz"
branchJdbcMap["erp_hb"]="erp_hb"
branchJdbcMap["erp_hlgy"]="erp_hlgy"
branchJdbcMap["erp_hlj"]="erp_hlj"
branchJdbcMap["erp_hn"]="erp_hn"
branchJdbcMap["erp_hz"]="erp_hz"
branchJdbcMap["erp_jx"]="erp_jx"
branchJdbcMap["erp_kh"]="erp_kh"
branchJdbcMap["erp_kx"]="erp_kx"
branchJdbcMap["erp_lz"]="erp_lz"
branchJdbcMap["erp_nm"]="erp_nm"
branchJdbcMap["erp_py"]="erp_py"
branchJdbcMap["erp_qs"]="erp_qs"
branchJdbcMap["erp_sc"]="erp_sc"
branchJdbcMap["erp_sd"]="erp_sd"
branchJdbcMap["erp_sh"]="erp_sh"
branchJdbcMap["erp_sx"]="erp_sx"
branchJdbcMap["erp_sz"]="erp_sz"
branchJdbcMap["erp_tj"]="erp_tj"
branchJdbcMap["erp_wx"]="erp_wx"
branchJdbcMap["erp_xj"]="erp_xj"
branchJdbcMap["erp_ynmd"]="erp_ynmd"


branchSchemaMap["erp_ag"]="JZTRERP."
branchSchemaMap["erp_ah"]="HFERP."
branchSchemaMap["erp_bj"]="BJQERP."
branchSchemaMap["erp_cc"]="CCERP."
branchSchemaMap["erp_cq"]="CQQERP."
branchSchemaMap["erp_dl"]="LNERP."
branchSchemaMap["erp_fj"]="FJNDERP."
branchSchemaMap["erp_gx"]="NNERP."
branchSchemaMap["erp_gz"]="GZQERP."
branchSchemaMap["erp_hb"]="HBQERP."
branchSchemaMap["erp_hlgy"]="XFPERP."
branchSchemaMap["erp_hlj"]="HLJERP."
branchSchemaMap["erp_hn"]="HNQERP."
branchSchemaMap["erp_hz"]="HZQERP."
branchSchemaMap["erp_jx"]="JXQERP."
branchSchemaMap["erp_kh"]="KHERP."
branchSchemaMap["erp_kx"]="SXQERP."
branchSchemaMap["erp_lz"]="LZQERP."
branchSchemaMap["erp_nm"]="NMQERP."
branchSchemaMap["erp_py"]="HNQERP."
branchSchemaMap["erp_qs"]="QXERP."
branchSchemaMap["erp_sc"]="SCQERP."
branchSchemaMap["erp_sd"]="SDQERP."
branchSchemaMap["erp_sh"]="SHERP."
branchSchemaMap["erp_sx"]="TYERP."
branchSchemaMap["erp_sz"]="GDQERP."
branchSchemaMap["erp_tj"]="TJQERP."
branchSchemaMap["erp_wx"]="JSQERP."
branchSchemaMap["erp_xj"]="XJQERP."
branchSchemaMap["erp_ynmd"]="YNQERP."

#模板文件路径
targetPath=/home/peter/dev_project/jzt_project/datax/datax.conf/product/branch2mid
repoTemplate=${targetPath}/table/tableRepo.yml
schemaTemplate=${targetPath}/table/tableSchema.yml
repoSuffix=Repo.yml
schemaSuffix=Schema.yml

for (( i=1;i<${#tables[@]};i++ ))
do
	table="${tables[$i]}"
	origin_table=${table/${tableSuffix}/}
    field="${tableFieldsMap[${table}]}"
	update_field="${tableUpdateFieldsMap[${table}]}"
	a_field="("${field//,/,a.}")"
	a_field=${a_field/,/}
	field=${field/,/}
	update_field=${update_field/,/}
	values_field="#{values:"${field}"}"
	#echo -e 'table:'$table'\nfield:'$field'\nupdate_field:'${update_field}'\na_field:'${a_field}
	field=${field}",sysdate"
	for (( y=0;y<${#dateFieldFileContentArr[@]};y++ ))
	do
		dateField=${dateFieldFileContentArr[$y]}
		replacement="to_char("${dateField}",'yyyy-mm-dd hh24:mi:ss') as "${dateField}
		field=$(echo ${field} | sed "s/,${dateField},/,${replacement},/ig")

		update_field=$(echo ${update_field} | sed "s/:${dateField}/:to_date@${dateField}/ig")
		values_field=$(echo ${values_field} | sed "s/,${dateField}/,to_date@${dateField}/ig")
	done

	newDir=${targetPath}/${table}

	rm -rf ${newDir}
	mkdir ${newDir} 

	repoFileName=${table}${repoSuffix}
	sed -e "s/{values_field}/${values_field}/ig" -e "s/{origin_table}/${origin_table}/ig" -e "s/{table}/${table}/ig" -e "s/{field}/${field}/ig" -e "s/{update_field}/${update_field}/ig" -e "s/{a_field}/${a_field}/ig" ${repoTemplate} > ${newDir}/${repoFileName}
	sed -i "s/UPDATE SET a.PK=#{values:PK},/UPDATE SET /ig" ${newDir}/${repoFileName}

	
	echo "  - "${table}"/"${repoFileName} >> ${targetPath}/node.yml

	target_jdbc=${otherMap["target_jdbc"]}
	

	for (( k=0;k<${#branchIds[@]};k++ ))
	do
		branchid=${branchIds[$k]}
		schema=${branchSchemaMap["${branchid}"]}
		source_jdbc=${branchJdbcMap[${branchid}]}
		hermes=${source_jdbc}
		schemaFileName=${table}_${branchid}${schemaSuffix}
		sed -e "s/{table}/${table}/ig" -e "s/{branch_name}/${branchid}/ig" -e "s/{schema_table}/${schema}${origin_table}/ig" -e "s/{hermes}/${hermes}/ig" -e "s/{source_jdbc}/${source_jdbc}/ig" -e "s/{target_jdbc}/${target_jdbc}/ig" ${schemaTemplate} > ${newDir}/${schemaFileName}
		
		echo "  - "${table}"/"${schemaFileName} >> ${targetPath}/node.yml
	done

	

	
done



