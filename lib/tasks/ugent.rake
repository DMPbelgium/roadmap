namespace :ugent do

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

end
