namespace :ugent do

  desc "fix empty contributor email"
  task fix_contributor_email: :environment do

    fixed = 0
    contributors = Contributor.where(email: nil).all

    contributors.each do |contributor|

      if contributor.name.include?("@")

        email = contributor.name.strip.downcase
        contributor.email = email

        user = User.find_by_email(email)

        if user.present?

          contributor.update_from_user(user)
          contributor.save!
          fixed += 1

        else

          $stderr.puts "found contributor email #{email} that is not in user database"

        end

      end

    end

    puts "fixed: #{fixed}, not fixed: #{contributors.size - fixed}"

  end

  desc "fix duplicate contributors with same email"
  task fix_duplicate_contributor: :environment do

    ActiveRecord::Base.transaction do

      ActiveRecord::Base.connection
                        .select_all("select email,plan_id,count(*) from contributors where email is not null group by email,plan_id having count(*) > 1")
                        .each do |row|

        plan = Plan.find(row["plan_id"])
        contributors = plan.contributors.select { |contributor| contributor.email == row["email"] }

        first_contributor = contributors.shift

        contributors.each do |contributor|
          first_contributor.roles |= contributor.roles
        end

        contributors.map(&:destroy)

        first_contributor.save!

      end

    end

  end

  desc "reimport exported_plans from older installation"
  task reimport_exported_plans: :environment do

    ExportedPlan.transaction do

      # expected fields: id,phase_title,user_id,format,created_at,updated_at
      # col_sep: ,
      # reads from stdin
      # please use an empty table as this imports new data
      csv = CSV.new( $stdin, {
          :headers => true,
          :col_sep => ","
        }
      )

      csv.each do |r|

        row   = r.to_hash.slice("id","phase_title","user_id","format","created_at","updated_at")

        # id: plan id (project.id in old database)
        plan  = Plan.find_by_id(row["id"])
        if plan.nil?
          $stderr.puts "no plan found with id "+row["id"]
          next
        end

        # select phase by searching on its title (no other way)
        phase = plan.phases.select { |ph| ph.title == row["phase_title"] }.first
        if phase.nil?
          $stderr.puts "no phase found with title \""+row["phase_title"]+"\" from plan id "+row["id"]
          next
        end

        # select user by searching on its id (has not changed)
        user = User.find_by_id(row["user_id"])
        if user.nil?
          $stderr.puts "no user found with id "+row["user_id"]+" from plan id "+row["id"]
          next
        end

        exported_plan = ExportedPlan.new(
          plan: plan,
          user: user,
          format: row["format"],
          created_at: row["created_at"].in_time_zone("Europe/Brussels"),
          updated_at: row["updated_at"].in_time_zone("Europe/Brussels")
        )

        if exported_plan.save
          puts "saved exported_plan for Plan[id=#{plan.id}"
        else
          $stderr.puts "unable to save exported_plan: #{exported_plan.errors.full_messages.join(',')}"
        end

      end

      csv.close

    end

  end

  desc "create shibboleth ds based on old table wayfless_entities"
  task move_wayfless_entities: :environment do

    scheme = IdentifierScheme.find_by_name!("shibboleth")

    ActiveRecord::Base.connection.select_all("select * from wayfless_entities").each do |we|

      # this works because organisation id has not changed
      org = Org.find( we["organisation_id"] )
      id  = Identifier.where( identifiable_type: "Org", identifiable_id: org.id, identifier_scheme_id: scheme.id, value: we["url"] )
                      .first

      if id.nil?

        Identifier.create!(
          identifiable_type: "Org", identifiable_id: org.id, identifier_scheme_id: scheme.id, value: we["url"]
        )

      else

        Rails.logger.info("wayfless_entity #{we["name"]} already moved")

      end

    end

  end

  desc "print out in csv existing question_options and their associated themes (for evaluation)"
  task question_option_themes: :environment do

    csv = CSV.new($stdout,{ write_headers: true, headers: %w(id text themes) })

    QuestionOption.includes(:themes)
                  .find_each do |question_option|

      themes = question_option.themes

      next if themes.size == 0

      record = []
      record << question_option.id
      record << question_option.text
      record << themes.map(&:title).join(" | ")
      csv << record

    end

    csv.close

  end

  desc "add/update org identifiers"
  task import_org_id: :environment do

    csv = CSV.new($stdin, { headers: true, col_sep: ";" })
    fields = %w(org_abbreviation id_scheme_name id_value)

    csv.each do |r|

      row = r.to_hash.slice(*fields)

      unless fields.all? { |f| row.key?(f) && row[f].present? }

        $stderr.puts "missing fields"
        break

      end

      scheme = IdentifierScheme.where(name: row["id_scheme_name"])
                               .first

      if scheme.nil?

        $stderr.puts "unable to find scheme for name #{row["id_scheme_name"]}"
        next

      end

      org = Org.where(abbreviation: row["org_abbreviation"])
               .first

      if org.nil?

        $stderr.puts "unable to find org for abbreviation #{row["org_abbreviation"]}"
        next

      end

      id = org.identifiers
              .select { |i| i.identifier_scheme_id == scheme.id }
              .first

      is_new = !(id.present?)

      if id.present?

        # update

      else

        id = org.identifiers.build
        id.identifier_scheme = scheme

      end

      id.value = row["id_value"]

      if id.save

        $stdout.puts "#{is_new ? 'added' : 'updated'} Identifier #{id.id} to Org #{org.abbreviation}"

      else

        $stderr.puts "failed to add/update Identifier to Org #{org.abbreviation}: #{id.errors.full_messages.join(', ')}"

      end

    end

    csv.close

  end

end
