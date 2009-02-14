# encoding: utf-8

$:.unshift File.join(File.dirname(__FILE__), '..', 'lib')

require 'ascii85'

describe Ascii85 do

  TEST_CASES = {

    ""          => "",
    " "         => "<~+9~>",

    "\0" * 1    => "<~!!~>",
    "\0" * 2    => "<~!!!~>",
    "\0" * 3    => "<~!!!!~>",
    "\0" * 4    => "<~z~>",
    "\0" * 5    => "<~z!!~>",
    "A\0\0\0\0" => "<~5l^lb!!~>", # No z-abbreviation!

    "A"         => "<~5l~>",
    "AB"        => "<~5sb~>",
    "ABC"       => "<~5sdp~>",
    "ABCD"      => "<~5sdq,~>",
    "ABCDE"     => "<~5sdq,70~>",
    "ABCDEF"    => "<~5sdq,77I~>",
    "ABCDEFG"   => "<~5sdq,77Kc~>",
    "ABCDEFGH"  => "<~5sdq,77Kd<~>",
    "ABCDEFGHI" => "<~5sdq,77Kd<8H~>",
    "Ascii85"   => "<~6$$OMBfIs~>",

    'Antidisestablishmentarianism' => '<~6#LdYA8-*rF*(i"Ch[s(D.RU,@<-\'jDJ=0/~>',

    # Dōmo arigatō, Mr. Roboto (according to Wikipedia)
    'どうもありがとうミスターロボット' =>
        "<~j+42iJVN3:K&_E6j+<0KJW/W?W8iG`j+EuaK\"9on^Z0sZj+FJoK:LtSKB%T?~>",

    [Math::PI].pack('G') => "<~5RAV2<(&;T~>",
    [Math::E].pack('G')  => "<~5R\"n0M\\K6,~>"
  }

  it "#decode should be the inverse of #encode" do

    # Generate a random string
    test_str = ""
    (1 + rand(255)).times do
      test_str += rand(256).chr
    end

    encoded = Ascii85::encode(test_str)
    decoded = Ascii85::decode(encoded)

    decoded.should == test_str
  end

  describe "#encode" do

    it "should encode all specified test-cases correctly" do
      TEST_CASES.each_pair do |input, encoded|
        Ascii85::encode(input).should == encoded
      end
    end

    it "should produce output lines no longer than specified" do
      test_str = '0123456789' * 30

      #
      # No wrap
      #
      Ascii85::encode(test_str, false).count("\n").should == 0

      #
      # x characters per line, except for the last one
      #
      x = 2 + rand(255) # < test_str.length
      encoded = Ascii85::encode(test_str, x)

      # Determine the length of all lines
      count_arr = []
      encoded.each_line do |line|
        count_arr << line.chomp.length
      end

      # The last line is allowed to be shorter than x, so remove it
      count_arr.pop if count_arr.last <= x

      # If the end-marker is on a line of its own, the next-to-last line is
      # allowed to be shorter than specified by exactly one character
      count_arr.pop if (encoded[-3].chr =~ /[\r\n]/) and (count_arr.last == x-1)

      # Remove all line-lengths that are of length x from count_arr
      count_arr.delete_if { |len| len == x }

      # Now count_arr should be empty
      count_arr.should be_empty
    end

    it "should not split the end-marker to achieve correct line length" do
      Ascii85::encode("\0" * 4, 4).should == "<~z\n~>"
    end

  end

  describe "#decode" do

    it "should decode all specified test-cases correctly" do
      TEST_CASES.each_pair do |decoded, input|
        Ascii85::decode(input).should == decoded
      end
    end

    it "should ignore everything before/after the delimiter-pairs" do
      Ascii85::decode("Doesn't contain delimiters").should == ''
      Ascii85::decode("FooBar<~z~>BazQux").should == ("\0" * 4)
    end

    it "should ignore whitespace" do
      decoded = Ascii85::decode("<~6   #LdYA\r\08\n  \n\n- *rF*(i\"Ch[s \t(D.RU,@ <-\'jDJ=0\f/~>")
      decoded.should == 'Antidisestablishmentarianism'
    end

    describe "Error conditions" do

      it "should raise DecodingError if it encounters a word >= 2**32" do
        lambda {
          Ascii85::decode('<~s8W-#~>')
        }.should raise_error Ascii85::DecodingError
      end

      it "should raise DecodingError if it encounters an invalid character" do
        lambda {
          Ascii85::decode('<~!!y!!~>')
        }.should raise_error Ascii85::DecodingError
      end

      it "should raise DecodingError if the last tuple consists of a single character" do
        lambda {
          Ascii85::decode('<~!~>')
        }.should raise_error Ascii85::DecodingError
      end

      it "should raise DecodingError if a z is found inside a 5-tuple" do
        lambda {
          Ascii85::decode('<~!!z!!~>')
        }.should raise_error Ascii85::DecodingError
      end

    end

  end

end
