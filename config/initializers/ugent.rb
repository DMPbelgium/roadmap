Identifier.module_eval do

  def value_uniqueness_with_scheme
    #override - start
    #Org may have multiple login routes of the same type
    if self.identifier_scheme.name == "shibboleth" && self.identifiable_type == "Org"
      return true
    end
    #same orcid may be attached to several users
    if self.identifier_scheme.name == "orcid" && self.identifiable_type == "User"
      return true
    end
    #override - end
    #old code
    if Identifier.where(identifier_scheme: self.identifier_scheme,
                        identifiable: self.identifiable).any?
      errors.add(:identifier_scheme, _("already assigned a value"))
    end
  end

end

DMPRoadmap::Application.class_eval do
  if File.exists?(Rails.root.join('config', 'custom.yml'))
    config.custom = config_for(:custom)
  end
end
