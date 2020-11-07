#!/bin/sh
projects=( "" "components/" "halo/" "matcha/" "mqtt/" "network/" )
ktlint_remote_version="$(curl -s -X GET https://raw.githubusercontent.com/Andr3Carvalh0/iTV_initializer/master/ktlint.txt 2> /dev/null)"
ktlint_version="${ktlint_remote_version:=0.39.0}"

fail(){
	echo ""
	echo "Something went wrong ¯\_(ツ)_/¯"
	exit 1
}

setupKtlint(){
	echo "Downloading ktlint..."
	curl -sSLO https://github.com/pinterest/ktlint/releases/download/"$ktlint_version"/ktlint || fail

	echo "Setting right permissions for it..."
	chmod a+x ktlint

	echo "Copying ktlint to /usr/local/bin/ ..."
	sudo mv ktlint /usr/local/bin/

	echo "Ktlint installed successfully!"
}

setupHooks(){
	echo "Installing git-hooks..."

	for i in "${projects[@]}"
	do
		if [ -d ./../../"$i".git/hooks ] 
		then
			cp ./pre-commit ./../../"$i".git/hooks/pre-commit
			cp ./pre-push ./../../"$i".git/hooks/pre-push
			cp ./commit-msg ./../../"$i".git/hooks/commit-msg
		fi
		
		if [ -d ./../../.git/modules/"$i"hooks ] 
		then
			cp ./pre-commit ./../../.git/modules/"$i"hooks/pre-commit
			cp ./pre-push ./../../.git/modules/"$i"hooks/pre-push
			cp ./commit-msg ./../../.git/modules/"$i"hooks/commit-msg
		fi
	done

	setupProjectRules
}

setupProjectRules(){
	echo "Setting project rules..."
	cd ../../ && ktlint --android applyToIDEAProject -y
}

echo "Verifying if ktlint is installed & up-to-date..."

installed=$(ktlint -V 2> /dev/null)

if [ "$installed" != "$ktlint_version" ]; then
	setupKtlint
fi

setupHooks
