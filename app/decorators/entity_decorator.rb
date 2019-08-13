class EntityDecorator < Draper::Decorator
  delegate_all

  def address
    object.mails.any? ? object.mails.order(:by_default).first.mail_coordinate : object.full_name
  end

  def email
    object.emails.any? ? object.emails.order(:by_default).first.coordinate : ''
  end

  def phone
    object.phones.any? ? object.phones.order(:by_default).first.coordinate : ''
  end

  def website
    object.websites.any? ? object.websites.order(:by_default).first.coordinate : ''
  end
end
