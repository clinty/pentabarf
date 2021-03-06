class XmlController < ApplicationController

  before_filter :init

  def schedule
    if params[:preview]
      # if preview is specified we work on live data
      @conference = Release_preview::Conference.select_single({:conference_id=>params[:conference_id]})
    elsif params[:release]
      # if a specific release is selected we show that one
      @conference = Release::Conference.select_single({:conference_id=>params[:conference_id],:conference_release_id=>params[:release]})
    else
      # otherwise we show the latest release with fallback to live data if nothing has been released yet
      begin
        @conference = Release::Conference.select_single({:conference_id=>params[:conference_id]},{:limit=>1,:order=>Momomoto.desc(:conference_release_id)})
      rescue Momomoto::Nothing_found
        @conference = Release_preview::Conference.select_single({:conference_id=>params[:conference_id]})
      end
    end
  end

  protected

  def init
    @current_language = 'en'
    response.content_type = Mime::XML
  end

  def check_permission
    return false if not POPE.conference_permission?('pentabarf::login',params[:conference_id])
    case params[:action]
      when 'schedule' then POPE.conference_permission?('conference::show',params[:conference_id])
      else
        false
    end
  end


end
