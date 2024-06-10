# frozen_string_literal: true

module DMPRoadmap

  class Application < Rails::Application

    WickedPdf.configure do |c|
      c.exe_path = "#{ENV['GEM_HOME']}/bin/wkhtmltopdf"
    end

  end

end
