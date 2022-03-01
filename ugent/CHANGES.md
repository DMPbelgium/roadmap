Changes to the core dmproadmap
==============================

* Only allow login with Shibboleth or ORCID.

  * Local login is only available in development mode.
    If you want to login locally in development mode,
    you'll have to assign a password using the rails cli.

  * The home page lists all organisations that have
    a wayfless entity (i.e. the shibboleth IDP) assigned to them.
    In the default dmproadmap, an organisation can
    only have one wayfless entity. We allow for
    multiple. If multiple, the domain of that
    IDP is added to name in the list.

  * Users are created automatically after returning
    from the Shibboleth IDP or ORCID.
    To make the internal user validation happy,
    passwords are generated automatically.

  * The default dmproadmap does not support login
    by ORCID, but does use its login functionality
    to assign logged in users to an orcid ("link to orcid")
    We do allow users to login with orcid.

  * Users that are created after login with shibboleth
    receive the attributes
    * `email` from `mail` (so required)
    * `surname` from `sn`
    * `firstname` from `givenname`

    So make sure that your shibboleth service provider
    maps the shibboleth attributes to `mail`, `sn` and `givenname`,
    and that the IDP provides them. Only `mail` is required.

  * Users that are created after login with ORCID
    receive the attributes
    * `email` from the primary email address in ORCID (`info.email`)
    * `firstname` from `info.first_name`
    * `surname` from `info.last_name`

    Make sure that your users return these attributes.
    Public attributes are always returned,
    trusted attributes only to trusted parties.

    Only during user creation do these attributes
    need to be returned. In other cases a match on
    orcid id suffices.

  * The automatic user creation may result in one or more users
    (so with a different email address) with the same orcid.

    If you login with orcid, and there are than one user
    with that orcid, you may select which one to use.

    Via the link "<user name>" > "Switch profile"
    users may switch to their other accounts.

  * The default dmproadmap does not allow for multiple users
    with the same orcid, but we disabled that

  * Users are automatically assigned to an organisation
    based on the domain of their email address.
    Those who cannot be assigned, are assigned
    to an organisation with name "guests".
    Those "guest" users cannot create plans.

  * on the "edit profile" page, users can only
    change their name, but nothing else.
    The reason for this is that the attribute
    `email` can only be verified by the external
    login provider (Shibboleth or ORCID).

* Changed plan "Share" tab.

  Dmproadmap distinguishes between "contributors"
  and "collaborators" of a plan, which is a distinction
  between rights (read, write) and your function (e.g. "data manager")
  within that plan.

  Collaborators (`plan.roles`) have the following attributes:

  * `user_id`
  * `plan_id`
  * `access` (flags). Here resides `owner`, `co-owner`, `editor` and `read-only`

  Contributors (`plans.contributors`) have the following attributes:

  * `email`
  * `name`
  * `orcid`
  * `affiliation`
  * `roles` (flags)

  So if you are the owner of a plan,
  and your function is "Data Manager",
  you need to manually add yourself
  as contributor and reenter your
  user data there (like email and orcid).

  We have decided to hide the link to the tab
  "Collaborator", and merge its functionality
  into the share tab. For every collaborator
  in the share tab, there is a column "contribution"
  where you can assign the corresponding "contribution roles".
  If any, a Contributor is created automatically with
  the same user data. If none, that Contributor is
  removed. "collaborator" and "contributor" share
  the same email attribute. There is no database
  level link between corresponding contributors
  and collaborators.

  P.S. one cannot add more than one collaborator to a plan
       belonging to the same user.

  P.S. the old contributor tab is still available for inspection
       replace the last part "/share" by "/contributors"

* Disabled form on org admin edit form to edit identifiers

  Roadmap only allows for one identifier per scheme per associated
  record.

  e.g. an "Org" can only have one identifier of identifier_scheme "shibboleth"

  We have one party that is part of Ghent University,
  but still has its own shibboleth identity provider: uzgent.
  They also share the same templates as such.

  For this we had to disable the uniqueness check on identifiers.
  (see config/initializers/ugent.rb)

  The org admin edit form allows admins to edit the shibboleth idp
  but provides only one input per schema. If you have multiple in store
  and you hit save, you lose the second one.

  Id management should be done in /admin/identifier

* Changed pdf/word export of a plan

  The default dmproadmap lists the names of the
  owner and co-owner, and lists the Orcid
  identifiers of all collaborators,
  but fails to show what and who they are.

  We show the "Creator(s)" (owner and co-owner)
  with name (and orcid if applicable).

  We show all "Contributors" with name
  (and orcid if applicable).

* Changed text on welcome page

* Changed icon and layout (minimal)

* Changed text on static page /help

* Changed text on static page /privacy

* Changed text on static page /termsuse

* Added an extra super admin interface (see /admin)
  so that we can create/delete/update
  models that are not managed by the default
  dmproadmap, or at least not in that way.

  Only users with super admin rights may
  access this page. There is no link
  to this page anywhere, and should
  not be.

  For example: we added a model `Ugent::OrgDomain`
    that lists domain names per organisation.
    This way we can match an email's domain
    to an organisation during user creation.

* Disabled functionality to manage schools and departments

* Added controllers for our own flavoured export of plans

  See [ugent/doc/internal_export.md](https://github.com/DMPbelgium/roadmap/blob/master/ugent/doc/internal_export.md)

  The only partner who is using this at the moment
  is the UGent Sharepoint team. They need
  information that is beyond the built in
  [dmp export](https://github.com/DMPRoadmap/roadmap/wiki/API-Documentation-V1).

  This functionality is deemed deprecated,
  and should therefore not be communicated to
  other organisations.

* Disabled link to page /public_plans

* Disabled link on /public_templates to automatically create plans

  Reason: selection procedure of template is different from the plan creation wizard
          only the raw funder template is selected, while
          in the plan creation wizard one may receive
          the customized version of that funder template
          based on your chosen organisation

* add list of templates for your organisation on page /public_templates
