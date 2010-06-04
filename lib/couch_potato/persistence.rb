require 'digest/md5'
require File.dirname(__FILE__) + '/database'
require File.dirname(__FILE__) + '/persistence/active_model_compliance'
require File.dirname(__FILE__) + '/persistence/properties'
require File.dirname(__FILE__) + '/persistence/magic_timestamps'
require File.dirname(__FILE__) + '/persistence/callbacks'
require File.dirname(__FILE__) + '/persistence/json'
require File.dirname(__FILE__) + '/persistence/dirty_attributes'
require File.dirname(__FILE__) + '/persistence/ghost_attributes'
require File.dirname(__FILE__) + '/persistence/attachments'
require File.dirname(__FILE__) + '/persistence/type_caster'
require File.dirname(__FILE__) + '/view/custom_views'
require File.dirname(__FILE__) + '/view/view_query'


module CouchPotato
  module Persistence
    
    def self.included(base) #:nodoc:
      base.send :include, Properties, Callbacks, Validation, Json, CouchPotato::View::CustomViews
      base.send :include, DirtyAttributes, GhostAttributes, Attachments
      base.send :include, MagicTimestamps, ActiveModelCompliance
      base.class_eval do
        attr_accessor :_id, :_rev, :_deleted, :database
        alias_method :id, :_id
        alias_method :id=, :_id=
      end
    end

    # initialize a new instance of the model optionally passing it a hash of attributes.
    # the attributes have to be declared using the #property method
    # 
    # example: 
    #   class Book
    #     include CouchPotato::Persistence
    #     property :title
    #   end
    #   book = Book.new :title => 'Time to Relax'
    #   book.title # => 'Time to Relax'
    def initialize(attributes = {})
      attributes.each do |name, value|
        self.send("#{name}=", value)
      end if attributes
    end
    
    # assign multiple attributes at once.
    # the attributes have to be declared using the #property method
    #
    # example:
    #   class Book
    #     include CouchPotato::Persistence
    #     property :title
    #     property :year
    #   end
    #   book = Book.new
    #   book.attributes = {:title => 'Time to Relax', :year => 2009}
    #   book.title # => 'Time to Relax'
    #   book.year # => 2009
    def attributes=(hash)
      hash.each do |attribute, value|
        self.send "#{attribute}=", value
      end
    end
    
    # returns all of a model's attributes that have been defined using the #property method as a Hash
    #
    # example:
    #   class Book
    #     include CouchPotato::Persistence
    #     property :title
    #     property :year
    #   end
    #   book = Book.new :year => 2009
    #   book.attributes # => {:title => nil, :year => 2009}
    def attributes
      self.class.properties.inject({}) do |res, property|
        property.value(res, self)
        res
      end
    end

    def has_attribute?(attr_name)
      self.send("#{attr_name}?")
    end

    def [](attr_name)
      self.send("#{attr_name}")
    end
    
    def []=(attr_name, value)
      self.send "#{attr_name}=", value
    end
    
    # returns true if a  model hasn't been saved yet, false otherwise
    def new?
      _rev.nil?
    end
    alias_method :new_record?, :new?
    
    # returns the document id
    # this is used by rails to construct URLs
    # can be overridden to for example use slugs for URLs instead if ids
    def to_param
      _id
    end
    
    def ==(other) #:nodoc:
      other.class == self.class && self.to_json == other.to_json
    end
   
    def inspect
      attributes_as_string = attributes.map {|attribute, value| "#{attribute}: #{value.inspect}"}.join(", ")
      %Q{#<#{self.class} _id: "#{_id}", _rev: "#{_rev}", #{attributes_as_string}>}
    end
  end    
end
