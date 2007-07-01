require 'bluecloth'

module ScheduleHelper

  def markup( text )
    BlueCloth.new( text.to_s, :filter_html ).to_html
  end

  def sanitize_track( track )
    track = track.to_s.downcase.gsub(/[^a-z0-9]/, '')
    return track == '' ? '' : h("track-#{track}")
  end

  # returns an array with the ids of rooms that are really used in a schedule table
  def schedule_rooms( table, rooms )
    used_rooms = []
    rooms.each do | room |
      table.each do | row |
        if row[room.room_id]
          used_rooms.push( room.room_id)
          break
        end
      end
    end
    used_rooms
  end
            
  def person_image( person_id = 0, size = 32, extension = nil )
    url_for({:controller=>'image',:action=>:person,:id=>person_id}) + "-#{size}x#{size}" + ( extension ? ".#{extension}" : '')
  end

  def event_image( event_id = 0, size = 32, extension = nil )
    url_for({:controller=>'image',:action=>:event,:id=>event_id}) + "-#{size}x#{size}" + ( extension ? ".#{extension}" : '')
  end

  def conference_image( conference_id = 0, size = 32, extension = nil )
    url_for({:controller=>'image',:action=>:conference,:id=>event_id}) + "-#{size}x#{size}" + ( extension ? ".#{extension}" : '')
  end

end