#!/bin/bash

declare -A tableFieldsMap
declare -A tableUpdateFieldsMap
declare -A otherMap

tableFieldFile=集中库同步到中间库表.txt
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


otherMap["hermes"]="center"
otherMap["rabbitmq"]="mid"
otherMap["source_jdbc"]="center"
otherMap["target_jdbc"]="mid"
otherMap["schema"]="ERP."
tableSuffix=""

#模板文件路径
targetPath=/home/peter/dev_project/jzt_project/datax/datax.conf/product/center2mid/fixdata
repoTemplate=${targetPath}/table/tableRepo.yml
schemaTemplate=${targetPath}/table/tableSchema.yml
repoSuffix=Repo.yml
schemaSuffix=Schema.yml


for (( i=1;i<${#tables[@]};i++ ))
do
	table="${tables[$i]}"
    field="${tableFieldsMap[${table}]}"
	update_field="${tableUpdateFieldsMap[${table}]}"
	a_field="("${field//,/,a.}")"
	a_field=${a_field/,/}
	field=${field/,/}
	update_field=${update_field/,/}
	origin_table=${table/${tableSuffix}/}
	values_field="#{values:"${field}"}"
	field=${field}",sysdate"

	for (( y=0;y<${#dateFieldFileContentArr[@]};y++ ))
	do
		dateField=${dateFieldFileContentArr[$y]}
		replacement="to_char("${dateField}",'yyyy-mm-dd hh24:mi:ss') as "${dateField}
		field=$(echo ${field} | sed "s/,${dateField},/,${replacement},/ig")

		update_field=$(echo ${update_field} | sed "s/:${dateField}/:to_date@${dateField}/ig")
		values_field=$(echo ${values_field} | sed "s/,${dateField}/,to_date@${dateField}/ig")
	done

	#echo -e 'table:'$table'\nfield:'$field'\nupdate_field:'${update_field}'\na_field:'${a_field}

	newDir=${targetPath}/${table}

	rm -rf ${newDir}
	mkdir ${newDir} || echo 'exists'

	repoFileName=${table}${repoSuffix}
	sed -e "s/{values_field}/${values_field}/ig" -e "s/{origin_table}/${origin_table}/ig" -e "s/{table}/${table}/ig" -e "s/{field}/${field}/ig" -e "s/{update_field}/${update_field}/ig" -e "s/{a_field}/${a_field}/ig" ${repoTemplate} > ${newDir}/${repoFileName}
	sed -i "s/UPDATE SET a.PK=#{values:PK},/UPDATE SET /ig" ${newDir}/${repoFileName}
	
	echo "  - "${table}"/"${repoFileName} >> ${targetPath}/node.yml
	schema=${otherMap["schema"]}
	rabbitmq=${otherMap["rabbitmq"]}
	source_jdbc=${otherMap["source_jdbc"]}
	target_jdbc=${otherMap["target_jdbc"]}
	hermes=${otherMap["hermes"]}
	
	schemaFileName=${table}${schemaSuffix}
	sed -e "s/{table}/${table}/ig"  -e "s/{hermes}/${hermes}/ig" -e "s/{rabbitmq}/${rabbitmq}/ig" -e "s/{source_jdbc}/${source_jdbc}/ig" -e "s/{target_jdbc}/${target_jdbc}/ig" ${schemaTemplate} > ${newDir}/${schemaFileName}

	echo "  - "${table}"/"${schemaFileName} >> ${targetPath}/node.yml
done



