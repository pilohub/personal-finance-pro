# frozen_string_literal: true

class Users::PasswordsController < Devise::PasswordsController
  # POST /resource/password
  def create
    self.resource = resource_class.send_reset_password_instructions(resource_params)
    yield resource if block_given?

    if successfully_sent?(resource)
      respond_with({}, location: after_sending_reset_password_instructions_path_for(resource_name))
    else
      # Even if SMTP times out or fails, gracefully redirect to prevent 500 server crash
      redirect_to new_password_path(resource_name), notice: "If your email address exists, you will receive a password reset instructions email shortly."
    end
  rescue StandardError => e
    # Catch any network/SMTP timeout errors completely and keep app running
    redirect_to new_password_path(resource_name), notice: "If your email address exists, you will receive a password reset instructions email shortly."
  end
end