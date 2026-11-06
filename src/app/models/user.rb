class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  ## Admin/curator rights are granted by email (ENV ADMIN_EMAILS / CURATOR_EMAILS) and emails
  ## are not verified, so nobody may sign up with, or switch to, one of these addresses.
  ## Role accounts must exist before their email is added to the ENV lists.
  validate :email_not_reserved_for_role, on: :create
  validate :email_not_reserved_for_role, on: :update, if: :will_save_change_to_email?

  def self.role_emails
    (ENV['ADMIN_EMAILS'].to_s + ',' + ENV['CURATOR_EMAILS'].to_s).split(/\s*[,;]\s*/).map{|e| e.strip.downcase}.reject(&:empty?)
  end

  private

  def email_not_reserved_for_role
    if email.present? and User.role_emails.include?(email.strip.downcase)
      errors.add(:email, "is not available")
    end
  end
end
