require 'integer_hash'
require 'active_record'

module IntegerHash
  module Rails
    def encode_id
      require 'integer_hash'
      extend ClassMethods
      include InstanceMethods

      cattr_accessor :integer_hash_configuration

    end

    module ClassMethods
      def find(*args)
        options = args.extract_options!
        scope = args
        if has_encoded_id? && !options[:no_hashed_id]
          if scope.is_a?(Array)
            scope.map! {|a| IntegerHash.decode(a.to_i).to_s}
          else
            scope = IntegerHash.decode(scope.to_i).to_s
          end
        end
        super(*scope)
      end

      def has_encoded_id?
        true
      end
    end

    module InstanceMethods
      def to_param
        IntegerHash.encode(self.id).to_s
      end

      # Override ActiveRecord::Persistence#reload
      # passing in an options flag with { no_hashed_id: true }
      def reload(options = nil)
        clear_aggregation_cache
        clear_association_cache
        self.class.connection.clear_query_cache

        fresh_object =
          if options && options[:lock]
            self.class.unscoped { self.class.lock(options[:lock]).find(id) }
          else
            self.class.unscoped { self.class.find(id, no_hashed_id: true) }
          end


        @attributes = fresh_object.instance_variable_get('@attributes')
        @new_record = false
        self
      end
    end
  end
end

ActiveRecord::Base.extend IntegerHash::Rails
