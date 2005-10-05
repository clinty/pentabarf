class PentabarfController < ApplicationController
  before_filter :authorize, :check_permission
  after_filter :save_preferences, :except => [:meditation, :activity, :save_conference, :save_event, :save_person]
  after_filter :compress

  def initialize
    @content_title ='@content_title'
  end

  def index
    @content_title ='Overview'
  end

  def find_conference
    @content_title ='Find Conference'
    @preferences[:search_conference] = params[:id] if params[:id].to_s != ''
    if @preferences[:search_conference].match(/^ *(\d+ *)+$/)
      @conferences = Momomoto::View_find_conference.find( {:conference_id => @preferences[:search_conference].split(' ')} )
    else
      @conferences = Momomoto::View_find_conference.find( {:search => @preferences[:search_conference].split(' ')} )
    end
  end

  def search_conference
    @preferences[:search_conference] = request.raw_post if request.raw_post.to_s != ''
    if @preferences[:search_conference].match(/^ *(\d+ *)+$/)
      @conferences = Momomoto::View_find_conference.find( {:conference_id => @preferences[:search_conference].split(' ')} )
    else
      @conferences = Momomoto::View_find_conference.find( {:search => @preferences[:search_conference].split(' ')} )
    end
    render(:partial => 'search_conference')
  end

  def find_event
    @content_title ='Find Event'
    @preferences[:search_event] = params[:id] if params[:id].to_s != ''
    if @preferences[:search_event].match(/^ *(\d+ *)+$/)
      @events = Momomoto::View_find_event.find( {:event_id => @preferences[:search_event].split(' '), :conference_id => @current_conference_id, :translated_id => @current_language_id} )
    else
      @events = Momomoto::View_find_event.find( {:s_title => @preferences[:search_event].split(' '), :conference_id => @current_conference_id, :translated_id => @current_language_id} )
    end
  end

  def search_event
    @preferences[:search_event] = request.raw_post if request.raw_post.to_s != ''
    if @preferences[:search_event].match(/^ *(\d+ *)+$/)
      @events = Momomoto::View_find_event.find( {:event_id => @preferences[:search_event].split(' '), :conference_id => @current_conference_id, :translated_id => @current_language_id} )
    else
      @events = Momomoto::View_find_event.find( {:s_title => @preferences[:search_event].split(' '), :conference_id => @current_conference_id, :translated_id => @current_language_id} )
    end
    render(:partial => 'search_event')
  end

  def search_event_advanced
    @preferences[:search_event_advanced] = params[:search]
    conditions = transform_advanced_search_conditions( params[:search])
    conditions[:translated_id] = @current_language_id
    conditions[:conference_id] = @current_conference_id
    @events = Momomoto::View_find_event.find( conditions )
    render(:partial => 'search_event')
  end

  def search_person_advanced
    @preferences[:search_person_advanced] = params[:search]
    @persons = Momomoto::View_find_person.find( transform_advanced_search_conditions(@preferences[:search_person_advanced]) )
    render(:partial => 'search_person')
  end

  def transform_advanced_search_conditions( search )
    conditions = {}
    search.each do | key, value |
      if conditions[value['type'].to_sym]
        if
          conditions[value['type'].to_sym].kind_of?(Array)
          conditions[value['type'].to_sym].push(value['value'])
        else
          old_value = conditions[value['type'].to_sym]
          conditions[value['type'].to_sym] = []
          conditions[value['type'].to_sym].push( old_value )
          conditions[value['type'].to_sym].push( value['value'])
        end
      else
        conditions[value['type'].to_sym] = value['value']
      end
    end
    conditions 
  end

  def find_person
    @content_title ='Find Person'
    @preferences[:search_person] = params[:id] if params[:id].to_s != ''
    if @preferences[:search_person].match(/^ *(\d+ *)+$/)
      @persons = Momomoto::View_find_person.find( {:person_id => @preferences[:search_person].split(' ')} )
    else
      @persons = Momomoto::View_find_person.find( {:search => @preferences[:search_person].split(' ')} )
    end
  end

  def search_person
    @preferences[:search_person] = request.raw_post if request.raw_post.to_s != ''
    if @preferences[:search_person].match(/^ *(\d+ *)+$/)
      @persons = Momomoto::View_find_person.find( {:person_id => @preferences[:search_person].split(' ')} )
    else
      @persons = Momomoto::View_find_person.find( {:search => @preferences[:search_person].split(' ')} )
    end
    render(:partial => 'search_person')
  end

  def recent_changes
    @content_title ='Recent Changes'
    @changes = Momomoto::View_recent_changes.find( {}, params[:id] || 25 )
  end

  def conference
    if params[:id]
      if params[:id] == 'new'
        @content_title ='New Conference'
        @conference = Momomoto::Conference.new_record
        @conference.conference_id = 0
      else
        @conference = Momomoto::Conference.find( {:conference_id => params[:id] } )
        if @conference.length != 1
          redirect_to(:action => :meditation)
          return
        end
        @content_title = @conference.title
      end
    else
      render( :template => 'meditation', :layout => false )
    end
  end

  def event
    if params[:id]
      if params[:id] == 'new'
        @content_title ='New Event'
        @event = Momomoto::Event.new_record
        @event.event_id = 0
        @event.conference_id = @current_conference_id
        @rating = Momomoto::Event_rating.new_record
      else
        @event = Momomoto::Event.find( {:event_id => params[:id] } )
        if @event.length != 1
          redirect_to(:action => :meditation)
          return
        end
        @rating = Momomoto::Event_rating.find({:event_id => params[:id], :person_id => @user.person_id})
        @rating.create if @rating.length != 1
        @content_title = @event.title
      end
      @conference = Momomoto::Conference.find( {:conference_id => @event.conference_id } )
    else
      render( :template => 'meditation', :layout => false )
    end
  end

  def person
    if params[:id]
      if params[:id] == 'new'
        @content_title ='New Person'
        @person = Momomoto::View_person.new_record
        @person.person_id = 0
        @person.f_spam = 't'
        @conference_person = Momomoto::Conference_person.new_record
        @conference_person.conference_person_id = 0
        @conference_person.conference_id = @current_conference_id
        @conference_person.person_id = 0
        @person_travel = Momomoto::Person_travel.new_record
        @rating = Momomoto::Person_rating.new_record
      else
        @person = Momomoto::View_person.find( {:person_id => params[:id]} )
        if @person.length != 1
          redirect_to(:action => :meditation)
          return
        end
        @content_title = @person.name
        @conference_person = Momomoto::Conference_person.find({:conference_id => @current_conference_id, :person_id => @person.person_id})
        if @conference_person.length != 1
          @conference_person.create
          @conference_person.conference_person_id = 0
          @conference_person.conference_id = @current_conference_id
          @conference_person.person_id = @person.person_id
        end
        @person_travel = Momomoto::Person_travel.find( {:person_id => params[:id],:conference_id => @current_conference_id} )
        @person_travel.create if @person_travel.length == 0
        @rating = Momomoto::Person_rating.find({:person_id => params[:id], :evaluator_id => @user.person_id})
        @rating.create if @rating.length != 1
      end
    else
      render( :template => 'meditation', :layout => false )
    end
  end

  def conflicts
    @content_title = 'Conflicts'
  end

  def reports
    @content_title ='Reports'
  end

  def activity
    render(:partial => 'activity')
  end

  def meditation
    render( :template => 'meditation', :layout => false )
  end

  def save_person
    if params[:id] == 'new'
      person = Momomoto::Person.new_record
    else
      person = Momomoto::Person.find( {:person_id => params[:person_id]} )
    end
    if person.length == 1

      if params[:changed_when] != ''
        transaction = Momomoto::Person_transaction.find( {:person_id => person.person_id} )
        if transaction.length == 1 && transaction.changed_when != params[:changed_when]
          render_text('Outdated Data.')
          return
        end
      end
    
      modified = false
      person.begin

      begin
        if params[:person][:password].to_s != ''
          raise "Passwords do not match" if params[:person][:password] != params[:password]
        end
        
        params[:person].each do | key, value |
          next if key.to_sym == :preferences
          person[key]= value
        end
        person[:f_spam] = 'f' unless params[:person]['f_spam']
        person.password= params[:person][:password]
        prefs = person.preferences
        prefs[:current_language_id] = params[:person][:preferences][:current_language_id].to_i
        person.preferences = prefs
        modified = true if person.write

        conference_person = Momomoto::Conference_person.new
        modified = true if save_record( conference_person, 
                                      {:conference_person_id => params[:conference_person][:conference_person_id],
                                       :conference_id => params[:conference_person][:conference_id], 
                                       :person_id => person.person_id}, 
                                      params[:conference_person] )
        
        image = Momomoto::Person_image.new
        image.select({:person_id => person.person_id})
        if image.length != 1 && params[:person_image] && params[:person_image][:image] && params[:person_image][:image].size > 0
          image.create
          image.person_id = person.person_id
        end
        if image.length == 1
          if params[:person_image][:delete]
            modified = true if image.delete
          else
            image.f_public = ( params[:person_image] && params[:person_image][:f_public] ) ? 't' : 'f'
            if params[:person_image][:image].size > 0
              mime_type = Momomoto::Mime_type.find({:mime_type => params[:person_image][:image].content_type.chomp, :f_image => 't'})
              raise "mime-type not found #{params[:person_image][:image].content_type}" if mime_type.length != 1
              image.mime_type_id = mime_type.mime_type_id
              image.image = process_image( params[:person_image][:image].read )
              image.last_changed = 'now()'
            end
            modified = true if image.write
          end
        end

        person_role = Momomoto::Person_role.new
        for role in Momomoto::Role.find
          if params[:person_role] && params[:person_role][role.role_id.to_s]
            modified = true if save_record( person_role, {:person_id => person.person_id, :role_id => role.role_id}, [])
          else
            modified = true if delete_record( person_role, {:person_id => person.person_id, :role_id => role.role_id})
          end
        end

        modified = true if save_record( Momomoto::Person_travel.new, 
                                       {:person_id => person.person_id, :conference_id => @current_conference_id}, 
                                        params[:person_travel]) do | table |
          table.f_arrived = 'f' unless params[:person_travel]['f_arrived']
          table.f_arrival_pickup = 'f' unless params[:person_travel]['f_arrival_pickup']
          table.f_departure_pickup = 'f' unless params[:person_travel]['f_departure_pickup']
        end

        modified = true if save_record( Momomoto::Person_rating.new, 
                                       {:person_id => person.person_id, :evaluator_id => @user.person_id}, 
                                        params[:rating]) do | table |
          table.eval_time = 'now()'
        end
        
        if params[:event_person]
          event = Momomoto::Event_person.new
          params[:event_person].each do | key, value |
            if save_or_delete_record( event, {:person_id => person.person_id, :event_person_id => value[:event_person_id]}, value)
              transaction = Momomoto::Event_transaction.new_record
              transaction.event_id = event.event_id
              transaction.changed_by = @user.person_id
              transaction.write
              modified = true
            end
          end
        end
        
        if params[:person_im]
          person_im = Momomoto::Person_im.new
          params[:person_im].each do | key, value |
            modified = true if save_or_delete_record( person_im, {:person_id => person.person_id, :person_im_id => value[:person_im_id]}, value)
          end
        end

        if params[:person_phone]
          person_phone = Momomoto::Person_phone.new
          params[:person_phone].each do | key, value |
            modified = true if save_or_delete_record( person_phone, {:person_id => person.person_id, :person_phone_id => value[:person_phone_id]}, value) 
          end
        end

        if params[:link]
          person_link = Momomoto::Conference_person_link.new
          params[:link].each do | key, value |
            modified = true if save_or_delete_record( person_link, {:conference_person_id => conference_person.conference_person_id, :conference_person_link_id => value[:link_id]}, value)
          end
        end

        if params[:internal_link]
          person_link_internal = Momomoto::Conference_person_link_internal.new
          params[:internal_link].each do | key, value |
            modified = true if save_or_delete_record( person_link_internal, {:conference_person_id => conference_person.conference_person_id, :conference_person_link_internal_id => value[:internal_link_id]}, value)
          end
        end

        if modified == true
          transaction = Momomoto::Person_transaction.new_record
          transaction.person_id = person.person_id
          transaction.changed_by = @user.person_id
          transaction.f_create = 't' if params[:id] == 'new'
          transaction.write
          person.commit
        else
          person.rollback
        end
      rescue => e
        person.rollback
        raise e
      end
      redirect_to({:action => :person, :id => person.person_id})
    end
  end

  def save_conference
    if params[:id] == 'new'
      conference = Momomoto::Conference.new_record
    else
      conference = Momomoto::Conference.find( {:conference_id => params[:conference_id]})
    end
    if conference.length == 1
      if params[:changed_when] != ''
        transaction = Momomoto::Conference_transaction.find( {:conference_id => conference.conference_id} )
        if transaction.length == 1 && transaction.changed_when != params[:changed_when]
          render_text('Outdated Data.')
          return
        end
      end

      modified = false
      conference.begin

      begin
        params[:conference].each do | key, value |
          conference[key]= value
        end
        modified = true if conference.write

        image = Momomoto::Conference_image.new
        image.select({:conference_id => conference.conference_id})
        if image.length != 1 && params[:conference_image] && params[:conference_image][:image] && params[:conference_image][:image].size > 0
          image.create
          image.conference_id = conference.conference_id
        end
        if image.length == 1
          if params[:conference_image][:delete]
            modified = true if image.delete
          else
            if params[:conference_image][:image].size > 0
              mime_type = Momomoto::Mime_type.find({:mime_type => params[:conference_image][:image].content_type.chomp, :f_image => 't'})
              raise "mime-type not found #{params[:conference_image][:image].content_type}" if mime_type.length != 1
              image.mime_type_id = mime_type.mime_type_id
              image.image = process_image( params[:conference_image][:image].read )
              image.last_changed = 'now()'
            end
            modified = true if image.write
          end
        end

        if params[:team]
          team = Momomoto::Team.new
          params[:team].each do | key, value |
            modified = true if save_or_delete_record( team, {:conference_id => conference.conference_id, :team_id => value[:team_id]}, value)
          end
        end

        if params[:conference_track]
          track = Momomoto::Conference_track.new
          params[:conference_track].each do | key, value |
            modified = true if save_or_delete_record( track, {:conference_id => conference.conference_id, :conference_track_id => value[:conference_track_id]}, value)
          end
        end

        if params[:room]
          room = Momomoto::Room.new
          params[:room].each do | key, value |
            modified = true if save_or_delete_record( room, {:conference_id => conference.conference_id, :room_id => value[:room_id]}, value)
          end
        end

        if modified == true
          transaction = Momomoto::Conference_transaction.new_record
          transaction.conference_id = conference.conference_id
          transaction.changed_by = @user.person_id
          transaction.f_create = 't' if params[:id] == 'new'
          transaction.write
          conference.commit
        else
          conference.rollback
        end
      rescue => e
        conference.rollback
        raise e
      end
      redirect_to({:action => :conference, :id => conference.conference_id})
    end
  end

  def save_event
    if params[:id] == 'new'
      event = Momomoto::Event.new_record
    else
      event = Momomoto::Event.find( {:event_id => params[:event_id]} )
    end
    if event.length == 1

      if params[:changed_when] != ''
        transaction = Momomoto::Event_transaction.find( {:event_id => event.event_id} )
        if transaction.length == 1 && transaction.changed_when != params[:changed_when]
          render_text('Outdated Data.')
          return
        end
      end
    
      modified = false
      event.begin
      
      begin
        params[:event].each do | key, value |
          event[key]= value
        end
        event.f_public = 'f' unless params[:event]['f_public']
        event.f_paper = 'f' unless params[:event]['f_paper']
        event.f_slides = 'f' unless params[:event]['f_slides']
        modified = true if event.write
        
        modified = true if save_record(Momomoto::Event_rating.new, {:person_id => @user.person_id, :event_id => event.event_id}, params[:rating]) do | t |
          t.eval_time = 'now()'
        end

        if params[:related_event]
          params[:related_event].each do | key, value |
            modified = true if save_or_delete_record(Momomoto::Event_related.new, {:event_id1 => event.event_id, :event_id2 => value[:related_event_id]}, value)
          end
        end

        image = Momomoto::Event_image.new
        image.select({:event_id => event.event_id})
        if image.length != 1 && params[:event_image] && params[:event_image][:image] && params[:event_image][:image].size > 0
          image.create
          image.event_id = event.event_id
        end
        if image.length == 1
          if params[:person_image][:delete]
            modified = true if image.delete
          else
            if params[:event_image][:image].size > 0
              mime_type = Momomoto::Mime_type.find({:mime_type => params[:event_image][:image].content_type.chomp, :f_image => 't'})
              raise "mime-type not found #{params[:event_image][:image].content_type}" if mime_type.length != 1
              image.mime_type_id = mime_type.mime_type_id
              image.image = process_image( params[:event_image][:image].read )
              image.last_changed = 'now()'
            end
            modified = true if image.write
          end
        end

        if params[:attachment_upload]
          file = Momomoto::Event_attachment.new
          params[:attachment_upload].each do | key, value | 
            next unless value[:data].size > 0
            file.create
            file.event_id = event.event_id
            file.attachment_type_id = value[:attachment_type_id]
            mime_type = Momomoto::Mime_type.find({:mime_type => params[:event_image][:image].content_type.chomp})
            raise "mime-type not found #{params[:event_image][:image].content_type}" if mime_type.length != 1
            file.mime_type_id = mime_type.mime_type_id
            file.filename = File.basename(value[:data].original_filename).gsub(/[^\w0-9.-_]/, '')
            file.title = value[:title]
            file.data = value[:data].read
            file.f_public = value[:f_public] ? 't' : 'f'
            file.last_changed = 'now'
            modified = true if file.write
          end
        end

        if params[:event_attachment]
          attachment = Momomoto::Event_attachment.new
          params[:event_attachment].each do | key, value |
            modified = true if save_or_delete_record( attachment, {:event_attachment_id => key, :event_id => event.event_id}, value )
          end
        end

        if params[:event_person]
          person = Momomoto::Event_person.new
          params[:event_person].each do | key, value |
            if save_or_delete_record( person, {:event_id => event.event_id, :event_person_id => value[:event_person_id]}, value )
              transaction = Momomoto::Person_transaction.new_record
              transaction.person_id = person.person_id
              transaction.changed_by = @user.person_id
              transaction.write
              modified = true
            end
          end
        end
        
        if params[:link]
          event_link = Momomoto::Event_link.new
          params[:link].each do | key, value |
            modified = true if save_or_delete_record( event_link, {:event_id => event.event_id, :event_link_id => value[:link_id]}, value)
          end
        end

        if params[:internal_link]
          event_link_internal = Momomoto::Event_link_internal.new
          params[:internal_link].each do | key, value |
            modified = true if save_or_delete_record( event_link_internal, {:event_id => event.event_id, :event_link_internal_id => value[:internal_link_id]}, value)
          end
        end

        if modified == true
          transaction = Momomoto::Event_transaction.new_record
          transaction.event_id = event.event_id
          transaction.changed_by = @user.person_id
          transaction.f_create = 't' if params[:id] == 'new'
          transaction.write
          event.commit
        else
          event.rollback
        end
      rescue => e
        event.rollback
        raise e
      end
      redirect_to({:action => :event, :id => event.event_id})
    end
  end

  protected

  def check_permission
    #redirect_to :action => :meditation if params[:action] != 'meditation'
    if @user.permission?('login_allowed') || params[:action] == 'meditation'
      @preferences = @user.preferences
      if params[:current_conference_id]
        conf = Momomoto::Conference.find({:conference_id => params[:current_conference_id]})
        if conf.length == 1
          @preferences[:current_conference_id] = params[:current_conference_id].to_i
          @user.preferences = @preferences
          @user.write
          redirect_to
          return false
        end
      end
      @current_conference_id = @preferences[:current_conference_id]
      @current_language_id = @preferences[:current_language_id]
    else
      redirect_to( :action => :meditation )
      false
    end
  end

  def save_or_delete_record( table, pkeys, values )
    if values[:delete]
      return delete_record( table, pkeys )
    else
      return save_record( table, pkeys, values )
    end
  end

  def save_record( table, pkeys, values )
    if table.select( pkeys ) != 1
      table.create
      pkeys.each do | field_name, value |
        table[field_name] = value
      end
    end
    values.each do | field_name, value |
      next if pkeys.key?(field_name.to_sym)
      next unless table.fields.member?( field_name.to_sym )
      table[field_name] = value
    end
    yield( table ) if block_given? 
    return table.write
  end

  def delete_record( table, pkeys )
    if table.select( pkeys ) == 1
      return table.delete
    elsif table.length > 1
      raise "deleting multiple records is forbidden"
    end
    false
  end

  def process_image( image )
    image
  end

end
