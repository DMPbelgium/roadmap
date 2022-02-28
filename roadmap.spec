Name: roadmap
Summary: DMP Roadmap is a Data Management Planning tool
License: MIT
Version: 3.0.2
# "X" is replaced by jenkins at build time
Release: X
BuildArch: x86_64
BuildRoot: %(mktemp -ud %{_tmppath}/%{name}-%{version}-%{release}-XXXXXX)

#Notes about yum repos
#
# rh-ruby26
#   from repo centos-release-scl: yum install centos-release-scl
# epel-release
#   yum install epel-release
# remi
# percona-release
#   yum install https://repo.percona.com/yum/percona-release-latest.noarch.rpm
# or use the repo's from http://pulp.mgmtprod.inuits.eu/pulp/repos/private/environments/dmpuat/upstream/

# yum repo for special ruby versions
BuildRequires: centos-release-scl
# newer devtools (some gems do no compile without)
BuildRequires: scl-utils
BuildRequires: devtoolset-9

BuildRequires: rh-ruby26
BuildRequires: rh-ruby26-ruby-devel
# this bundler 1.17 is too old, so we install bundler 2.1.4 at build time
#BuildRequires: rh-ruby26-rubygem-bundler
BuildRequires: make
BuildRequires: automake
BuildRequires: autoconf
BuildRequires: libtool
BuildRequires: gcc
BuildRequires: gcc-c++
# we use Percona as mysql server
BuildRequires: Percona-Server-devel-56
BuildRequires: Percona-Server-shared-56
BuildRequires: openssl-devel
BuildRequires: libxml2-devel
BuildRequires: libcurl-devel
BuildRequires: readline-devel
BuildRequires: libyaml-devel
BuildRequires: libffi-devel
BuildRequires: bison

Requires: rh-ruby26
# this bundler 1.17 is too old, so we install bundler 2.1.4 at post install
#Requires: rh-ruby26-rubygem-bundler,
Requires: openssl-libs
Requires: libxml2
Requires: libyaml
# we use Percona as mysql server
Requires: Percona-Server-shared-56
Requires: Percona-Server-client-56
Requires: libXrender
Requires: libXext
Requires: libjpeg-turbo
Requires: libpng
Requires: bison
#requires repo "remi" (which has dependency on repo "epel-release")
Requires: ImageMagick7

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

# install newer version of bundler
gem install bundler:2.1.4

# fix ruby version from 2.6.3 (not in scl) to 2.6.2
sed -i "s/ruby '>= 2.6.3'/ruby '>= 2.6.2'/" Gemfile

# fix issue https://github.com/DMPRoadmap/roadmap/issues/3004
sed -i 's/config.log_level = :debug/config.log_level = :warn/' config/environments/production.rb

# switch to higher dev tools
# without these some gems will not compile
source /opt/rh/devtoolset-9/enable

# start installing gems into vendor/bundler folder
bundle _2.1.4_ config set --local path 'vendor/bundle'
bundle _2.1.4_ config set --local with "mysl,puma"
bundle _2.1.4_ config set --local without pgsql
bundle _2.1.4_ install

# remove temporary files
rm -rf tmp/
rm -rf vendor/bundle/ruby/2.6.0/cache

# Not possible to compile assets here:
#   need to load rails which requires config/credentials.yml.enc
#   need to have working database
#   need nodejs
#   requires too much memory
#
# Run ugent/bin/build_assets to recompile assets

%install
rm -rf %{buildroot}
mkdir -p %{buildroot}/opt/%{name}

mkdir -p %{buildroot}/opt/%{name}
mkdir -p %{buildroot}/opt/%{name}/tmp
mkdir -p %{buildroot}/var/log/%{name}
mkdir -p %{buildroot}/etc/systemd/system
mkdir -p %{buildroot}/etc/cron.d

cp -r $RPM_BUILD_DIR/%{name}/* %{buildroot}/opt/%{name}/
cp -r $RPM_BUILD_DIR/%{name}/.bundle %{buildroot}/opt/%{name}/
cp $RPM_BUILD_DIR/%{name}/ugent/etc/systemd/%{name}.service %{buildroot}/etc/systemd/system/
cp $RPM_BUILD_DIR/%{name}/ugent/cron.d/roadmap.cron %{buildroot}/etc/cron.d/roadmap

# move assets precompiled at development time
# to build assets in ugent/public, run bin/build_assets
mv %{buildroot}/opt/%{name}/ugent/public/packs %{buildroot}/opt/%{name}/public/
mv %{buildroot}/opt/%{name}/ugent/public/assets %{buildroot}/opt/%{name}/public/

%clean
rm -rf %{buildroot}

%files
%defattr(-,%{user},%{user},-)
/opt/%{name}/
/var/log/%{name}/
%attr(644,root,root) /etc/systemd/system/%{name}.service
%attr(644,root,root) /etc/cron.d/roadmap

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
# without this javascript runtime is still needed, even in production mode
export EXECJS_RUNTIME=Disabled

# install newer version of bundler
gem install bundler:2.1.4

# run db migration
# important: have a working rails configuration and database in place
bin/rails db:migrate

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
