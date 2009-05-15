# vim:ts=2:sw=2:et:

module IBANTools
  class IBAN

    def self.valid?( code, rules = nil )
      new(code).validate(rules).empty?
    end

    def initialize( code )
      @code = IBAN.canonicalize_code(code)
    end

    def validate( rules = nil )
      errors = []
      return [:too_short] if @code.size < 5
      return [:bad_chars] unless @code =~ /^[A-Z0-9]+$/
      errors += validate_against_rules( rules || IBAN.default_rules )
      errors << :bad_check_digits unless valid_check_digits?
      errors
    end

    def validate_against_rules( rules )
      errors = []
      return [:unknown_country_code] if rules[country_code].nil?
      errors << :bad_length if rules[country_code]["length"] != @code.size
      errors << :bad_format unless bban =~ rules[country_code]["bban_pattern"]
      errors
    end

    # The code in canonical form,
    # suitable for storing in a database
    # or sending over the wire
    def code
      @code
    end

    def country_code
      @code[0..1]
    end

    def check_digits
      @code[2..3]
    end

    def bban
      @code[4..-1]
    end

    def valid_check_digits?
      numerify.to_i % 97 == 1
    end

    def numerify
      (@code[4..-1] + @code[0..3]).chars.map do |ch|
      	case ch
	      when '0'..'9'
          ch
        when 'A'..'Z'
          (ch[0] - ?A + 10).to_s
        else
          raise RuntimeError.new("Unexpected char '#{ch}' in IBAN code '#{prettify}'")
        end
      end.join
    end

    def to_s
      "#<#{self.class}: #{prettify}>"
    end

    # The IBAN code in a human-readable format
    def prettify
      @code.gsub(/(.{4})/, '\1 ').strip
    end

    def self.canonicalize_code( code )
      code.strip.gsub(/\s+/, '').upcase
    end

    # Load and cache the default rules from rules.yml
    def self.default_rules
      @default_rules = IBANRules.defaults
    end

  end
end
