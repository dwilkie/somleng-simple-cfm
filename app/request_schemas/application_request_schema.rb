class ApplicationRequestSchema < Dry::Validation::Schema
  configure do |config|
    config.messages = :i18n
    config.type_specs = true
  end

  module Types
    include Dry::Types.module

    PhoneNumber = String.constructor do |phone_number|
      result = PhonyRails.normalize_number(phone_number)
      result.insert(0, "0") if phone_number.to_s.starts_with?("0")
      result
    end
  end
end
