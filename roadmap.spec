Name: roadmap
Summary: DMP Roadmap is a Data Management Planning tool
License: MIT
Version: 3.0.1
Release: X
BuildArch: x86_64
BuildRoot: %(mktemp -ud %{_tmppath}/%{name}-%{version}-%{release}-XXXXXX)

#Notes about yum repos
#
# rh-ruby26
#   from repo centos-release-scl: yum install centos-release-scl
# percona:
#   from repo http://pulp.mgmtprod.inuits.eu/pulp/repos/private/environments/dmpuat/upstream/
# epel-release
#   yum install epel-release
# nodesource-release:
#    yum install nodesource-release
# [nodesource]
# name=Node.js Packages for Enterprise Linux 7 - $basearch
# baseurl=https://rpm.nodesource.com/pub_10.x/el/7/$basearch
# failovermethod=priority
# enabled=1
# gpgcheck=1
# gpgkey=file:///etc/pki/rpm-gpg/NODESOURCE-GPG-SIGNING-KEY-EL
#
# remi:
#
# [remi]
# name=Remi
# baseurl=http://remi.mirrors.cu.be/enterprise/7/remi/x86_64/
# enabled=1
# gpgcheck=0

# yum repo for special ruby versions
BuildRequires: centos-release-scl
# newer devtools (some gems do no compile without)
BuildRequires: scl-utils
BuildRequires: devtoolset-9

BuildRequires: rh-ruby26
BuildRequires: rh-ruby26-ruby-devel
BuildRequires: rh-ruby26-rubygem-bundler
BuildRequires: make
BuildRequires: automake
BuildRequires: autoconf
BuildRequires: libtool
BuildRequires: gcc
BuildRequires: gcc-c++
BuildRequires: mysql-devel
#TODO: uninstall mariadb first
#BuildRequires: Percona-Server-shared-56
BuildRequires: sqlite-devel
BuildRequires: openssl-devel
BuildRequires: libxml2-devel
BuildRequires: libcurl-devel
BuildRequires: readline-devel
BuildRequires: libyaml-devel
BuildRequires: libffi-devel
BuildRequires: bison
BuildRequires: nodejs >= 10

Requires: rh-ruby26
Requires: rh-ruby26-rubygem-bundler
Requires: openssl-libs
Requires: libxml2
Requires: libyaml
#TODO: uninstall mariadb first
#Requires: Percona-Server-shared-56
#Requires: Percona-Server-client-56
Requires: libXrender
Requires: libXext
Requires: libjpeg-turbo
Requires: libpng
Requires: bison
#requires repo "remi" (which has dependency on repo "epel-release"
Requires: ImageMagick7
Requires: nodejs >= 10

Source: %{name}.tar.gz

%global user roadmap

#disable creation of debug info (because it fails anyway)
%define  debug_package %{nil}

%description

%prep
%setup -q -n %{name}

%build
cd $RPM_BUILD_DIR/%{name}

# load env
source /opt/rh/rh-ruby26/enable
export PATH=vendor/bundle/ruby/2.6.0/bin:$PATH
export GEM_HOME=vendor/bundle/ruby/2.6.0
export GEM_PATH=vendor/bundle/ruby/2.6.0:$GEM_PATH
export RAILS_ENV=production

# fix ruby version from 2.6.3 (not in scl) to 2.6.2
sed -i 's/ruby ">= 2.6.3"/ruby ">= 2.6.2"/' Gemfile

# uncomment sqlite3
sed -i "s/# gem 'sqlite3'/gem 'sqlite3'/" Gemfile

# switch to higher dev tools
source /opt/rh/devtoolset-9/enable

# start installing gems into vendor/bundler folder
bundle config set path 'vendor/bundle'
bundle install --with=mysql,puma --without=pgsql

# install node modules
npm install
bin/rake yarn:install

# TODO: "rm -rf vendor/bundle/ruby/2.6.0/cache"
# That directory now contains 250MB of gemspec

# Not possible to compile assets here:
#   need to load rails which requires config/credentials.yml.enc
#   need to have working database

%install
rm -rf %{buildroot}
mkdir -p %{buildroot}/opt/%{name}

mkdir -p %{buildroot}/opt/%{name}
mkdir -p %{buildroot}/opt/%{name}/tmp
mkdir -p %{buildroot}/var/log/%{name}
mkdir -p %{buildroot}/etc/systemd/system

cp -r $RPM_BUILD_DIR/%{name}/* %{buildroot}/opt/%{name}/
cp $RPM_BUILD_DIR/%{name}/ugent/etc/systemd/%{name}.service %{buildroot}/etc/systemd/system/

%clean
rm -rf %{buildroot}

%files
%defattr(-,%{user},%{user},-)
/opt/%{name}/
/var/log/%{name}/
%attr(644,root,root) /etc/systemd/system/%{name}.service

%pre
# add user and group "roadmap"
getent group %{user} > /dev/null || groupadd -r %{user}
getent passwd %{user} > /dev/null || useradd -r -g %{user} \
    -m -s /bin/bash -c "%{name} user" %{user}

%post
cd /opt/%{name}

# load env
source /opt/rh/rh-ruby26/enable
export PATH=vendor/bundle/ruby/2.6.0/bin:$PATH
export GEM_HOME=vendor/bundle/ruby/2.6.0
export GEM_PATH=vendor/bundle/ruby/2.6.0:$GEM_PATH
export RAILS_ENV=production

# run db migration
bin/rake db:migrate &&

# generate assets
rm -rf tmp/cache
bin/rake assets:precompile || exit 1

# reload daemon
if [ ! -e /opt/%{name}/log ];then

  ln -s /var/log/%{name} /opt/%{name}/log

fi

systemctl daemon-reload &&
systemctl enable %{name} &&
systemctl restart %{name}

exit 0

%preun
if [ $1 -eq "0" ] ; then
  systemctl stop %{name}
  systemctl disable %{name}
fi
exit 0

%changelog
