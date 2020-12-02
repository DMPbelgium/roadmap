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

end
