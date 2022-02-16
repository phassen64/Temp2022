=begin
    Theme: strings
    Topics:
        quoting strings, repeater s*, compare
        concatenate,substrings[..]
    Functions:
        puts, printf, sprintf
    Methods:
        empty?, length, size
        downcase[!],upcase[!],capitalize[!],swapcase[!],reverse[!],
        count(c),delete(c),squeeze[(c)]
        chop[!],chomp[!],strip[!],slice[!]
        sub(),gsub
        index, rindex, include?, scan
=end
require_relative "TUT.inc"
$m.f_hdr("String",__FILE__)

#
#   define a string
#
$m.f_thm("define strings")
$m.f_inf("InfoTest readable?") # DOS>set v_VERBOSE=true

sLetter     = "ABCDEFGHIJ"
sText       = "Oliver Kahn steht im Tor!"
$m.f_puts("use sLetter   : '#{sLetter}'")
$m.f_puts("use sText     : '#{sText }'")
s = 'Hello, I am a defined in 2:'\
'lines'
$m.f_puts("2LineDefined String : '#{s}'")
#   __END__ testme

#   single quoted
$m.f_thm("simple single vs double quoted",true,__LINE__)
s = 'single-quoted string' ; $m.f_puts s
s = "double-quoted string" ; $m.f_puts s

#   double quoted
$m.f_thm("use Interpolation",true)
s = "double-quoted string with content id and ruby indent: <#{__id__}>" ; puts s
$m.f_thm("use add",true,__LINE__)
s = "concatenations:<" + __id__.to_s + ">\n"; $m.f_put s

#   string delimiters
$m.f_thm("define with alternate notations (different delimiters)")
$m.f_thm("use syntax: %q{s}",true)
$m.f_puts    %q{Hello World1}
$m.f_thm("use syntax: %q/s/",true)
$m.f_puts    %q/Hello World2/
$m.f_thm("use syntax: %q*s*",true)
$m.f_puts    %q*Hello World3*

#   string repeat
$m.f_thm("string repeat")
s   =   "Hello"
i   =   3
$m.f_put "repeat <#{s}> * <#{i}>  := " + s*i + ";\n"

#
#   string functions
#
$m.f_thm("string functions")

#   output
$m.f_thm("function :puts ",true,__LINE__)
$m.f_puts    "'puts'  Text with inclusive line feed"
s   =   "Anton"
puts "%s" % s.m_blue

$m.f_thm("function :print",true,__LINE__)
$m.f_put   "'print' Text Normal with no implicit lineFeed\n" # noLineFeed
s='Peter'
print("#{s}\n".m_blue)

$m.f_thm("function: printf : with formats '%'",true,__LINE__)
i=1;s='Willy'
printf("NAME:<%s>;",s)      # color not possible
printf("NUMBER:<%03d>\n",i)

#   format strings
$m.f_thm("format strings WITH sprintf",true,__LINE__)
sTxt = "Albert Einstein"; i=26; s=sTxt; $m.f_inf("use s:'#{s}';i:#{i}")
x = sprintf("%-20s...is:%d",s,i);  $m.f_puts "s.sprintf() =: #{x}"

#
#   substrings
#
$m.f_thm("build substrings with s[..]")
s = sLetter                                             # "ABCDEFGHIJ"
$m.f_inf("use s:'#{s}'")
#
x = s[0]     ; $m.f_puts "s[0]        =: '#{x}'"        # <A>
x = s[-1]    ; $m.f_puts "s[-1]       =: '#{x}'"        # <J>
x = s[-2]    ; $m.f_puts "s[-2]       =: '#{x}'"        # <I>
x = s[1,4]   ; $m.f_puts "s[1,4]      =: '#{x}'"        # <BCDE>
x = s[1..4]  ; $m.f_puts "s[1..4]     =: '#{x}'"        # <BCDE>
x = s[1,-3]  ; $m.f_puts "s[1,-3]     =: '#{x}':?"      # <> : NOK
x = s[1..-3] ; $m.f_puts "s[1..-3]    =: '#{x}'"        # <BCDEFGH>

#
#   string handling
#
$m.f_thm("Simple string handling")
s = sLetter;
sTmp = "ABC"

#   compare
$m.f_thm("compare strings",true,__LINE__)
s       = sLetter; sTmp    = sText
b = s==sTmp ; $m.f_puts "?('#{s}' == '#{sTmp}')   =: <" + b.to_s + ">"  # false
b = s!=sTmp ; $m.f_puts "?('#{s}' != '#{sTmp}')   =: <" + b.to_s + ">"  # true

#   casecmp - similiar to spaceship-op:'<=>'
s='ABCxyz';
s='abc';t='abc';x=s.casecmp(t); $m.f_puts "'#{s}'.casecmp('#{t}')=:'#{x}'"; #0
s='abc';t='xyz';x=s.casecmp(t); $m.f_puts "'#{s}'.casecmp('#{t}')=:'#{x}'"; #-1
s='xyz';t='abc';x=s.casecmp(t); $m.f_puts "'#{s}'.casecmp('#{t}')=:'#{x}'"; #1

#   concat strings
$m.f_thm("Concatenations(stack like)",true,__LINE__)
s1 = "Anton"
s2 = "Bert"
s3 = "Cleo"
$m.f_puts "s1:#{s1},s2:{s2},s3:{s3}"
x = s1+s2+s3 ;      $m.f_puts "x = s1+s2+s3     => <#{x}>"   # AntonBertCleo
x = s1<<s2<<s3;     $m.f_puts "x = s1<<s2<<s3   => <#{x}>"   # AntonBertCleo

#problems with concatenate
$m.f_thm("Clone vs Copy",true,__LINE__)
s1="Anton"; s2="Bert"
s1=s2           # this is a pointer copy!
s2 << ":Peter"
$m.f_puts "s1=<#{s1}>;s2=<#{s2}>" # s1==s2='Bert:Peter'

s1="Anton"; s2="Bert"
s1=s2.clone     # cloning is better
s2 << ":Peter"
$m.f_puts "s1=<#{s1}>;s2=<#{s2}>" # s1='Bert'; s2='Bert:Peter'

#   $m.f_bug("hello",__FILE__,__LINE__)

#   calculate methods
$m.f_thm("calc methods",true)
x = s.length    ;   $m.f_puts "#{s}.length        =: '#{x}'"    # <10>
x = s.size      ;   $m.f_puts "#{s}.size          =: '#{x}'"    # <10>

#   check methods
$m.f_thm("check",true)
x = s.empty?    ;   $m.f_puts "#{s}.empty?        =: '#{x}'"    # <false>

#
#   change methods
#
$m.f_thm("change : s.<method>: downcase,upcase,capitalize,swapcase,reverse",true,__LINE__)
s = sText; # $m.f_inf("use : '#{s}'")

#   downcase
s="Oliver Kahn steht im Tor!";
x = s.downcase    ; $m.f_puts "'#{s}'.downcase        =: '#{x}'";
x = s.downcase!   ; $m.f_puts "'#{s}'.downcase!    => s: '#{s}'";
s="Oliver Kahn steht im Tor!";

#   upcase
x = s.upcase      ; $m.f_puts "'#{s}'.upcase          =: '#{x}'";
x = s.upcase!     ; $m.f_puts "'#{s}'.upcase!      => s: '#{s}'";

#   capitalize
s="Oliver Kahn steht im Tor!";
x = s.capitalize  ; $m.f_puts "'#{s}'.capitalize      =: '#{x}'";
x = s.capitalize! ; $m.f_puts "'#{s}'.capitalize!  => s: '#{s}'";

#   swapcase
s="Oliver Kahn steht im Tor!";
x = s.swapcase    ; $m.f_puts "'#{s}'.swapcase        =: '#{x}'";
x = s.swapcase!   ; $m.f_puts "'#{s}'.swapcase!    => s: '#{s}'";

#   reverse
s="Oliver Kahn steht im Tor!";
x = s.reverse     ; $m.f_puts "'#{s}'.reverse         =: '#{x}'";
x = s.reverse!    ; $m.f_puts "'#{s}'.reverse!    =>  s: '#{s}'";

#
#   calc and change by string-parameter s.<method>(<sPar>)
#
$m.f_thm("change or calc : s.<method>[.(pS)] : count,delete,squeeze",true,__LINE__)
sText="Oliver Kahn steht im Tor!";s=sText
s=sText; $m.f_inf("s:='#{s}'")

#   count
c='e';  x=s.count(c);   $m.f_puts "#{s}.count('#{c}') =: '#{x}'"    # <10>
c='ae'; x=s.count(c);   $m.f_puts "#{s}.count('#{c}') =: '#{x}'"    # <10>

#   delete special chars
c='e';  x=s.delete(c);  $m.f_puts "'#{s}'.delete('#{c}') =: '#{x}'";
c='ae'; x=s.delete(c);  $m.f_puts "'#{s}'.delete('#{c}') =: '#{x}'";

#   remove method: squeeze[(c)] : remove duplicates
s='bookkeeper'; c = 'e' #   $m.f_inf("use : '#{s}'")
x = s.squeeze   ;   $m.f_puts "'#{s}'.squeeze           =: '#{x}'";  # bokeper
x = s.squeeze(c) ;  $m.f_puts "'#{s}'.squeeze('#{c}')   =: '#{x}'";  # bookkeper

#
#   casting - use : to_s,to_i,to_f
#
$m.f_thm("castings - use {to_s,to_i, to_f} ('%s,%d,%f')",true,__LINE__)
x = "1000"
$m.f_inf("use x:'#{x}'")
s=sprintf("cast s2s : %s\n",x.to_s);        $m.f_print s            # 1000
s=sprintf("cast s2i : %d\n",x.to_i);        $m.f_print s            # 1000
s=sprintf("cast s2f : %2.2f\n",x.to_f);     $m.f_print s            # 1000.00

#
#   chop && chomp && trim
#
$m.f_thm("remove leading or trailing chars")
sTxt = "ABCDEFG"
$m.f_inf("use s:'#{sTxt}'")

#   chop - only cut '\n'
$m.f_thm("chop",true,__LINE__)
s = sTxt + "\n"
l1 = s.length; x = s.chop; l2 = x.length
$m.f_puts "s.chop =: s:'#{x}' l1:#{l1} l2:#{l2}";
l1 = s.length; s.chop!; l2 = s.length
$m.f_puts "s.chop! =: s:'#{s}' l1:#{l1} l2:#{l2}";

#   chomp cuts '\r\n'
$m.f_thm("chomp",true,__LINE__)
s = sTxt + "\r\n"   # only works like this
l1 = s.length; x = s.chomp; l2 = x.length
$m.f_puts "s.chomp =: 's:#{x}' l1:#{l1} l2:#{l2}";
l1 = s.length; x = s.chomp!; l2 = x.length
$m.f_puts "s.chomp! =: s:'#{s}' l1:#{l1} l2:#{l2}";

#   chomp with parameter
$m.f_thm("chomp(s)",true,__LINE__)
m = "xyz"
s = sTxt+m; x = s.chomp(m); $m.f_puts "'#{s}'.chomp('#{m}') =: '#{x}'"; # 'ABCDEFG'
s = sTxt+'y'; x = s.chomp(m); $m.f_puts "'#{s}'.chomp('#{m}') =: '#{x}'"; # 'ABCDEFGy'
s = sTxt+'l'; x = s.chomp(m); $m.f_puts "'#{s}'.chomp('#{m}') =: '#{x}'"; # 'ABCDEFGl'

#   strip[!]
$m.f_thm("strip",true,__LINE__)
sTxt = " \t  Albert Einstein ist hier!   "
lTxt = sTxt.length
$m.f_inf("use s:'#{sTxt}' with l:#{lTxt}")
#   strip
s=sTxt; x=s.strip;  l=x.length
$m.f_puts "x=s.strip  =: x:'#{x}' \tx.length:#{l}";
#   strip   left
sTxt = "    Albert Einstein ist hier!   "
s=sTxt; x=s.lstrip; l=x.length
$m.f_puts "x=s.lstrip =: x:'#{x}' \tx.length:#{l}";
#   strip   right
sTxt = "    Albert Einstein ist hier!   "
s=sTxt; x=s.rstrip; l=x.length
$m.f_puts "x=s.rstrip =: x:'#{x}'\tx.length:#{l}";
#   strip!  # change source
sTxt = "    Albert Einstein ist hier!   "
s=sTxt; s.strip!; l=s.length
$m.f_puts "s.strip! =: s:'#{s}'\ts.length:#{l}";

$m.f_thm("slice",true,__LINE__)
sTxt = "ABCDEFGHHIJ"
$m.f_inf("use s:'#{sTxt}'")
s=sTxt; i=0; s=sTxt.slice(i); $m.f_puts "s.slice(#{i}) => <#{s}>";        # A
s=sTxt; i=1; s=sTxt.slice(i); $m.f_puts "s.slice(#{i}) => <#{s}>";        # B
s=sTxt; i=2..5; s=sTxt.slice(i); $m.f_puts "s.slice(#{i}) => <#{s}>";     # CDEF
s=sTxt; i=2...5; s=sTxt.slice(i); $m.f_puts "s.slice(#{i}) => <#{s}>";    # CDE
s=sTxt; i='D'; s=sTxt.slice(i); $m.f_puts "s.slice(#{i}) => <#{s}>";    # 'D'
s=sTxt; i='X'; s=sTxt.slice(i); $m.f_puts "s.slice(#{i}) => <#{s}>";    # ''

s=sTxt; sTmp='DEF'; s=sTxt.slice(sTmp); $m.f_puts "s.slice(#{sTmp}) => <#{s}>";    # DEF

#
#   substitute strings
#
$m.f_thm("substitute with 'sub' and 'gsub'")

#   sub
$m.f_thm("sub",true,__LINE__)
a = 'A'
x = 'x'
sTmp    = sLetter
s       = sTmp << '|' << sTmp       # ACHTUNG
y       = s.sub(a,x); $m.f_puts "#{s}.sub(#{a},#{x},)      =: <" + y.to_s + ">"
#   =>  <xBCDEFGHIJ|ABCDEFGHIJ|>

#   gsub
$m.f_thm("gsub=sub multiple",true,__LINE__)
y = s.gsub(a,x); $m.f_puts "#{s}.gsub(#{a},#{x})    =: <" + y.to_s + ">"
#   =>  <xBCDEFGHIJ|xBCDEFGHIJ|>

#
#   search in strings
#
$m.f_thm("search in strings")
sTxt = "Albert Einstein is a Genie not a Hubert"
$m.f_inf("use s:'#{sTxt}'")
s = sTxt

#   index - look from left to right
$m.f_thm("index",true,__LINE__)
m = '?a'.to_sym # ?PHA: using symbols?
x=s.index(?a);  $m.f_puts "s.index(?a)) =: #{x}" # 19
m="bert"; x = s.index(m);  $m.f_puts "s.index('#{m}')) =: #{x}" # 2
x = s.index(/rt/);  $m.f_puts "s.index(/rt/)) =: #{x}" # 4

#   rindex - look from right to left
$m.f_thm("rindex",true,__LINE__)
x=s.rindex(?a);  $m.f_puts "s.rindex(?a)) =: #{x}" # 31
m="bert"; x = s.rindex(m);  $m.f_puts "s.rindex('#{m}')) =: #{x}" # 35
x = s.rindex(/rt/);  $m.f_puts "s.rindex(/rt/)) =: #{x}" # 37

#   include?
$m.f_thm("include?",true,__LINE__)
a = 'A'
x=s.include? a;  $m.f_puts "s.include ?('#{a}') =: #{x}" # true
x="bert"; x = s.include?(m);  $m.f_puts "s.include('#{m}')) =: #{x}" # true
aPrj = "ProjectW"
bPrj = "Project"
x=aPrj.include? bPrj;  $m.f_puts "'#{aPrj}'.include ? '#{bPrj}' =: #{x}" # true
x=bPrj.include? aPrj;  $m.f_puts "'#{bPrj}'.include ? '#{aPrj}' =: #{x}" # false

#   scan?
$m.f_thm("scan",true,__LINE__)
s = "abracadabra"
x = s.scan(/a./);  $m.f_puts "s.scan(/a./) =: #{x}" # => ["ab,"ac,"ad","ab"]
x = x.class;  $m.f_puts "x.class =: <#{x}> ;"     # Array

#
#   split strings with 'split' into arrays (s2a)
#
$m.f_thm("split strings")
sTxt = "Albert Einstein, is a Genie not a Hubert"; $m.f_inf("use s:'#{sTxt}'")
s=sTxt;
c = ','; x = s.split(c);  $m.f_puts "s.split('#{c}') =: #{x}"
c = 'a'; x = s.split(c);  $m.f_puts "s.split('#{c}') =: #{x}"
x = x.class;  $m.f_puts "x.class =: <#{x}> ;"     # Array

$m.f_end()

