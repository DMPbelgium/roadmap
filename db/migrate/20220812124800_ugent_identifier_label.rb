class UgentIdentifierLabel < ActiveRecord::Migration[5.2]
  def up
    if table_exists?(:identifiers)
      unless column_exists?(:identifiers, :label)
        add_column :identifiers, :label, :string

        # set default label from org.name
        scheme = IdentifierScheme.where(name: "shibboleth").first

        Org.where(managed: true)
           .each do |org|
              identifiers = org.identifiers.select { |id| id.identifier_scheme_id == scheme.id }
              next if identifiers.empty?
              identifiers.each do |id|
                id.label = org.name
              end
              identifiers.map(&:save)
           end

      end
    end
  end
  def down
    if table_exists?(:identifiers)
      if column_exists?(:identifiers, :label)
        remove_column :identifiers, :label
      end
    end
  end
end
