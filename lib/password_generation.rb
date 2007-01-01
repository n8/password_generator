require 'digest/sha1'

class Password
  private
  # This flag is used in conjunction with Password.phonemic and states that a
  # password must include a digit.
  ONE_DIGIT  =	1
  
  # This flag is used in conjunction with Password.phonemic and states that a
  # password must include a capital letter.
  ONE_CASE    = 1 << 1
  
  # phoneme flags
  CONSONANT = 1
  VOWEL	    = 1 << 1
  DIPHTHONG = 1 << 2
  NOT_FIRST = 1 << 3  # indicates that a given phoneme may not occur first
  
  PHONEMES = {
    :a	=> VOWEL,
    :ae	=> VOWEL      | DIPHTHONG,
    :ah => VOWEL      | DIPHTHONG,
    :ai => VOWEL      | DIPHTHONG,
    :b	=> CONSONANT,
    :c	=> CONSONANT,
    :ch	=> CONSONANT  | DIPHTHONG,
    :d	=> CONSONANT,
    :e	=> VOWEL,
    :ee	=> VOWEL      | DIPHTHONG,
    :ei	=> VOWEL      | DIPHTHONG,
    :f	=> CONSONANT,
    :g	=> CONSONANT,
    :gh	=> CONSONANT  | DIPHTHONG | NOT_FIRST,
    :h	=> CONSONANT,
    :i	=> VOWEL,
    :ie	=> VOWEL      | DIPHTHONG,
    :j	=> CONSONANT,
    :k	=> CONSONANT,
    :l	=> CONSONANT,
    :m	=> CONSONANT,
    :n	=> CONSONANT,
    :ng	=> CONSONANT  | DIPHTHONG | NOT_FIRST,
    :o	=> VOWEL,
    :oh	=> VOWEL      | DIPHTHONG,
    :oo	=> VOWEL      | DIPHTHONG,
    :p	=> CONSONANT,
    :ph	=> CONSONANT  | DIPHTHONG,
    :qu	=> CONSONANT  | DIPHTHONG,
    :r	=> CONSONANT,
    :s	=> CONSONANT,
    :sh	=> CONSONANT  | DIPHTHONG,
    :t	=> CONSONANT,
    :th	=> CONSONANT  | DIPHTHONG,
    :u	=> VOWEL,
    :v	=> CONSONANT,
    :w	=> CONSONANT,
    :x	=> CONSONANT,
    :y	=> CONSONANT,
    :z	=> CONSONANT
  }
  
  class << self
    # Determine whether the next character should be a vowel or consonant.
    def get_vowel_or_consonant
      rand( 2 ) == 1 ? VOWEL : CONSONANT
    end
    
    # Generate a memorable password of _length_ characters, using phonemes that
    # a human-being can easily remember. _flags_ is one or more of
    # <em>Password::ONE_DIGIT</em> and <em>Password::ONE_CASE</em>, logically
    # OR'ed together. For example:
    #
    #  password = Password.generate( 8, Password::ONE_DIGIT | Password::ONE_CASE )
    #
    # This would generate an eight character password, containing a digit and an
    # upper-case letter, such as <b>Ug2shoth</b>.
    #
    # This method was inspired by the
    # pwgen[http://sourceforge.net/projects/pwgen/] tool, written by Theodore
    # Ts'o.
    #
    # Generated passwords may contain any of the characters in
    # <em>Password::PASSWD_CHARS</em>.
    def generate(length=8, flags=ONE_DIGIT | ONE_CASE)
      password = nil
      ph_flags = flags
      
      loop do
        password = ''
        
        # Separate the flags integer into an array of individual flags
        feature_flags = [ flags & ONE_DIGIT, flags & ONE_CASE ]
        
        prev = []
        first = true
        desired = Password.get_vowel_or_consonant
        
        # Get an Array of all of the phonemes
        phonemes = PHONEMES.keys.map { |ph| ph.to_s }
        nr_phonemes = phonemes.size
        
        while password.length < length do
        	# Get a random phoneme and its length
        	phoneme = phonemes[ rand( nr_phonemes ) ]
        	ph_len = phoneme.length
          
        	# Get its flags as an Array
        	ph_flags = PHONEMES[ phoneme.to_sym ]
        	ph_flags = [ ph_flags & CONSONANT, ph_flags & VOWEL,
        		     ph_flags & DIPHTHONG, ph_flags & NOT_FIRST ]
          
        	# Filter on the basic type of the next phoneme
        	next if ph_flags.include? desired
          
        	# Handle the NOT_FIRST flag
        	next if first and ph_flags.include? NOT_FIRST
          
        	# Don't allow a VOWEL followed a vowel/diphthong pair
        	next if prev.include? VOWEL and ph_flags.include? VOWEL and
        		ph_flags.include? DIPHTHONG
          
        	# Don't allow us to go longer than the desired length
        	next if ph_len > length - password.length
          
        	# We've found a phoneme that meets our criteria
        	password << phoneme
          
        	# Handle ONE_CASE
        	if feature_flags.include? ONE_CASE
        	  if (first or ph_flags.include? CONSONANT) and rand( 10 ) < 3
        	    password[-ph_len, 1] = password[-ph_len, 1].upcase
        	    feature_flags.delete ONE_CASE
        	  end
        	end
          
        	# Is password already long enough?
        	break if password.length >= length
          
        	# Handle ONE_DIGIT
        	if feature_flags.include? ONE_DIGIT
        	  if !first and rand( 10 ) < 3
        	    password << ( rand( 10 ) + ?0 ).chr
        	    feature_flags.delete ONE_DIGIT
              
        	    first = true
        	    prev = []
        	    desired = Password.get_vowel_or_consonant
        	    next
        	  end
        	end
          
        	if desired == CONSONANT
        	  desired = VOWEL
        	elsif prev.include? VOWEL or ph_flags.include? DIPHTHONG or rand(10) > 3
        	  desired = CONSONANT
        	else
        	  desired = VOWEL
        	end
          
        	prev = ph_flags
        	first = false
        end
        
        # Try again
        break unless feature_flags.include? ONE_CASE or feature_flags.include? ONE_DIGIT
        
      end
      
      password
    end
  end
end