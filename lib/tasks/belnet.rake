namespace :belnet do

  namespace :users do

      desc "Deletes users who never had any activity, after some time"
      task :clean => :environment do 

        User.where(last_sign_in_at:nil).find_each do |user|

          # Only consider users that have been created more than 1 year ago
          if user.created_at.year < ( Date.today.year - 1 )

            # Unlink user from any existing plan
            role = Role.where(user_id:user.id).destroy_all
              
            # Deletes user
            user.destroy

          end

        end

      end

  end

end
