require "csv"
require "file_utils"
require "tempfile"
require "json"

def export_org_projects(org)

  org_dir = org.internal_export_dir

  #base url
  uri_base = org.internal_export_url

  #timestamp - start
  file_t = File.join(org_dir, "mdate.txt")
  now = Time.now
  new_timestamp = now.utc.strftime("%FT%TZ")
  sub_dir = File.join(
    now.utc.strftime("%Y"),
    now.utc.strftime("%m")
  )
  cur_dir = File.join(org_dir, sub_dir)
  old_timestamp = nil

  unless File.directory?(cur_dir)

    FileUtils.mkdir_p(cur_dir)

  end

  if File.exists?(file_t)
    fh = File.open(file_t,"r")
    old_timestamp = fh.readline.chomp
    fh.close()
  end
  #timestamp - end

  # temporary file that will contain all org plans, each one on each line
  tmp_fh_plans = Tempfile.new(["org_plans",".json"], encoding: "UTF-8")

  $stdout.puts "created tmp file for plans of #{org.id}: #{tmp_fh_plans.path}"

  # export plans and write to tmpfile
  projects_ld(org) do |pr|

    tmp_fh_plans.puts pr.to_json

  end

  # synchronise tmpfile
  tmp_fh_plans.close

  # write all plans to /opt/dmponline_internal/<org.abbreviation>/<year>/<month>/projects_<timestamp>.json - start
  begin

    # current file name to write to
    cur_fn = File.join(
      sub_dir,
      "projects_" + new_timestamp + ".json"
    )

    # full path to current file
    cur_file = File.join(org_dir,cur_fn)

    # previous file name to refer to
    prev_fn = Dir
      .glob( File.join(org_dir,"*","*","projects_*.json") )
      .map { |f| f.sub(org_dir,"").sub(/^\//,"") }
      .sort
      .last
    links = {
      self: uri_base + "/" + cur_fn
    }
    if prev_fn.present?

      links[:prev] = uri_base + "/" + prev_fn

    end

    fh_json = File.open(cur_file,"w:UTF-8")

    fh_json.print "{"

    fh_json.print "\"meta\": { \"version\": \"0.1\",\"created_at\": \"#{new_timestamp}\" }"

    fh_json.print ",\"links\": " + links.to_json

    fh_json.print ",\"data\": ["

    i = 0
    prev_i = nil

    # reopen tmp_fh_plans for reading
    tmp_fh_plans.open

    # copy json lines to final projects_<timestamp>.json
    tmp_fh_plans.each do |line|

      fh_json.print "," unless prev_i.nil?
      fh_json.print line.chomp
      prev_i = i
      i = i + 1

    end

    # close tmp_fh_plans again
    tmp_fh_plans.close

    fh_json.print "]"
    fh_json.print "}"

    # close projects_<timestamp>.json
    fh_json.close()

    # create symlink from projects.json to projects_<timestamp>.json
    ref_file = File.join( org_dir, "projects.json" )
    File.delete( ref_file ) if File.exists?( ref_file )
    File.symlink( cur_file, ref_file )
    File.utime(now,now,cur_file)
    File.utime(now,now,ref_file)

  end
  # write projects_<timestamp>.json - end

  #export updated projects - start
  begin

    cur_fn = File.join(
      sub_dir,
      "updated_projects_" + new_timestamp + ".json"
    )
    cur_file = File.join(org_dir,cur_fn)
    prev_fn = Dir
      .glob( File.join(org_dir,"*","*","updated_projects_*.json") )
      .map { |f| f.sub(org_dir,"").sub(/^\//,"") }
      .sort
      .last
    links = {
      self: uri_base + "/" + cur_fn
    }
    if prev_fn.present?

      links[:prev] = uri_base + "/" + prev_fn

    end

    tmp_fh_plans.open

    fh_json = File.open(cur_file,"w:UTF-8")

    fh_json.print "{"

    fh_json.print "\"meta\": { \"version\": \"0.1\",\"created_at\": \"#{new_timestamp}\" }"

    fh_json.print ",\"links\": " + links.to_json

    fh_json.print ",\"data\": ["

    i = 0
    prev_i = nil

    tmp_fh_plans.each do |line|

      line.chomp!
      pr = JSON.parse(line).with_indifferent_access

      do_print = old_timestamp.nil? || project_ld_updated?(pr, old_timestamp)

      if do_print

        fh_json.print "," unless prev_i.nil?
        fh_json.print line
        prev_i = i
        i = i + 1

      end

    end

    fh_json.print "]"
    fh_json.print "}"

    fh_json.close()

    ref_file = File.join( org_dir, "updated_projects.json" )
    File.delete( ref_file ) if File.exists?( ref_file )
    File.symlink( cur_file, ref_file )
    File.utime(now,now,cur_file)
    File.utime(now,now,ref_file)

  end
  #export updated projects - end

  #export "deleted" projects - start
  begin

    cur_fn = File.join(
      sub_dir,
      "deleted_projects_" + new_timestamp + ".json"
    )
    cur_file = File.join(org_dir, cur_fn)
    prev_fn = Dir
      .glob( File.join(org_dir, "*", "*", "deleted_projects_*.json") )
      .map { |f| f.sub(org_dir, "").sub(/^\//,"") }
      .sort
      .last

    links = {
      self: uri_base + "/" + cur_fn
    }
    if prev_fn.present?

      links[:prev] = uri_base + "/" + prev_fn

    end

    fh_json = File.open(cur_file, "w:UTF-8")

    fh_json.print "{"

    fh_json.print "\"meta\": { \"version\": \"0.1\",\"created_at\": \"#{new_timestamp}\" }"

    fh_json.print ",\"links\": " + links.to_json

    fh_json.print ",\"data\": ["

    i = 0
    prev_i = nil

    Plan.where("(SELECT COUNT(*) FROM roles WHERE roles.plan_id = plans.id) = 0")
        .each do |plan|

          fh_json.print "," unless prev_i.nil?

          # TODO: timestamp of deletion unknown
          fh_json.print({ id: plan.id, type: "Project", datetime: plan.updated_at.utc.strftime("%FT%TZ") }.to_json)

          prev_i = i
          i = i + 1

        end

    fh_json.print "]}"

    fh_json.close()

    ref_file = File.join(org_dir, "deleted_projects.json")
    File.delete(ref_file ) if File.exists?(ref_file)
    File.symlink(cur_file, ref_file)
    File.utime(now,now,cur_file)
    File.utime(now,now,ref_file)

  end
  #export "deleted" projects - end

  #timestamp - start
  begin

    fh = File.open(file_t,"w")
    fh.puts(new_timestamp)
    fh.close()

  end
  #timestamp - end

  # removes tmp file
  tmp_fh_plans.unlink

end

def project_ld_updated?(project,date_s)

  if project[:updated_at] >= date_s

    return true

  end

  project[:plans].each do |plan|

    plan[:sections].each do |section|

      section[:questions].each do |question|

        answer = question[:answer]

        if answer.present? && answer[:updated_at] >= date_s

          return true

        end

        question[:comments].each do |comment|

          if comment[:updated_at] >= date_s

            return true

          end

        end

      end

    end

  end

  project[:collaborators].each do |collaborator|

    if collaborator[:updated_at] >= date_s

      return true

    end

  end

  false

end

def projects_ld(org)

  org_admin_plan_ids = org.org_admin_plan_ids # keep this method in line with Org#org_admin_plans (see ugent.rb)

  while org_admin_plan_ids.size > 0

    plan_ids = org_admin_plan_ids.shift(100)

    includes = [
      { answers: [
          :notes,
          :user,
          :question_options
        ]
      },
      { roles: { user: [:identifiers, :perms] } },
      { template: [
          :org,
          {
            phases: {
              sections: {
                questions: [
                  :annotations,
                  { question_options: :themes },
                  :themes
                ]
              }
            }
          }
        ]
      }
    ]

    Plan.includes(*includes)
        .where(id: plan_ids)
        .each do |plan|

       next if plan.is_test?

       if block_given?
        yield(plan.ld)
       end

     end

  end

end

def cleanup_org_projects(org, max = 30)

  if max < 2
    throw "max should be at least 2"
  end

  org_dir = org.internal_export_dir

  # cleanup <year>/<month>/projects_*.json
  begin

    files = Dir.glob(File.join(org_dir,"*","*","projects_*.json"))
               .sort

    if files.size > max

      files_to_delete = files.slice!(0, files.size - max)

      files_to_delete.each do |f|
        File.delete(f)
        $stderr.puts "deleted #{f}"
      end

      files.each do |f|
        $stderr.puts "left: #{f}"
      end

    end

  end

  # cleanup <year>/<month>/updated_projects_*.json
  begin

    files = Dir.glob(File.join(org_dir,"*","*","updated_projects_*.json"))
               .sort

    if files.size > max

      files_to_delete = files.slice!(0, files.size - max)

      files_to_delete.each do |f|
        File.delete(f)
        $stderr.puts "deleted #{f}"
      end

      files.each do |f|
        $stderr.puts "left: #{f}"
      end

    end

  end

  # cleanup <year>/<month>/deleted_projects_*.json
  begin

    files = Dir.glob(File.join(org_dir,"*","*","deleted_projects_*.json"))
               .sort

    if files.size > max

      files_to_delete = files.slice!(0, files.size - max)

      files_to_delete.each do |f|
        File.delete(f)
        $stderr.puts "deleted #{f}"
      end

      files.each do |f|
        $stderr.puts "left: #{f}"
      end

    end

  end

end

namespace :ugent do

  namespace :export do

      desc "export projects for organisations"
      task :projects, [:id] => :environment do |t,args|

        if args[:id].present?

          org = Org.find(args[:id])
          export_org_projects(org)

        else

          Org.where(managed: true).find_each do |org|

            export_org_projects(org)

          end

        end

      end

  end

  namespace :cleanup do

    desc "cleanup projects for organisations"
      task :projects, [:id] => :environment do |t,args|

        if args[:id].present?

          org = Org.find(args[:id])
          cleanup_org_projects(org)

        else

          Org.where(managed: true).find_each do |org|

            cleanup_org_projects(org)

          end

        end

      end

  end

end
