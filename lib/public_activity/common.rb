module PublicActivity
  # Common methods shared across the gem.
  module Common
    extend ActiveSupport::Concern
    # Instance methods used by other methods in PublicActivity module.
    module InstanceMethods
      # Directly creates activity record in the database, based on supplied arguments.
      # Only first argument - key - is required.
      #
      # == Usage:
      #
      #   current_user.create_activity("activity.user.avatar_changed") if @user.avatar_file_name_changed?
      #
      # == Parameters:
      # [key]
      #   Custom key that will be used as a i18n translation key - *required*
      # [owner]
      #   Polymorphic relation specifying the owner of this activity (for example, a User who performed this task) - *optional*
      # [params]
      #  Hash with parameters passed directly into i18n.translate method - *optional*
      #
      def create_activity(key, owner = nil, params = {})   
        
        if owner.nil? && ((defined? User) != nil) && User.respond_to?(:current_user)  
          owner = User.current_user
        end
            
        activity = self.activities.create(:key => key, :owner => owner, :parameters => params)
        if !Pusher.app_id.nil? && !Pusher.key.nil? && !Pusher.secret.nil?
         picture_url = ""
         
         if activity.trackable_type.eql?("Program")
           picture_url = activity.trackable.organization.logo.profile.url
         elsif activity.trackable_type.eql?("Task")
           picture_url = activity.trackable.program.organization.logo.profile.url
         end
            
          Pusher['acitivty-channel'].trigger('acitivty-create', {:picture_url => picture_url, :key => key, :owner => owner, :parameters => params, 
            :text => activity.text, :object => self})
        end
      end

      private
        # Prepares settings used during creation of Activity record.
        # params passed directly to tracked model have priority over
        # settings specified in tracked() method
        def prepare_settings
          # user responsible for the activity
          if self.activity_owner
            owner = self.activity_owner
          else
            owner = self.class.activity_owner_global
          end
          
          case owner
            when Symbol
              owner = self.try(owner)
            when Proc
              owner = owner.call(self)    
          end
          #customizable parameters
          parameters = self.class.activity_params_global
          parameters.merge! self.activity_params if self.activity_params      
          return {:key => self.activity_key,:owner => owner, :parameters => parameters}
        end      
    end
  end
end
