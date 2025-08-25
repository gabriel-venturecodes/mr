class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_many :analyses, dependent: :destroy
  has_many :conversations, dependent: :destroy

  def current_conversation
    conversations.active.order(updated_at: :desc).first
  end

  def start_new_conversation(title)
    conversations.create!(
      title: title,
      status: 'active',
      context: {}
    )
  end
end
