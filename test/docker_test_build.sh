USER="peon"
HOME="/home/$USER"

docker_setup_build_test()
{
	apt-get --assume-yes update

	debconf-set-selections <<_EOF
postfix postfix/main_mailer_type string 'Local only'
postfix postfix/mailname string invalid
tzdata tzdata/Areas select Etc
tzdata tzdata/Zones/Etc select UTC
_EOF
	rm -f /etc/localtime /etc/timezone
	env DEBIAN_FRONTEND=noninteractive \
	    DEBCONF_NONINTERACTIVE_SEEN=true \
	    apt-get install tzdata

	apt-get --assume-yes --no-upgrade install make $*

	useradd --home-dir $HOME --create-home $USER
	passwd --delete $USER
}

docker_run_mkdebian_build_test()
{
	local top_dir="$1"
	local flavour="$2"
	local vers
	local maj
	local arch

	make --directory "$top_dir" prepare
	apt-get clean

	su --login $USER --command "$top_dir/scripts/mkdebian.sh $flavour"

	vers=$($top_dir/scripts/localversion.sh $top_dir)
	maj=$(echo "$vers" | sed -n 's/^\([0-9]\+\).*/\1/p')
	arch=$(dpkg --print-architecture)

	dpkg -i "$top_dir/out/xtchain-${flavour}-${maj}_${vers}_${arch}.deb"
}
