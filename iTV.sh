#!/bin/bash
#
# Created by André Carvalho in July 2020
#
root="$PWD"

helpFunction()
{
	echo ""
	echo "Usage: $0 -p port number -u url -m project submodules -e scripts to run after -b branch name" ""
	echo "\t-p Port number for your vpn. eg: 5000"
	echo "\t-u Url for the project. eg: www.github.com/Andr3Carvalh0/iTV_initializer"
	echo "\t-m [OPTIONAL] Submodules names separated by comma. eg: If the project has 2 submodules called a and b submodules would be a,b"
	echo "\t-e [OPTIONAL] Scripts to run after cloned separated by comma. The path is relative to the clone project"
	echo "\t-b [OPTIONAL] Branch name"
	exit 1
}

fail()
{
	echo ""
	echo "Something went wrong..."
	exit 1
}

while getopts "p:u:m:e:b:" opt
do
	case "$opt" in
		p ) port="$OPTARG" ;;
		u ) url="$OPTARG" ;;
		m ) IFS=',' read -r -a submodules <<< "$OPTARG, " ;;
		e ) IFS=',' read -r -a scripts <<< "$OPTARG" ;;
		b ) branch="$OPTARG" ;;
		? ) helpFunction ;;
	esac
done

if [ -z "$port" ] || [ -z "$url" ]
then
	echo "The port number or project url are missing...";
	helpFunction
fi

echo "Validating configuration..."
IFS='/' read -r -a tmp <<< "$url"
project=${tmp[${#tmp[@]} - 1]}

if [ ${#submodules[@]} -eq 0 ]
then
	submodules=( "" )
fi

echo "Cloning project & its submodules..."
if [ -z "$branch" ]
then
	echo "Cloning using the default branch..."
	git -c http.sslVerify=false -c http.proxy=localhost:"$port" -c https.proxy=localhost:"$port" clone --recurse-submodules $url.git || fail 
else
	echo "Cloning $branch branch..."
	git -c http.sslVerify=false -c http.proxy=localhost:"$port" -c https.proxy=localhost:"$port" clone --recurse-submodules --branch "$branch" $url.git || fail 
fi

echo "Configuring project & submodules..."

for i in "${submodules[@]}"
do
	if [ -d $root/$project/$i ] 
	then
		if [ -z "${i// }" ]
		then
		    echo "Configuring main project..."
		else
		    echo "Configuring $i submodule..."
		fi

		cd $root/$project/$i
		git config http.proxy localhost:"$port"
		git config https.proxy localhost:"$port"
		git config http.sslVerify false
	else
		echo "Failed to process $root/$project/$i"
	fi
done

for i in "${scripts[@]}"
do
	if [ -f $root/$project/$i ] 
	then
		filename=$(basename -- "$root/$project/$i")
		directory=$(dirname "$root/$project/$i")
		echo "Executing $filename script..."
		cd $directory
		sh ./$filename
	else
		echo "Post script ($root/$project/$i) doesnt exist..."
	fi
done

echo "Self-cleanup..."
rm -- "$root/$0"

echo "Done!"