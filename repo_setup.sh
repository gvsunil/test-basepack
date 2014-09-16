#
# Copyright (c) 2009    Kevin Porter / Advanced Web Construction Ltd
#                       (http://coding.tinternet.info, http://webutils.co.uk)
# Copyright (c) 2010-2012     Ruediger Meier <sweet_f_a@gmx.de>
#                             (https://github.com/rudimeier/)
#
# Simple INI file parser.
#
# See README for usage.
#
#

function read_ini()
{
        # Be strict with the prefix, since it's going to be run through eval
        function check_prefix()
        {
                if ! [[ "${VARNAME_PREFIX}" =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]] ;then
                        echo "read_ini: invalid prefix '${VARNAME_PREFIX}'" >&2
                        return 1
                fi
        }               
                
        function check_ini_file()
        {
                if [ ! -r "$INI_FILE" ] ;then
                        echo "read_ini: '${INI_FILE}' doesn't exist or not" \
                                "readable" >&2
                        return 1
                fi
        }

	# enable some optional shell behavior (shopt)
        function pollute_bash()
        {
                if ! shopt -q extglob ;then
                        SWITCH_SHOPT="${SWITCH_SHOPT} extglob"
                fi
                if ! shopt -q nocasematch ;then
                        SWITCH_SHOPT="${SWITCH_SHOPT} nocasematch"
                fi
                shopt -q -s ${SWITCH_SHOPT}
        }       	

        # unset all local functions and restore shopt settings before returning
        # from read_ini()
        function cleanup_bash()
        {
                shopt -q -u ${SWITCH_SHOPT}
                unset -f check_prefix check_ini_file pollute_bash cleanup_bash
        }

	INI_FILE=$1
        if ! check_ini_file ;then
                cleanup_bash
                return 1
        fi

        # IFS is used in "read" and we want to switch it within the loop
        local IFS=$' \t\n'
        local IFS_OLD="${IFS}"

        # we need some optional shell behavior (shopt) but want to restore
        # current settings before returning
        local SWITCH_SHOPT=""
	local LINE_NUM=0
	local SECTIONS_NUM=0
        pollute_bash

	while read -r line || [ -n "$line" ]
	do
		((LINE_NUM++))
		
                # Skip blank lines and comments
                if [ -z "$line" -o "${line:0:1}" = ";" -o "${line:0:1}" = "#" ]
                then
                        continue
                fi

                # Section marker?
                if [[ "${line}" =~ ^\[[a-zA-Z0-9_]{1,}\]$ ]]
		then
                        # Set SECTION var to name of section (strip [ and ] from section marker)
                        SECTION="${line#[}"
                        SECTION="${SECTION%]}"
			((SECTIONS_NUM++))
			echo "Processing $SECTION..."
		
			continue
		fi

		if [ "$SECTION" == "apt_sources" ]
		then
			echo "		Adding $line to apt-sources."
			sudo echo $line >> /etc/apt/sources.list
		fi

                if [ "$SECTION" == "apt_key_urls" ]
                then
                        echo "          Adding $line to apt-keys."
			URL=$line
			AFTER_SLASH=${URL##*/}
			KEY_FILE_NAME="${AFTER_SLASH%%\?*}"
			echo "          Removing existing $KEY_FILE_NAME"
			sudo rm -rf /tmp/$KEY_FILE_NAME
			echo "		Fetching $KEY_FILE_NAME"
			curl -s $line -o /tmp/$KEY_FILE_NAME
			echo "		Adding $KEY_FILE_NAME"
			sudo apt-key add /tmp/$KEY_FILE_NAME
                fi

                if [ "$SECTION" == "apt_repositories" ]
                then
                        echo "          Adding $line to apt-repositories."
			sudo add-apt-repository --yes $line
			sudo apt-get update
                fi

		if [ "$SECTION" == "apt_packages" ]
		then
			echo "		Installing $line..."
			sudo apt-get -y install $line
		fi

		if [ "$SECTION" == "virtualenv_packages" ]
		then
			echo "Installing package...$line"
			##sudo pip install $line
		fi

		if [ "$SECTION" == "virtualenv_package_sources" ]
		then
			echo "Installing package from source...$line"
			##sudo pip install -e $line
		fi

	done <"${INI_FILE}"
}

function setup_mkvirtualenv
{
	sudo apt-get update
	sudo apt-get install python-setuptools python-dev build-essential git-core -y
	sudo easy_install pip
	sudo pip install virtualenv
	sudo pip install virtualenvwrapper
	mkdir ~/virtualenvs
	echo "export WORKON_HOME=~/virtualenvs" >> ~/.bashrc
	echo "source /usr/local/bin/virtualenvwrapper.sh" >> ~/.bashrc 
	echo "export PIP_VIRTUALENV_BASE=~/virtualenvs" >> ~/.bashrc 
	source ~/.bashrc 
}

function setup_virtualenvs
{
	local VIRTUALENVS_DIR="./virtualenvs"
	for file in "$VIRTUALENVS_DIR"/*; do
		echo "Creating virtualenv $file.."
		mkvirtualenv $file
		workon $file
		read_ini $file
	done
}

#### read_ini repo-packages.ini
#### sudo apt-get -y install `cat repo-packages`
#### setup_mkvirtualenv
#### setup_virtualenvs
