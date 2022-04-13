# Runtime requirements (for Centos 7)

(This guide about requirements is vaguely based on the wiki of [dmproadmap](https://github.com/DMPRoadmap/roadmap/wiki/Installation#requirements))

Specific packages are listed in the "Requires" statements of roadmap.spec

* Additional yum repositories (see also spec file):

  * [centos-release-scl](https://wiki.centos.org/AdditionalResources/Repositories/SCL)
  * [epel-release](https://www.cyberciti.biz/faq/installing-rhel-epel-repo-on-centos-redhat-7-x/)
  * [remi](https://www.unixmen.com/install-remi-repository-rhel-centos-scientific-linux-76-x5-x-fedora-201918/)
  * [percona-release](https://www.percona.com/doc/percona-server/8.0/installation/yum_repo.html)

  Or simply execute these commands:

  ```
  yum install centos-release-scl epel-release
  yum install http://rpms.famillecollet.com/enterprise/remi-release-7.rpm
  yum install https://repo.percona.com/yum/percona-release-latest.noarch.rpm
  ```

* `Ruby >= 2.6.2`. According to the original guide it should be version `2.6.3`, but that version is not (yet) included in the yum repository [centos-release-scl](https://wiki.centos.org/AdditionalResources/Repositories/SCL), and we do not want to work with [rvm](https://rvm.io/) on a production server. We tested with version `2.6.2`, which is included, and that seemed to work. The rpm spec file `roadmap.spec` replaces the ruby version in the `Gemfile` during the build process. The spec file requires the right package (`rh-ruby26`) during build and installation.

* `MySQL >= 5.5`. We choose [Percona 5.6](https://www.percona.com/downloads/Percona-Server-5.6/LATEST/) which is installed at the production database server. For local development one can use a different implementation.

* `ImageMagick`, used by the [Dragonfly gem](https://github.com/markevans/dragonfly) to manage logos. Apparently that gem uses the command `convert` directly so no development packages are needed to build packages like `RMagic` or so. For Centos 7 we use package `ImageMagick7` from repo `remi`

# Build requirements (for Centos 7)

Specific packages are listed in the "BuildRequires" statements of roadmap.spec

* Additional yum repositories (see also spec file):

  * [centos-release-scl](https://wiki.centos.org/AdditionalResources/Repositories/SCL)
  * [epel-release](https://www.cyberciti.biz/faq/installing-rhel-epel-repo-on-centos-redhat-7-x/)
  * [remi](https://www.unixmen.com/install-remi-repository-rhel-centos-scientific-linux-76-x5-x-fedora-201918/)
  * [percona-release](https://www.percona.com/doc/percona-server/8.0/installation/yum_repo.html)

  Or simply execute these commands:

  ```
  yum install centos-release-scl epel-release
  yum install http://rpms.famillecollet.com/enterprise/remi-release-7.rpm
  yum install https://repo.percona.com/yum/percona-release-latest.noarch.rpm
  ```

* `Ruby >= 2.6.2`. According to the original guide it should be version `2.6.3`, but that version is not (yet) included in the yum repository [centos-release-scl](https://wiki.centos.org/AdditionalResources/Repositories/SCL), and we do not want to work with [rvm](https://rvm.io/) on a production server. We tested with version `2.6.2`, which is included, and that seemed to work. The rpm spec file `roadmap.spec` replaces the ruby version in the `Gemfile` during the build process. The spec file requires the right package (`rh-ruby26`) during build and installation.

* `MySQL >= 5.5`. We choose [Percona 5.6](https://www.percona.com/downloads/Percona-Server-5.6/LATEST/) which is installed at the production database server. For local development one can use a different implementation.

* `ImageMagick`, used by the [Dragonfly gem](https://github.com/markevans/dragonfly) to manage logos. Apparently that gem uses the command `convert` directly so no development packages are needed to build packages like `RMagic` or so. For Centos 7 we use package `ImageMagick7` from repo `remi`

* `nodejs` `>=10`. This is only necessary to build the asset pipeline, which depends on webpack:

  ```
  ugent/bin/build_assets
  ```

  That executable not only compiles the assets for production, but also copies the files to `ugent/public`.
  That last folder is in git, so no compilation of assets is needed on a rpm build server.
  The build step of the rpm simply copies `ugent/public/*` to `public/`.

  Hopefully no production depended variables will be inserted in the future.


# Installation (for Centos 7)

## Create database

**Important**: **DO NOT create a new database**, as stated in the wiki from roadmap.
This repository depends on a database, migrated from DMPOnline_v4 (with local additions),
that has more attributes than the regular one.

Migrated data will be provided

## Install ruby dependencies

```
gem install bundler:2.1.4
bundle _2.1.4_ config set --local path "vendor/bundle"
bundle _2.1.4_ config set --local with "mysl,puma"
bundle _2.1.4_ config set --local without pgsql
bundle _2.1.4_ install
```

If bundler is updated, you update these statements

in `roadmap.spec` the bundler version from rh-ruby26-rubygem-bundler
is not used as that bundler is too old (1.17)

## Add/Update config/database.yml

config/database.yml:

```
default: &default
  adapter: mysql2
  database: roadmap
  username: roadmap
  password: roadmap
  encoding: utf8mb4

development: *default
production: *default
```

## Add/Update config/credentials.yml.enc

Add or update the encrypted `config/credentials.yml.enc` ..

```
EDITOR=vim bin/rails credentials:edit
```

and edit

```
# Used as the base secret for all MessageVerifiers in Rails, including the one protecting cookies.
secret_key_base: "replace_with_your_secret_key"

# used in config/initializers/devise.rb
devise_pepper: "replace_with_your_pepper"

#used in config/initializers/dragonfly.rb
dragonfly_secret: "replace_with_your_dregaonfly_secret"

# used in recaptcha.rb
recaptcha:
 site_key: 'replace_this_with_your_public_key'
 secret_key: 'replace_this_with_your_private_key'
```

This will generate a `config/master.key` which should NOT be included
in the git repository.

The encrypted `config/credentials.yml.enc` is a Rails 5.2 replacement
of `config/secrets.yml`. Rails expects you to include this file
(and not the master.key) in git, but in our case it is better to not
include this file as well, as it contains environment specific information.

So these files should be added by puppet:

* config/master.key
* config/credentials.yml.enc

That last file cannot be created by puppet unfortunately,
and should be provided by the developers

# Run

```
bin/rails server [any arguments]
```

or

```
bin/start [any arguments]
```

That last command does almost the same as the first,
but differences as such:

* changes to the application directory
* loads `env.sh` into the current bash environment
* starts rails with arguments given from the CLI

So it can be run from an absolute location,
which is handy in a systemd file (see above)

# Relation with base repository from DCC

This git repository is a fork of [roadmap](https://github.com/DMPRoadmap/roadmap) from the DCC,
with a lot of local additions, which are documented in `ugent/CHANGES.txt`

You will need to add the base repository of the DCC as a git remote.

## update to latest changes from the base repository

If you want to be up to date with the latest changes in the DCC repository,
do the following:

* add base repository as a new git remote (if you haven't already):

```
git remote add dcc https://github.com/DMPRoadmap/roadmap
```

* pull in the latest changes

```
git checkout master
git pull dcc master
```

* resolve any merge conflicts

* read ugent/CHANGES.txt and see if the changes mentioned are still
  necessary, still work or need update

* always set file format to `dos` if you're using `vi(m)` because the DCC does.
  Setting this to `unix` will show unrelated differences because of different
  line endings.

* read ugent/TODO.txt and see if all still apply

## branding information

Necessary steps are taken to make sure that local
additions are kept separate from the files from
the base repository, or to make sure that merge
conflicts are reduced to small parts.

See also `ugent/CHANGES.txt` for detailed information

* use of `app/views/branded`

  this directory is added to `.gitignore` by the base repo
  we add additional `.gitignore` files in these directories directly
  to override this, and so reinclude these.

  See also https://github.com/DMPRoadmap/roadmap/wiki/Branding

  Note that any extra templates that are not in the base repository
  are ALSO added here. The mere existence of a template so does
  not always imply an accompanying source template

  e.g. app/views/branded/shared/_dev_sign_in_form.html.erb

* `config/initializers/ugent.rb`

  Reopens existing ruby models/controllers and changes/add methods

* `app/models/ugent/*.rb`

  Add extra models under namespace Ugent::
  Tables have namespace ugent_

* `app/controllers/ugent.rb`

  Add extra controllers
  Loaded from `config/routes/ugent.rb` (see below)

* `config/routes/*.rb`

  Adds additional routes
  See also load statement in `config/application.rb`

* `Gemfile.local`

  Adds additional gems
  Loaded from `Gemfile`

* `Gemfile`

  File from base repository.
  We add an extra line to include `Gemfile.local`
  Make sure this remains true when merging the upstream branch

  IMPORTANT: look at ugent/CHANGES.txt for notes about changes
             to Gemfile. If you have merged upstream changes
             it is possible that, for example, gem "wicked_pdf"
             is loaded from the main gem repository, which is
             a problem (see notes in that file about wicked_pdf)

* `config/initializers/rails_admin.rb`

  Adds [RailsAdmin](https://github.com/sferik/rails_admin)
  RailsAdmin adds a CRUD interface at /admin to edit/preview
  models that cannot be manipulated in any other way in 
  roadmap:
    * model `Ugent::RestUser` which adds organisational REST users
    * model `Ugent::WayflessEntity` (deprecated)
    * associate themes with question options
  Most of the models in the RailsAdmin are read only

* `env.sh`

  Bash environment file

  Automatically included by `bin/start`

  This is usefull to set the environment correctly before starting
  the application or use any of its command line tools.

  e.g.

  ```
  . env.sh
  bin/rails console
  ```

* `ugent/public`

  `ugent/bin/build_assets` precompiles all assets
  and copies them here, so no precompilation should
  be done on the build server

  Make sure however to set environment variable `EXECJS_RUNTIME`
  to `Disabled`, or rails will complain about missing
  javascript runtime, even in production mode

Old tables added when we used DMPOnline_v4:

* `ugent_org_domains`

* `ugent_logs`

* `ugent_wayfless_entities`

* `ugent_rest_users`

# Technical model overview

A handy overview of the available models, and their attributes:

* https://github.com/DMPRoadmap/roadmap/wiki/DB-Schema
* https://github.com/DMPRoadmap/roadmap/issues/1382#issuecomment-405252771
