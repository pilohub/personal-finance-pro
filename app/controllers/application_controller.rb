class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Prevent 500 error blank screen and show exact error for debugging
  rescue_from StandardError do |exception|
    if Rails.env.production?
      render plain: "EXACT ERROR: #{exception.message} \n\n BACKTRACE: \n#{exception.backtrace.join("\n")}", status: 500
    else
      raise exception
    end
  end
end