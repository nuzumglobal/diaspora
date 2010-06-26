module ApplicationHelper
  def object_path(object)
    eval("#{object.class.to_s.underscore}_path(object)")
  end

  def object_fields(object)
    object.attributes.keys 
  end

  def parse_sender_id_from_xml(xml)
    doc = Nokogiri::XML(xml) { |cfg| cfg.noblanks }
    doc.xpath("/XML/head/sender/email").text.to_s
  end
  
  def parse_sender_object_from_xml(xml)
    sender_id = parse_sender_id_from_xml(xml)
    Friend.where(:email => sender_id).first
  end

  def parse_body_contents_from_xml(xml)
    doc = Nokogiri::XML(xml) { |cfg| cfg.noblanks }
    doc.xpath("/XML/posts/post")
  end

  def parse_objects_from_xml(xml)
    objects = []
    sender = parse_sender_object_from_xml(xml)
    body = parse_body_contents_from_xml(xml)
    body.children.each do |post|
      begin
        object = post.name.camelize.constantize.from_xml post.to_s
        object.person = sender if object.is_a? Post  
        objects << object 
      rescue
        puts "Not a real type: #{object.to_s}"
      end
    end
    objects
  end

  def store_objects_from_xml(xml)
    objects = parse_objects_from_xml(xml)

    objects.each do |p|
      p.save if p.respond_to?(:person) && !(p.person.nil?) #WTF
      #p.save if p.respond_to?(:person) && !(p.person == nil) #WTF
    end
  end

  def mine?(post)
    post.person == User.first
  end
  
  def type_partial(post)
    class_name = post.class.name.to_s.underscore
    "#{class_name.pluralize}/#{class_name}"
  end
  
  def how_long_ago(obj)
    time_ago_in_words(obj.created_at) + " ago."
  end

  def person_url(person)
    case person.class.to_s
    when "Friend"
      friend_path(person)
    when "User"
      user_path(person)
    else
      "#"
    end
  end

  def link_to_person(person)
    link_to person.real_name, person_url(person)
  end

end
