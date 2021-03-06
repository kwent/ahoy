module Ahoy
  class BaseController < ApiController
    filters = _process_action_callbacks.map(&:filter) - Ahoy.preserve_callbacks
    if Rails::VERSION::MAJOR >= 5
      skip_before_action(*filters, raise: false)
      skip_after_action(*filters, raise: false)
      skip_around_action(*filters, raise: false)
    else
      skip_action_callback(*filters)
    end
    before_action :verify_request_size
    before_action :renew_cookies

    if respond_to?(:protect_from_forgery)
      protect_from_forgery with: :null_session, if: -> { Ahoy.protect_from_forgery }
    end

    protected

    def ahoy
      @ahoy ||= Ahoy::Tracker.new(controller: self, api: true)
    end

    # set proper ttl if cookie generated from JavaScript
    # approach is not perfect, as user must reload the page
    # for new cookie settings to take effect
    def renew_cookies
      set_ahoy_cookies if params[:js] && !Ahoy.api_only
    end

    def verify_request_size
      if request.content_length > Ahoy.max_content_length
        logger.info "[ahoy] Payload too large"
        render text: "Payload too large\n", status: 413
      end
    end
  end
end
