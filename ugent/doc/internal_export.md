Internal Exports
================

Some background
---------------

Available routes
----------------

There are, per organisation, 3 export routes, all available through HTTP Basic Auth

```
https://dmponline.be/internal/exports/v01/organisations/:name/projects.json
https://dmponline.be/internal/exports/v01/organisations/:name/updated_projects.json
https://dmponline.be/internal/exports/v01/organisations/:name/deleted_projects.json
```

The route parameter `name` is the organisation's `abbreviation`

Examples are:

```
https://dmponline.be/internal/exports/v01/organisations/UGent/projects.json
https://dmponline.be/internal/exports/v01/organisations/UGent/updated_projects.json
https://dmponline.be/internal/exports/v01/organisations/UGent/deleted_projects.json
```

In order to create your credentials, go to https://dmponline.be/admin/ugent~rest_user:

  * `code`: unique name to identify the credential. Should be unique
  * `token`: automatically generated when not provided
  * `organisation`: organisation these credentials apply to.

Provide `code` and `token` as username and password respectively to Basic Auth.

All routes return JSON, and conform to the [jsonapi schema](https://jsonapi.org/format/#document-top-level):

```
{
  "meta" : {
      "created_at" : "2021-11-21T19:00:04Z",
      "version" : "0.1"
   },
   "links" : {
      "prev" : "https://dmponline.be/internal/exports/v01/organisations/UGent/2021/11/projects_2021-11-20T19:00:17Z.json",
      "self" : "https://dmponline.be/internal/exports/v01/organisations/UGent/2021/11/projects_2021-11-21T19:00:04Z.json"
   },
  "data": [

  ]
}
```

projects.json
-------------

```
GET /internal/exports/v01/organisations/${org.abbreviation}/projects.json
```

Return the LATEST export of projects for organisation with abbreviation `${org.abbreviation}`

This url is actually a link to a more specific url, with an UTC timestamp:

```
GET /internal/exports/v01/organisations/UGent/${year}/${month}/projects_${timestamp}.json
```

Path parameters:

* `${org.abbreviation}`: abbreviated name of the organisation. e.g. `UGent`

Response:

Paged result of projects

```
{
  "meta" : {
      "created_at" : "<utc-timestamp>",
      "version" : "0.1"
   },
   "links" : {
      "prev" : "<url-to-previous-page>",
      "self" : "<canonical-version-of-current-url-with-timestamp>"
   },
  "data": [
    {

    },
    ..
  ]
}
```

Properties:

* `links`:
  * description: object with paging attributes [jsonapi]
  * properties:
    * `prev`: url of previous page of results, if any [jsonapi]
    * `next`: url of next page of results, if any [jsonapi]
    * `self`: url of the current page. Note that this url includes the timestamp [jsonapi]

* `data`:
  * description: array of projects
  * properties:
    * `id`
    * `type`: "Project"
    * `created_at`
    * `updated_at`
    * `template`:
      * description: object that describes the template that the project was generated from. Note that the whole project is derived from this template structure. Every phase becomes a "plan".
      * properties:
        * `id`
        * `created_at`
        * `updated_at`
        * `title`
        * `description`
        * `is_default`
        * `gdpr`:
          * description: boolean flag. `gdpr:true` means "yes, this project contains personal data". If the template contains an option based question with Theme `ugent:data`, and that question was answered with option  `Yes`, then this whole project is marked as `gdpr:true`. Of course, this attribute should be available in a plan object, and not in the template object, but that was the way we did it in the past.
    * `plans`:
      * description: array of plans. These plans are derived from the template's phases.
      * properties:
        * `type`: "Plan"
        * `version`:
          * description: (deprecated) object that describes a version of a phase in a template
        * `sections`
          * description: array of sections within one single plan
          * properties:
            * `id`
            * `title`
            * `number`
            * `type`: "Section"
            * `questions`:
              * description: array of questions for this section
              * properties:
                * `id`
                * `type`: "Question"
                * `question_format`:
                  * description: format of question.
                  * properties:
                    * `type`: "QuestionFormat"
                    * `title`: Maybe `Text area`, `Text field`, `Radio buttons`, `Check box`, `Dropdown`, `Multi select box` or `Date`. Some of these are option based, and therefore cannot be answered in property `answer` as such
                * `text`:
                  * description: question text
                * `number`
                * `default_value`:
                  * description: default answer for text based questions. Filled in as default in the form
                * `suggested_answers`:
                  * description: array of example answers. Read from table `annotations` with attribute `type` set to `example_answer`.
                  * properties:
                    * `id`
                    * `type`: "SuggestedAnswer"
                    * `is_example`: "true"
                    * `text`
                    * `created_at`
                    * `updated_at`
                * `answer`:
                  * description: for text based questions, this is the regular "Answer" below the question. For option based question this is the text you can provide in "Additional information". For option selected, see `selected` and `options` below.
                  * properties:
                    * `text`
                    * `type`: "Answer"
                    * `created_at`
                    * `updated_at`
                    * `user`
                      * description: user that created the answer
                      * properties:
                        * `id`
                        * `type`: "User"
                        * `email`
                        * `orcid`
                * `options`:
                  * description: array of options for an option based question
                  * properties:
                    * `id`
                    * `type`: "Option"
                    * `text`
                    * `number`
                    * `is_default`
                      * description: boolean flag that determines if this option is the default selected one
                    * `created_at`
                    * `updated_at`
                    * `themes`:
                      * description: array of themes. These themes are stored in table `question_options_themes` and can only be added in https://dmponline.be/admin/question_option
                      * properties: same as question' themes (see below)

                * `selected`:
                  * description: object of key value pairs. This represents the selected option(s). The keys correspond to the option number, the value to the option title.

                * `themes`:
                  * description: array of themes
                  * properties:
                    * `id`
                    * `type`: "Theme"
                    * `title`
                    * `created_at`
                    * `updated_at`

                * `comments`:
                  * description: array of comments to a question. In the old DMPonline_v4, these were comments to a question. But in roadmap these are records of table `notes` and attached to an answer. So, no answer, no comment.
                  * properties:
                    * `id`
                    * `type`: "Comment"
                    * `text`
                    * `created_at`
                    * `updated_at`
                    * `created_by`:
                      * description: user object that created the comment. May be `null`
                      * properties:
                        * `id`
                        * `type`: "User"
                        * `email`
                        * `orcid`
                    * `archived_at`
                    * `archived`: `true|false`

Usage
-----

In practice, these internal exports are only used by the Sharepoint Team

of Ghent University, and we do not plan on supporting it for other

organizations, given the fact that roadmap now has its own RDM API.

We hope that the Sharepoint Team will eventually be able to adopt

the newer RDM API once the standard includes the questions, answers and themes

for every plan, which is not the case today.

Software (files) and storage involved
-------------------------------------

- `config/application.rb`: includes an extra section at the end, enclosed with `# ugent: start` and `# ugent: end`, where extra routes are included. These extra routes are expected in `config/routes/*.rb` (see next). When merging upstream, keep in mind to preserve this section.

- `config/routes/ugent.rb`: adds several internal routes. For this purpose we document the following:

  - adds route `/internal/exports/v01/organisations/:abbreviation/:name.json` which links to method `show_link` in `app/controllers/ugent/internal/exports_controller.rb`. e.g. https://dmponline.be/internal/exports/v01/organisations/UGent/updated_projects.json. The method is called `show_link` because it provides a symbolic link to the latest export file with that name (see next).

  - adds route `/internal/exports/v01/organisations/:abbreviation/:year/:month/:name.json` which links to method `show_file` in `app/controllers/ugent/internal/exports_controller.rb`. e.g. https://dmponline.be/internal/exports/v01/organisations/UGent/2021/11/projects_2021-11-20T19:00:17Z.json. This is the file that `show_link` links to.

- `app/controllers/ugent/internal/exports_controller.rb`: ugent specific controller that implements above described routes. It reads JSON files from disk, and is protected by HTTP Basic Authentication. Credentials are stored in table `ugent_rest_users`, and is managed by model `UGent::RestUser`. The RailsAdmin route [/admin/ugent~rest_user](https://dmponline.be/admin/ugent~rest_user) provides a GUI to manage this

- `app/models/ugent/rest_user.rb`: Rails model that manages table `ugent_rest_users`.

- MySQL table `ugent_rest_users`. Note that this table is not created by any Rails migration. Table definition is stored in comment in the model file `app/models/ugent/rest_user.rb`

- MySQL table `question_option_themes`. This table links question options to themes. This table is a local addition, and can only by managed via [/admin/question_option](https://dmponline.be/admin/question_option), and of course via calls like `my_question_option.themes << Theme.new`

- `lib/tasks/ugent_deprecated.rake`: provides ruby rake tasks `ugent:export:projects` and `ugent:cleanup:projects`. That first task is the piece that generates the JSON files. The second one removes files and symbolic links older than a month

- `ugent/bin/daily_export_projects`: bash script that acts as a wrapper to rake task `ugent:export:projects`. Its sets the environment, adds locking, and makes sure that the script is online run on the production web server.

- `ugent/bin/daily_cleanup_projects`: bash script that acts as a wrapper to rake task `ugent:cleanup:projects`. Its sets the environment, adds locking, and makes sure that the script is online run on the production web server.

- `ugent/cron.d/roadmap.cron`: cronjob configuration. Bash scripts `daily_export_projects` and `daily_cleanup_projects` are added here. MAILTO configures where the stdout and stderr is sent to. This file is copied by the RPM to `/etc/cron.d/roadmap` on the server itself, and therefore is not managed by Puppet.

- directory (mount) `/opt/dmponline_internal`: directory where JSON export files and symbolic links are stored.

- `config/initializers/ugent.rb`. Here the necessary methods are added to the models:

  - `Theme.GDPR`: returns Theme with title `UGENT:DATA`. A question with this theme determines whether a plan can be gdpr related. Make sure that this theme stays in the table `themes`

  - `Template#gdpr_question`: returns the first question from the template that has the gdpr theme. A question with this theme is expected to be of boolean nature, and therefore should be a question with options "Yes" and "No".

  - `Template#gdpr_question?`: does the template have a question with gdpr? This question determines whether the plan is gdpr related or not.

  - `Plan#gdpr?`: does the plan have a template with a gdpr question AND did the user answer "Yes" to that question? If "No", then the plan itself is NOT gdpr related.

  - `Plan#old_project_groups`: mimics old model ProjectGroup from DMPonline_v4

  - `Plan#ld_uri`

  - `Plan#ld`: converts Plan record to a hash as needed by the export. Note that plans are called "projects" as was the case in the old DMPonline_v4

  - `QuestionOption#deep_copy`: overrides method of the same, in order to copy the themes linked to that option. The base software does not provide this linkage. MySQL table `question_option_themes` stores these links

  - `Org#internal_export_dir`: returns base directory where the JSON files for that organisation are stored (which is almost always `/opt/mponline_internal/<org_abbreviation>`)

  - `Org#internal_export_url`: returns base url for that organisations exports. e.g. https://dmponline.be/internal/exports/v01/organisations/UGent

  - `Org#internal_export_files`
