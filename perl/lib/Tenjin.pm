##
## $Copyright: copyright(c) 2007-2010 kuwata-lab.com all rights reserved.$
## $License: MIT License $
##
## Permission is hereby granted, free of charge, to any person obtaining
## a copy of this software and associated documentation files (the
## "Software"), to deal in the Software without restriction, including
## without limitation the rights to use, copy, modify, merge, publish,
## distribute, sublicense, and/or sell copies of the Software, and to
## permit persons to whom the Software is furnished to do so, subject to
## the following conditions:
##
## The above copyright notice and this permission notice shall be
## included in all copies or substantial portions of the Software.
##
## THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
## EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
## MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
## NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
## LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
## OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
## WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
##


package Tenjin;
#use strict;

our $USE_STRICT     = undef;
our $BYPASS_TAINT   = 1;          # unset if you like taint mode
our $TEMPLATE_CLASS = 'Tenjin::Template';
our $CONTEXT_CLASS  = 'Tenjin::Context';
our $PREPROCESSOR_CLASS = 'Tenjin::Preprocessor';
our $VERSION        = (split(' ', '$Release: 0.0.0 $'))[1];
our $WARNING        = 0;
our $logger         = undef;

sub import {
    my ($klass, %opts) = @_;
    $USE_STRICT = $opts{strict}  if defined $opts{strict};
    $WARNING    = $opts{warning} if defined $opts{warning};
}

our %_H = ( '&'=>'&amp;', '<'=>'&lt;', '>'=>'&gt;', '"'=>'&quot;', "'"=>'&#039;' );


##
## utilities
##
package Tenjin::Util;


sub read_file {
    my ($filename, $lock_required) = @_;
    open(my $fh, $filename)  or die "$filename: $!";
    binmode($fh);
    my $content = '';
    flock($fh, 1) if $lock_required;
    read($fh, my $data, -s $filename);
    close($fh);
    return $data;
}


sub write_file {
    my ($filename, $content, $lock_required, $mtime) = @_;
    my $fname = $filename;
    $fname .= rand() if $lock_required;
    open(my $fh, ">$fname")  or die "$filename: $!";
    binmode($fh);
    #flock($fh, 2) if $lock_required
    print $fh $content;
    close($fh);
    utime($mtime, $mtime, $fname) if $mtime;
    rename($fname, $filename) if $lock_required;
}


sub _path_join {
    my $sep = $^O eq 'MSWin32' ? '\\\\' : '/';
    return join($sep, @_);
}


sub expand_tabs {
    my ($str, $tabwidth) = @_;
    $tabwidth = 8 unless defined $tabwidth;
    my $s = '';
    my $pos = 0;
    while ($str =~ /.*?\t/sg) {   ## /(.*?)\t/ may be slow
        my $end = $+[0];
        my $text = substr($str, $pos, $end - 1 - $pos);
        my $n = rindex($text, "\n");
        my $col = $n >= 0 ? length($text) - $n - 1 : length($text);
        $s .= $text;
        $s .= ' ' x ($tabwidth - $col % $tabwidth);
        $pos = $end;
    }
    my $rest = substr($str, $pos);
    $s .= $rest if $rest;
    return $s;
}


sub _p {
    my ($arg) = @_;
    return "<`\#$arg\#`>"
}


sub _P {
    my ($arg) = @_;
    return "<`\$$arg\$`>"
}


sub _decode_params {
    my ($s) = @_;
    $s = '' . $s;
    return '' unless $s;
    $_ = $s;
    s/%3C%60%23(.*?)%23%60%3E/'[=='.Tenjin::Helper::Html::decode_url($1).'=]'/ge;
    s/%3C%60%24(.*?)%24%60%3E/'[='.Tenjin::Helper::Html::decode_url($1).'=]'/ge;
    s/&lt;`\#(.*?)\#`&gt;/'[=='.Tenjin::Helper::Html::unescape_xml($1).'=]'/ge;
    s/&lt;`\$(.*?)\$`&gt;/'[='.Tenjin::Helper::Html::unescape_xml($1).'=]'/ge;
    s/<`\#(.*?)\#`>/[==$1=]/g;
    s/<`\$(.*?)\$`>/[=$1=]/g;
    return $_;
}



##
## safe string
##
package Tenjin::SafeStr;


sub new {
    #my ($class, $value) = @_;
    #return bless { value => $value }, $class;
    bless { value => $_[1] }, $_[0];
}


sub value {
    #my ($this) = @_;
    #return $this->{value};
    $_[0]->{value};
}



##
## helpers for SafeStr
##
##  argument    -> return       no escape           do escape
##  -------------------------------------------------------------------------
##  str         -> SafeStr      safe_str($x)        safe_str(escape_html($x))
##  str/SafeStr -> SafeStr      to_safe_str($x)     safe_str(safe_escape($x))
##  str/SafeStr -> str          to_str($x)          safe_escape($x)
##
package Tenjin::Helper::Safe;
use Exporter 'import';
our @EXPORT = qw(safe_str is_safe_str to_safe_str to_str safe_escape);


sub safe_str {
    Tenjin::SafeStr->new($_[0]);    # return
}


sub is_safe_str {
    ref($_[0]) eq 'Tenjin::SafeStr';  # return
}


sub to_safe_str {
    #is_safe_str($_[0]) ? $_[0] : safe_str($_[0]);  # return
    ref($_[0]) eq 'Tenjin::SafeStr' ? $_[0] : Tenjin::SafeStr->new($_[0]);  # return
}


sub to_str {
    #is_safe_str($_[0]) ? $_[0]->{value} : $_[0];  # return
    ref($_[0]) eq 'Tenjin::SafeStr' ? $_[0]->{value} : $_[0];  # return
}


sub safe_escape {
    is_safe_str($_[0]) ? $_[0]->{value} : escape_xml($_[0]);  # return
}



##
## helpers for html
##
package Tenjin::Helper::Html;
use Exporter 'import';
our @EXPORT = qw(escape_xml unescape_xml encode_url decode_url
                 checked selected disabled nl2br text2html tagattr tagattrs nv new_cycle);


our %ESCAPE_HTML = ( '&'=>'&amp;', '<'=>'&lt;', '>'=>'&gt;', '"'=>'&quot;', "'"=>'&#039;');


sub escape_xml {
    #my ($s) = @_; $s =~ s/[&<>"]/$ESCAPE_HTML{$&}/ge; return $s;       # 7.63
    #my ($s) = @_; $s =~ s/[&<>"]/$ESCAPE_HTML{$&}/ge; $s;              # 7.48
    #my $s = shift; $s =~ s/[&<>"]/$ESCAPE_HTML{$&}/ge; $s;             # 7.44
    #my $s = $_[0]; $s =~ s/[&<>"]/$ESCAPE_HTML{$&}/ge; $s;             # 7.28
    #my $s; ($s = $_[0]) =~ s/[&<>"]/$ESCAPE_HTML{$&}/ge; $s;           # 7.27
    (my $s = $_[0]) =~ s/[&<>"]/$ESCAPE_HTML{$&}/ge; $s;               # 7.19
    #$_[0] =~ s/[&<>"]/$ESCAPE_HTML{$&}/ge; $_[0];                      # error
    #($_ = $_[0]) =~ s/[&<>"]/$ESCAPE_HTML{$&}/ge; $_;                  # 7.21
    #my $s; (($s = $_[0]) =~ s/[&<>"]/$ESCAPE_HTML{$&}/ge, $s)[1];      # 7.49
    #(($_ = $_[0]) =~ s/[&<>"]/$ESCAPE_HTML{$&}/ge, $_)[1];             # 7.43
    #my $s; ($s = $_[0]) =~ s/[&<>"]/$ESCAPE_HTML{$&}/ge && undef, $s;  # 7.46
    #my $s; ($s = $_[0]) =~ s/[&<>"]/$ESCAPE_HTML{$&}/ge ? $s : $s;     # 7.30
    #my $s; ($s = $_[0]) =~ s/[&<>"]/$ESCAPE_HTML{$&}/ge && $s || $s;   # 7.39
    #{ my $s; ($s = $_[0]) =~ s/[&<>"]/$ESCAPE_HTML{$&}/ge; $s };       # 7.68
    #
    #$_ = $_[0]; s/&/&amp;/g; s/</&lt;/g; s/>/&gt;/g; s/"/&quot;/g; $_;    # 7.59
    #($_ = $_[0]) =~ s/&/&amp;/g; s/</&lt;/g; s/>/&gt;/g; s/"/&quot;/g; $_;  # 7.61
    #my $s=$_[0]; $s=~s/&/&amp;/g; $s=~s/</&lt;/g; $s=~s/>/&gt;/g; $s=~s/"/&quot;/g; $s;    # 7.70
    #(my $s=$_[0])=~s/&/&amp;/g; $s=~s/</&lt;/g; $s=~s/>/&gt;/g; $s=~s/"/&quot;/g; $s;    # 7.67

}

*Tenjin::Helper::Safe::escape_xml = *escape_xml;


our %UNESCAPE_HTML = ('lt'=>'<', 'gt'=>'>', 'amp'=>'&', 'quot'=>'"', '#039'=>"'");


sub unescape_xml {
    my $s = $_[0];
    $s =~ tr/+/ /;
    $s =~ s/&(lt|gt|amp|quot|#039);/$UNESCAPE_HTML{$1}/ge;
    $s;  # returns
}


sub encode_url {
    my $s = $_[0];
    $s =~ s/([^-A-Za-z0-9_.\/])/sprintf("%%%02X", ord($1))/sge;
    $s =~ tr/ /+/;
    $s;  # returns
}


sub decode_url {
    my $s = $_[0];
    #$s =~ s/\%([a-fA-F0-9][a-fA-F0-9])/pack('H2', $1)/sge;
    $s =~ s/\%([a-fA-F0-9][a-fA-F0-9])/pack('C', hex($1))/sge;
    $s;  # returns
}


sub checked {
    $_[0] ? ' checked="checked"' : '';  # returns
}


sub selected {
    $_[0] ? ' selected="selected"' : '';  # returns
}


sub disabled {
    $_[0] ? ' disabled="disabled"' : '';  # returns
}


sub nl2br {
    my $text = $_[0];
    #$text = Tenjin::Helper::Html::escape_xml($text);
    $text =~ s/(\r?\n)/<br \/>$1/g;
    $text;  # returns
}


sub text2html {
    my $text = $_[0];
    $text = Tenjin::Helper::Html::escape_xml($text);
    $text =~ s/(\r?\n)/<br \/>$1/g;
    $text;  # returns
}


sub tagattr {   ## [experimental]
    my ($name, $expr, $value) = @_;
    return '' unless $expr;
    $value = $expr unless defined $value;
    " $name=\"".escape_xml($value)."\"";   # returns
}


sub tagattrs {   ## [experimental]
    my (%attrs) = @_;
    my $s = "";
    while (my ($k, $v) = each %attrs) {
        $s .= " $k=\"".escape_xml($v)."\"" if defined $v;
    }
    $s;  # returns
}


## ex.
##   nv('pair', 'Haru&Kyon')  #=> 'name="pair" value="Haru&amp;Kyon"'
sub nv {   ## [experimental]
    my ($name, $value) = @_;
    'name="'.$name.'" value="'.escape_xml($value).'"';  # return
}


## ex.
##   my $cycle = new_cycle('red', 'blue');
##   print $cycle->();  #=> 'red'
##   print $cycle->();  #=> 'blue'
##   print $cycle->();  #=> 'red'
##   print $cycle->();  #=> 'blue'
sub new_cycle {   ## [experimental]
    my @items = @_;
    my $len = @items;
    my $i = 0;
    sub { $items[$i++ % $len] };  # returns
}



##
## html helpers for SafeTemplate and SafeEngine
##
package Tenjin::Helper::SafeHtml;
use Exporter 'import';
our @EXPORT = qw(checked selected disabled nl2br text2html tagattr tagattrs nv new_cycle);
import Tenjin::Helper::Safe;


sub import {
    _import();
    goto &Exporter::import;
}


sub _import {
    *Tenjin::Context::checked   = *checked;
    *Tenjin::Context::selected  = *selected;
    *Tenjin::Context::disabled  = *disabled;
    *Tenjin::Context::nl2br     = *nl2br;
    *Tenjin::Context::text2html = *text2html;
    *Tenjin::Context::tagattr   = *tagattr;
    *Tenjin::Context::tagattrs  = *tagattrs;
    *Tenjin::Context::nv        = *nv;
    *Tenjin::Context::new_cycle = *new_cycle;
}


my $_empty    = safe_str('');
my $_checked  = safe_str(' checked="checked"');
my $_selected = safe_str(' selected="selected"');
my $_disabled = safe_str(' disabled="disabled"');


sub checked {
    $_[0] ? $_checked : $_empty;  # return
}


sub selected {
    $_[0] ? $_selected : $_empty;  # return
}


sub disabled {
    $_[0] ? $_disabled : $_empty;  # return
}


sub nl2br {
    my $text = to_str($_[0]);
    $text =~ s/(\r?\n)/<br \/>$1/g;
    safe_str($text);  # return
}


sub text2html {
    my $text = safe_escape($_[0]);
    $text =~ s/(\r?\n)/<br \/>$1/g;
    safe_str($text);  # return
}


sub tagattr {   ## [experimental]
    my ($name, $expr, $value) = @_;
    return safe_str('') unless $expr;
    $value = $expr unless defined $value;
    safe_str(" $name=\"".safe_escape($value)."\"");   # return
}


sub tagattrs {   ## [experimental]
    my (%attrs) = @_;
    my $s = "";
    while (my ($k, $v) = each %attrs) {
        $s .= " $k=\"".safe_escape($v)."\"" if defined $v;
    }
    safe_str($s);  # return
}


sub nv {   ## [experimental]
    my ($name, $value) = @_;
    safe_str('name="'.$name.'" value="'.safe_escape($value).'"');  # return
}


sub new_cycle {   ## [experimental]
    my @items = map { safe_str(safe_escape($_)) } @_;
    my $len = @items;
    my $i = 0;
    sub { $items[$i++ % $len] };  # return
}



##
## base class of context object
##
package Tenjin::BaseContext;


sub new {
    my ($class, $this) = @_;
    $this = { } unless defined $this;
    return bless $this, $class;
}


sub _cache_with {
    my $code_block = pop @_;
    my $_context   = pop @_;
    my $cache_key  = shift @_;
    my $store = $_context->{_store}  or die "key-value store for fragment cache is not passed.";
    my $fragment  = $store->get($cache_key);
    unless (defined($fragment)) {
        $fragment = $code_block->();
        $store->set($cache_key, $fragment, @_);
    }
    return $fragment;
}


## ex. {x=>10, y=>20} ==> "my $x = $_context->{'x'}; my $y = $_context->{'y'}; "
sub _build_decl {
    my ($context) = @_;
    my $s = '';
    while (my ($k, ) = each %$context) {
        $s .= "my \$$k = \$_context->{'$k'}; " unless $k eq '_context';
    }
    return $s;
}


our $defun = '# line '.(__LINE__+1).' "'.__FILE__.'"'."\n" . <<'END';
sub evaluate {
    my ($_this, $_script, $_filename) = @_;
    my $_context = $_this;
    $_script = ($_script =~ /\A.*\Z/s) && $& if $Tenjin::BYPASS_TAINT;
    my $_s = $_filename ? "# line 1 \"$_filename\"\n" : '';  # line directive
    $_s = $_s.$_script;
    return eval($_s) unless $Tenjin::USE_STRICT;
    use strict;
    return eval($_s);
}


sub to_func {    # returns closure
    my ($_klass, $_script, $_filename) = @_;
    $_script = ($_script =~ /\A.*\Z/s) && $& if $Tenjin::BYPASS_TAINT;
    my $_s = $_filename ? "# line 1 \"$_filename\"\n" : '';  # line directive
    $_s = "${_s}sub { my (\$_context) = \@_; $_script }";
    return eval($_s) unless $Tenjin::USE_STRICT;
    use strict;
    return eval($_s);
}

*cache_with = *Tenjin::BaseContext::_cache_with;

END

eval $defun;


sub escape {
    #my $arg = $_[0];  return $arg;
    $_[0];      # returns as is
}


*_p = *Tenjin::Util::_p;
*_P = *Tenjin::Util::_P;



##
## common context object class which supports safe and html helpers
##
package Tenjin::Context;
our @ISA = ('Tenjin::BaseContext');

our $defun = $Tenjin::BaseContext::defun;
eval $defun;

*_p           = *Tenjin::Util::_p;
*_P           = *Tenjin::Util::_P;

import Tenjin::Helper::Safe;
import Tenjin::Helper::Html;



##
## template class
##
## ex.
##   ## convert file into perl script
##   use Tenjin strict=>1;   ## 'strict=.1' is optional
##   my $template = new Tenjin::Template('example.plhtml');
##   print $template->{script};
##   ## or
##   my $template = new Tenjin::Template();
##   my $input = Tenjin::Util::read_file('example.plhtml');
##   print $template->convert($input, 'example.plhtml');   # filename is optional
##   ## evaluate converted perl script with context data
##   my $context = { 'title'=>'Example', 'items'=>['A','B','C'], };
##   $template->compile();  ## optional
##   print $template->render($context);
##
package Tenjin::Template;


sub new {
    my ($class, $filename, $opts) = @_;
    my $escapefunc = defined($opts) && exists($opts->{escapefunc}) ? $opts->{escapefunc} : undef;
    my $this = {
        'filename'   => $filename,
        'script'     => undef,
        'escapefunc' => $escapefunc,
        'timestamp'  => undef,
        'args'       => undef,
    };
    #return bless($this, $class);
    $this = bless($this, $class);
    $this->convert_file($filename) if $filename;
    return $this;
}


sub _read_file {
    my $this = shift;
    return Tenjin::Util::read_file(@_);
}


sub _render {
    my ($this, $context) = @_;
    $context = {} unless $context;
    if ($this->{func}) {
        return $this->{func}->($context);
    }
    else {
        if (ref($context) eq 'HASH') {
            my $klass = $Tenjin::CONTEXT_CLASS; # || Tenjin::Context;
            $context = $klass->new($context);
        }
        my $script = $this->{script};
        $script = Tenjin::BaseContext::_build_decl($context) . $script unless $this->{args};
        return $context->evaluate($script, $this->{filename});
    }
}


sub render {
    my $this = shift;
    #my $output = $this->{func} ? $this->{func}->(@_) : $this->_render(@_);
    my $output = $this->_render(@_);
    if ($@) {  # error happened
        my $template_filename = $this->{filename};
        die "*** ERROR: " . $this->{filename} . "\n", $@;
    }
    return $output;
}


sub convert_file {
    my ($this, $filename) = @_;
    my $input = $this->_read_file($filename);
    my $script = $this->convert($input);
    $this->{filename} = $filename;
    #$this->{input}    = $input;
    return $script;
}


sub convert {
    my ($this, $input, $filename) = @_;
    $this->{filename} = $filename;
    my @buf = $this->{escapefunc} ?
              ('my $_buf = ""; ', ) :
              ('my $_buf = ""; my $_V; ', );
    $this->parse_stmt(\@buf, $input);
    return $this->{script} = $buf[0] . " \$_buf;\n";
}


sub compile_stmt_pattern {
    my ($pi) = @_;
    my $pat = '((^[ \t]*)?<\?'.$pi.'( |\t|\r?\n)(.*?) ?\?>([ \t]*\r?\n)?)';
    return qr/$pat/sm;
}


#my $STMT_PATTERN = qr/((^[ \t]*)?<\?pl( |\t|\r?\n)(.*?) ?\?>([ \t]*\r?\n)?)/sm;
my $STMT_PATTERN = compile_stmt_pattern('pl');


sub stmt_pattern {
    my $this = shift;
    return $STMT_PATTERN;
}


sub parse_stmt {
    my ($this, $bufref, $input) = @_;
    my $pos = 0;
    my $pat = $this->stmt_pattern();
    while ($input =~ /$pat/g) {
        my ($pi, $lspace, $mspace, $stmt, $rspace) = ($1, $2, $3, $4, $5);
        my $start = $-[0];
        my $text = substr($input, $pos, $start - $pos);
        $pos = $start + length($pi);
        $this->parse_expr($bufref, $text) if $text;
        $mspace = '' if $mspace eq ' ';
        $stmt = $this->hook_stmt($stmt);
        $this->add_stmt($bufref, $lspace . $mspace . $stmt . $rspace);
    }
    my $rest = $pos == 0 ? $input : substr($input, $pos);
    $this->parse_expr($bufref, $rest) if $rest;
}


sub hook_stmt {
    my ($this, $stmt) = @_;
    ## macro expantion
    if ($stmt =~ /\A(\s*)(\w+)\((.*?)\);?(\s*)\Z/) {
        my ($lspace, $funcname, $arg, $rspace) = ($1, $2, $3, $4);
        my $s = $this->expand_macro($funcname, $arg);
        return $lspace . $s . $rspace if defined $s;
    }
    ## template arguments
    if (! $this->{args}) {
        if ($stmt =~ m/\A(\s*)\#\@ARGS\s+(.*)(\s*)\Z/) {
            my ($lspace, $argstr, $rspace) = ($1, $2, $3);
            my @args = ();
            my @declares = ();
            for my $arg (split(',', $argstr)) {
                $arg =~ s/(^\s+|\s+$)//g;
                next unless $arg;
                $arg =~ m/\A([\$\@\%])?([a-zA-Z_]\w*)\Z/  or die "$arg: invalid template argument.";
                ! $1 || $1 eq '$'  or die "$arg: only '\$var' is available for template argument.";
                my $name = $2;
                push(@args, $name);
                push(@declares, "my \$$name = \$_context->{$name}; ");
            }
            $this->{args} = \@args;
            return $lspace . join('', @declares) . $rspace;
        }
    }
    ##
    return $stmt;
}


our $MACRO_HANDLER_TABLE = {
    'include' => sub { my ($arg) = @_;
        " \$_buf .= \$_context->{_engine}->_include(\$_context, $arg);";
    },
    'start_capture' => sub { my ($arg) = @_;
        " my \$_buf_bkup=\$_buf; \$_buf=''; my \$_capture_varname=$arg;";
    },
    'stop_capture' => sub { my ($arg) = @_;
        " \$_context->{\$_capture_varname}=\$_buf; \$_buf=\$_buf_bkup;";
    },
    'start_placeholder' => sub { my ($arg) = @_;
        " if (\$_context->{$arg}) { \$_buf .= \$_context->{$arg}; } else {";
    },
    'stop_placeholder' => sub { my ($arg) = @_;
        " }";
    },
    'echo' => sub { my ($arg) = @_;
        " \$_buf .= $arg;";
    },
    'start_cache' => sub { my ($arg) = @_;
        ' $_buf .= cache_with(' . $arg . ', $_context, sub { my $_buf = "";';
    },
    'stop_cache' => sub { my ($arg) = @_;
        '$_buf });';
    },
};


sub expand_macro {
    my ($this, $funcname, $arg) = @_;
    my $handler = $Tenjin::Template::MACRO_HANDLER_TABLE->{$funcname};
    return $handler ? $handler->($arg) : undef;
}


my $EXPR_PATTERN = qr/\[=(=?)(.*?)(=?)=\]/s;


sub expr_pattern {
    my $this = shift;
    return $EXPR_PATTERN;
}


## ex. capture_expr('=', '$item->{name}', '')  => 1, '$item->{name}', 0
sub capture_expr {
    my ($this, $m1, $m2, $m3) = @_;
    my ($not_escape, $expr, $delete_newline) = ($m1, $m2, $m3);
    return $expr, $not_escape eq '', $delete_newline eq '=',
}


sub parse_expr {
    my ($this, $bufref, $input) = @_;
    my $pos = 0;
    $this->start_text_part($bufref);
    my $pat = $this->expr_pattern();
    while ($input =~ /$pat/g) {
        my $start = $-[0];
        my $text = substr($input, $pos, $start - $pos);
        my ($expr, $flag_escape, $delete_newline) = $this->capture_expr($1, $2, $3);
        $pos = $start + length($&);
        $this->add_text($bufref, $text) if $text;
        $this->add_expr($bufref, $expr, $flag_escape) if $expr;
        if ($delete_newline) {
            my $end = $+[0];
            if (substr($input, $end+1, 1) == "\n") {
                $bufref->[0] .= "\n";
                $pos += 1;
            }
        }
    }
    my $rest = $pos == 0 ? $input : substr($input, $pos);
    $this->add_text($bufref, $rest);
    $this->stop_text_part($bufref);
}


sub start_text_part {
    my ($this, $bufref) = @_;
    $bufref->[0] .= ' $_buf .= ';
}


sub stop_text_part {
    my ($this, $bufref) = @_;
    $bufref->[0] .= "; ";
}


sub add_text {
    my ($this, $bufref, $text) = @_;
    return unless $text;
    $text =~ s/[`\\]/\\$&/g;
    my $is_start = $bufref->[0] =~ / \$_buf \.= \Z/;
    $bufref->[0] .= $is_start ? "q`$text`" : " . q`$text`";
}


sub add_stmt {
    my ($this, $bufref, $stmt) = @_;
    $bufref->[0] .= $stmt;
}


sub add_expr {
    my ($this, $bufref, $expr, $flag_escape) = @_;
    my $dot = $bufref->[0] =~ / \$_buf \.= \Z/ ? "" : " . ";
    $bufref->[0] .= $dot . ($flag_escape ? $this->escaped_expr($expr) : "($expr)");
}


sub escaped_expr {
    my ($this, $expr) = @_;
    return $this->{escapefunc}
           ? "$this->{escapefunc}($expr)"
           : "((\$_V = ($expr)) =~ s/[&<>\"]/\$Tenjin::_H{\$&}/ge, \$_V)";
}


sub defun {   ## (experimental)
    my ($this, $funcname, @args) = @_;
    if (! $funcname) {
        $_ = $this->{filename};
        s/\.\w+$//  if ($_);
        s/[^\w]/_/g if ($_);
        $funcname = "render_" . $_;
    }
    my $str = '';
    $str .= "sub $funcname {";
    $str .= " my (\$_context) = \@_; ";
    for my $arg (@args) {
        $str .= "my \$$arg = \$_context->{'$arg'}; ";
    }
    $str .= $this->{script};
    $str .= "}\n";
    return $str;
}


## compile $this->{script} into closure.
sub compile {
    my ($this) = @_;
    if ($this->{args}) {
        #my $f = $Tenjin::CONTEXT_CLASS . '::to_func';
        #my $func = $f->($this->{script});
        my $func = $Tenjin::CONTEXT_CLASS->to_func($this->{script}, $this->{filename});
        ! $@  or die "*** Error: " . $this->{filename} . "\n", $@;
        return $this->{func} = $func;
    }
    else {
        warn "[Tenjin.pm] $this->{filename}: Template arguments not found. It is strongly recommended to specify '<?pl #\@ARGS arg1, arg2 ?> for performance and readability." if $Tenjin::WARNING;
    }
    return;
}



##
## safe template class which uses SafeStr
##
package Tenjin::SafeTemplate;
our @ISA = 'Tenjin::Template';


sub escaped_expr {
    my ($this, $expr) = @_;
    return $this->{escapefunc}
           ? "(ref(\$_V = ($expr)) eq 'Tenjin::SafeStr' ? \$_V->{value} : $this->{escapefunc}(\$V)"
           : "(ref(\$_V = ($expr)) eq 'Tenjin::SafeStr' ? \$_V->{value} : (\$_V =~ s/[&<>\"]/\$Tenjin::_H{\$&}/ge, \$_V))";
           #? "(is_safe_str(\$_V = ($expr)) ? \$_V->{value} : $this->{escapefunc}(\$V)"
           #: "(is_safe_str(\$_V = ($expr)) ? \$_V->{value} : (\$_V =~ s/[&<>\"]/\$Tenjin::_H{\$&}/ge, \$_V))";
}


sub capture_expr {
    my ($this, $m1, $m2, $m3) = @_;
    my ($not_escape, $expr, $delete_newline) = ($m1, $m2, $m3);
    #return $expr, $not_escape eq '', $delete_newline eq '=',
    $not_escape eq ''  or die "'[==$expr=]': '[== =]' is not available with Tenjin::SafeTemplate.";
    my $flag_escape = 1;
    if ($expr =~ /\A(\s*)safe_str\((.*?)\)(\s*)\Z/s) {
        $expr = $1 . $2 . $3;
        $flag_escape = undef;
    }
    return $expr, $flag_escape, $delete_newline eq '=';
}



##
## preprocessor
##
package Tenjin::Preprocessor;
our @ISA = ('Tenjin::Template');


our $STMT_PATTERN = Tenjin::Template::compile_stmt_pattern('PL');


sub stmt_pattern {
    my ($this) = @_;
    return $STMT_PATTERN;
}


our $EXPR_PATTERN = qr/\[\*=(=?)(.*?)(=?)=\*\]/s;


sub expr_pattern {
    my ($this) = @_;
    return $EXPR_PATTERN;
}


sub add_expr {
    my ($this, $bufref, $expr, $flag_escape) = @_;
    $expr = "Tenjin::Util::_decode_params($expr)";
    $this->SUPER::add_expr($bufref, $expr, $flag_escape);
}



##
## safe preprocessor class which uses SafeStr
##
package Tenjin::SafePreprocessor;
our @ISA = ('Tenjin::Preprocessor');


sub add_expr {
    my ($this, $bufref, $expr, $flag_escape) = @_;
    my $dot = $bufref->[0] =~ / \$_buf \.= \Z/ ? "" : " . ";
    #$bufref->[0] .= $dot . ($flag_escape ? $this->escaped_expr($expr) : "($expr)");
    $bufref->[0] .= $dot . $this->escaped_expr($expr);
}


sub escaped_expr {
    my ($this, $expr) = @_;
    return $this->{escapefunc}
           ? "(ref(\$_V = ($expr)) eq 'Tenjin::SafeStr' ? Tenjin::Util::_decode_params(\$_V->{value}) : $this->{escapefunc}(\$V)"
           : "(ref(\$_V = ($expr)) eq 'Tenjin::SafeStr' ? Tenjin::Util::_decode_params(\$_V->{value}) : (\$_V = Tenjin::Util::_decode_params(\$_V), \$_V =~ s/[&<>\"]/\$Tenjin::_H{\$&}/ge, \$_V))";
}


sub capture_expr {
    my ($this, $m1, $m2, $m3) = @_;
    my ($not_escape, $expr, $delete_newline) = ($m1, $m2, $m3);
    #return $expr, $not_escape eq '', $delete_newline eq '=',
    $not_escape eq ''  or die "'[*==$expr=*]': '[*== =*]' is not available with Tenjin::SafePreprocessor.";
    return $expr, 1, $delete_newline eq '=',
}



##
## interface of TemplateCache
##
package Tenjin::TemplateCache;


sub save {
    my ($this, $cachepath, $template) = @_;
}


sub load {
    my ($this, $cachepath, $timestamp) = @_;
}



##
## memory base template cache
##
package Tenjin::MemoryBaseTemplateCache;
our @ISA = ('Tenjin::TemplateCache');


sub new {
    my ($class) = @_;
    my $this = {
        values => {},
    };
    return bless($this, $class);
}


sub save {
    my ($this, $cachepath, $template) = @_;
    $this->{cachepath} = $template;
}


sub load {
    my ($this, $cachepath, $timestamp) = @_;
    my $template = $this->{cachepath};
    return unless $template;
    return if $timestamp && $template->{timestamp} != $timestamp;
    return $timestamp;
}



##
## file base template cache
##
package Tenjin::FileBaseTemplateCache;
our @ISA = ('Tenjin::TemplateCache');


sub new {
    my ($class) = @_;
    my $this = {};
    return bless($this, $class);
}


sub save {
    my ($this, $cachepath, $template) = @_;
    #: save template script and args into cache file.
    my $cachestr = $template->{script};
    if (defined($template->{args})) {
        my $args = $template->{args};
        $cachestr = "\#\@ARGS " . join(',', @$args) . "\n" . $cachestr;
    }
    Tenjin::Util::write_file($cachepath, $cachestr, 1);
    #: set cache file's mtime to template timestamp.
    my $ts = $template->{timestamp};
    utime($ts, $ts, $cachepath);
    $Tenjin::logger->debug("[Tenjin.pm:".__LINE__."] template cache saved (path=$cachepath)") if $Tenjin::logger;
}


sub load {
    my ($this, $cachepath, $timestamp) = @_;
    #: if cache file is not found, return undef.
    unless (-f $cachepath) {
        $Tenjin::logger->debug("[Tenjin.pm:".__LINE__."] template cache not found (path=$cachepath)") if $Tenjin::logger;
        return;
    }
    #: if template timestamp is specified and different from that of cache file, return undef.
    my $mtime = (stat $cachepath)[9];
    if ($timestamp && $timestamp != $mtime) {
        $Tenjin::logger->debug("[Tenjin.pm:".__LINE__."] template cache expired (path=$cachepath)") if $Tenjin::logger;
        return;
    }
    #: load template data from cache file.
    my $str = Tenjin::Util::read_file($cachepath);
    my @args = ();
    if ($str =~ s/\A\#\@ARGS (.*)\r?\n//) {
        #: get template args data from cached data.
        my $argstr = $1;
        $argstr =~ s/\A\s+|\s+\Z//g;
        @args = split(',', $argstr);
    }
    #: return script, template args, and mtime of cache file.
    my $script = $str;
    return {script=>$script, args=>\@args, timestamp=>$mtime};
}



##
## abstract class for key-value store
##
package Tenjin::KeyValueStore;


sub get {
    my ($this, $key, @options) = @_;
    die "get() is not implemented yet.";
}


sub set {
    my ($this, $key, $value, @options) = @_;
    die "set() is not implemented yet.";
}


sub del {
    my ($this, $key, @options) = @_;
    die "del() is not implemented yet.";
}


sub has {
    my ($this, $key, @options) = @_;
    die "has() is not implemented yet.";
}



##
## memory base key-value store
##
package Tenjin::MemoryBaseStore;
our $ISA = ('Tenjin::KeyValueStore');


sub new {
    my ($class) = @_;
    my $this = {
        values => {},
    };
    return bless($this, $class);
}


sub get {
    my ($this, $key) = @_;
    my $pair = $this->{values}->{$key};
    return unless $pair;
    my ($value, $timestamp) = @$pair;
    if ($timestamp && $timestamp < time()) {
        undef $this->{values}->{$key};
        return;
    }
    return $value;
}


sub set {
    my ($this, $key, $value, $lifetime) = @_;
    my $timestamp = $lifetime ? time() + $lifetime : 0;
    $this->{values}->{$key} = [$value, $timestamp];
    return 1;
}


sub del {
    my ($this, $key) = @_;
    undef $this->{values}->{$key};
    return 1;
}


sub has {
    my ($this, $key) = @_;
    return unless $this->{values}->{$key};
    return 1;
}



##
## file base key-value store
##
package Tenjin::FileBaseStore;
#use File::Basename;     # dirname
#use File::Path;         # mkpath, rmtree
our $ISA = ('Tenjin::KeyValueStore');
our $LIFE_TIME = 60*60*24*7;    # 1 week


my $_sub_dirname;
$_ = $^O;
#if ($_ eq 'linux' || $_ eq 'darwin' || m/bsd$/) {
if (0) {
    $_sub_dirname = sub {
        my ($fpath) = @_;
        $fpath =~ s/\/+$//;
        $fpath =~ m/(.*)[\/]/ ? $1 || '/' : '.';
    };
}
else {
    $_sub_dirname = sub {
        eval 'use File::Basename;' unless $File::Basename::VERSION; # lazy loading
        File::Basename::dirname($_[0]);
    }
}


sub new {
    my ($class, $root_path) = @_;
    unless ($root_path eq '0') {
        -d $root_path  or die "$root_path: not exist nor directory.";
    }
    my $this = {
        root_path => $root_path,
    };
    return bless($this, $class);
}


sub filepath {
    my ($this, $key) = @_;
    $this->{root_path} ne '0'  or die "root path is not set yet.";
    $_ = $key;
    s/[^-\/\w]/_/g;
    return $this->{root_path}.'/'.$_;
}


sub get {
    my ($this, $key) = @_;
    my $fpath = $this->filepath($key);
    return unless -f $fpath;
    if ((stat $fpath)[9] < time()) {
        #unlink($fpath);
        return;
    }
    return Tenjin::Util::read_file($fpath);
}


sub set {
    my ($this, $key, $value, $lifetime) = @_;
    $lifetime ||= $Tenjin::FileBaseStore::LIFE_TIME;
    my $fpath = $this->filepath($key);
    my $dir = $_sub_dirname->($fpath);
    unless (-d $dir) {
        eval 'use File::Path;' unless defined($File::Path::VERSION);   # lazy loading
        File::Path::mkpath($dir) unless -d $dir;
    }
    Tenjin::Util::write_file($fpath, $value, 't', time() + $lifetime);
}


sub del {
    my ($this, $key) = @_;
    my $fpath = $this->filepath($key);
    return unless -f $fpath;
    return unlink($fpath);
}


sub has {
    my ($this, $key) = @_;
    my $fpath = $this->filepath($key);
    return unless -f $fpath;
    if ((stat $fpath)[9] < time()) {
        #unlink($fpath);
        return;
    }
    return 1;
}



##
## helper class to find and read template files.
## if you want to store template files into database or other,
## define subclass of this and pass it's object to Engine.
##
## ex.
##    package DatabaseFinder;
##    sub find { ... }
##    sub timestamp { ... }
##    sub read { ... }   # should return content and mtime of file
##    #
##    package main;
##    my $engine = Tenjin::Engine->new({finder=>DatabaseFinder->new()});
##
package Tenjin::FileFinder;


sub new {
    my ($class) = @_;
    my $this = {};
    return bless($this, $class);
}


sub find {
    my ($this, $filename, $dirs) = @_;
    if ($dirs) {
        for my $dir (@$dirs) {
            my $filepath = Tenjin::Util::_path_join($dir, $filename);
            return $filepath if -f $filepath;
        }
    }
    else {
        return $filename if -f $filename;
    }
    return;
}


sub timestamp {
    my ($this, $filepath) = @_;
    return (stat $filepath)[9] if -f $filepath;
    return;
}


sub read {    # returns file content and file mtime
    my ($this, $filepath) = @_;
    if (-f $filepath) {
        my $mtime = (stat $filepath)[9];
        my $input = Tenjin::Util::read_file($filepath);
        my $mtime2 = (stat $filepath)[9];
        if ($mtime != $mtime2) {
            $mtime = $mtime2;
            my $input = Tenjin::Util::read_file($filepath);
            my $mtime2 = (stat $filepath)[9];
            if ($mtime != $mtime2) {
                warn("*** Tenjin::FileFinder->read(): timestamp changed while reading file (=$filepath).");
            }
        }
        return ($input, $mtime);
    }
    return;
}



##
## engine class which handles several template objects.
##
## ex.
##   use Tenjin strict=>1;    ## 'strict=>1' is optional
##   my $engine = new Tenjin::Engine({layout=>'layout.plhtml'});
##   my $context = { title=>'Example', items=>['A','B','C'], };
##   print $engine->render('example.plhtml', $context);
##
package Tenjin::Engine;
#use strict;


our $TIMESTAMP_INTERVAL = 1;
our $CACHE  = Tenjin::FileBaseTemplateCache->new();
our $STORE;   # default key-value store object for fragment cache
our $FINDER = Tenjin::FileFinder->new();


sub new {
    my ($class, $options) = @_;
    my $this = {};
    for my $key (qw[prefix postfix layout path cache store finder preprocess templateclass preprocessorclass]) {
        $this->{$key} = delete($options->{$key});
        #$this->{$key} = $options->{$key};
    }
    $this->{cache} = $Tenjin::Engine::CACHE if ! defined($this->{cache}) || $this->{cache} == 1;
    $this->{init_opts_for_template} = $options;
    $this->{_templates} = {};
    $this->{prefix} = '' if (! $this->{prefix});
    $this->{postfix} = '' if (! $this->{postfix});
    $this->{store} = $Tenjin::Engine::STORE unless $this->{store};
    $this->{finder} = $Tenjin::Engine::FINDER unless $this->{finder};
    return bless($this, $class);
}


sub register_template {
    my ($this, $template_name, $template) = @_;
    $this->{templates}->{$template_name} = $template;
}


sub cachename {
    #: return cache file path.
    my ($this, $filename) = @_;
    return $filename . '.cache';
}


sub to_filename {
    my ($this, $template_name) = @_;
    #: if template_name starts with ':', add prefix and postfix to it.
    #: if template_name doesn't start with ':', just return it.
    if (substr($template_name, 0, 1) eq ':') {
        return $this->{prefix} . substr($template_name, 1) . $this->{postfix};
    }
    return $template_name;
}


sub _timestamp_changed {
    my ($this, $template) = @_;
    #: if checked within a sec, skip timestamp check and return false.
    my $time = $template->{_last_checked_at};
    my $now = time();
    if ($time && $now - $time <= $Tenjin::Engine::TIMESTAMP_INTERVAL) {
        return;
    }
    #: if timestamp is same as file, return false.
    my $filepath = $template->{filename};
    if ($template->{timestamp} == $this->{finder}->timestamp($filepath)) {
        $template->{_last_checked_at} = $now;
        return;
    }
    #: if timestamp is changed, return true.
    else {
        $Tenjin::logger->info("[Tenjin.pm:".__LINE__."] template cache expired (path=$template->{filename})") if $Tenjin::logger;
        return 1;
    }
}


sub _get_template_in_memory {
    my ($this, $filename) = @_;
    #: if template object is not in memory cache then return undef.
    my $template = $this->{_templates}->{$filename};
    return unless $template;
    #: if timestamp is not set, don't check timestamp and return it.
    return $template unless $template->{timestamp};
    #: if timestamp of template file is not changed, return it.
    return $template unless $this->_timestamp_changed($template);
    #: if timestamp of template file is changed, clear it and return undef.
    delete($this->{_templates}->{$filename});
    return;
}


sub _get_template_in_cache {
    my ($this, $filepath, $cachepath) = @_;
    #: if template is not found in cache file, return nil.
    my $template = $this->{cache}->load($cachepath);
    return unless $template;
    #: if cache returns script and args then build a template object from them.
    if (ref($template) eq 'HASH') {
        my $hash = $template;
        $template = $this->_create_template();
        $template->{script}    = $hash->{script};
        $template->{args}      = $hash->{args};
        $template->{timestamp} = $hash->{timestamp};
        $template->{filename}  = $filepath;
    }
    #: if timestamp of template is changed then ignore it.
    return if $this->_timestamp_changed($template);
    #: if timestamp is not changed then return it.
    #$Tenjin::logger->trace("[Tenjin.pm:".__LINE__."] template '$filepath' found in cache.") if $Tenjin::logger;
    return $template;
}


sub _preprocess {
    my ($this, $input, $filepath, $_context) = @_;
    #: preprocess input with _context and return result.
    $_context = {} unless defined($_context);
    $this->hook_context($_context) unless $_context->{_engine};
    #$input = Tenjin::Preprocessor->new($filename)->render($_context);
    my $klass = $this->{preprocessorclass} || $Tenjin::PREPROCESSOR_CLASS;
    my $pp = $klass->new();
    #$pp->compile();   # DON'T COMPILE!
    $pp->convert($input);
    return $pp->render($_context);
}


sub _create_template {
    my ($this, $input, $filepath) = @_;
    #: create template object and return it.
    my $klass = $this->{templateclass} || $Tenjin::TEMPLATE_CLASS; # Tenjin::Template;
    my $template = $klass->new(undef, $this->{init_opts_for_template});
    #: if input is specified then convert it into script.
    $template->convert($input, $filepath) if $input;
    return $template;
}


sub get_template {
    my ($this, $template_name, $_context) = @_;
    #: accept template name such as :index.
    my $filename = $this->to_filename($template_name);
    #: if template object is in memory cache then return it.
    my $template = $this->_get_template_in_memory($filename);
    return $template if $template;
    #: if template file is not found then raise TemplateNotFoundError.
    my $filepath = $this->{finder}->find($filename, $this->{path});
    unless ($filepath) {
        my $path = $this->{path};
        my $s = $path ? ("['" . join("','", @$path) . "']") : '[]';
        die "$filename: template not found. (path=$s)";
    }
    #: if template is cached in file then store it into memory and return it.
    my $cachepath = $this->cachename($filepath);
    if ($this->{cache}) {
        $template = $this->_get_template_in_cache($filepath, $cachepath);
        if ($template) {
            $this->{_templates}->{$filename} = $template;
            $template->compile();
            return $template;
        }
    }
    #: get template content and timestamp
    my ($input, $timestamp) = $this->{finder}->read($filepath);
    if (!$input && !$timestamp) {
        die "$filepath: template not found.";
    }
    #: if preprocess is enabled then preprocess template file.
    $input = $this->_preprocess($input, $filepath, $_context) if $this->{preprocess};
    #: if template is not found in memory nor cache then create new one.
    $template = $this->_create_template($input, $filepath);
    $template->{filename} = $filepath;
    $template->{timestamp} = $timestamp;
    $template->{_last_checked_at} = time();
    #: save template object into file cache and memory cache.
    $this->{cache}->save($cachepath, $template) if $this->{cache};
    $this->{_templates}->{$filename} = $template;
    #: return template object.
    $template->compile();
    return $template;
}


sub render {
    my ($this, $template_name, $context, $layout) = @_;
    $context = {} unless defined $context;
    $layout = 1 unless defined $layout;
    $this->hook_context($context);
    my $output;
    while (1) {
        my $template = $this->get_template($template_name, $context); # pass $context only for preprocessing
        $output = $template->_render($context);
        ! $@  or die "*** ERROR: $template->{filename}\n", $@;
        $layout = $context->{_layout} if exists $context->{_layout};
        $layout = $this->{layout} if $layout == 1;
        last unless $layout;
        $template_name = $layout;
        $layout = undef;
        $context->{_content} = $output;
        delete $context->{_layout};
    }
    return $output;
}


sub hook_context {
    my ($this, $context) = @_;
    $context->{_engine} = $this;
    $context->{_store} = $this->{store};
}


sub _include {
    my ($this, $context, $template_name, $localvars) = @_;
    my $s;
    if ($localvars) {
        $context->{$_} = $localvars->{$_} for (keys %$localvars);
        $s = $this->render($template_name, $context, 0);
        undef $context->{$_} for (keys %$localvars);
    }
    else {
        $s = $this->render($template_name, $context, 0);
    }
    $s;
}



##
## engine class which uses SafeTemplate class
##
package Tenjin::SafeEngine;
our @ISA = ('Tenjin::Engine');


sub new {
    my ($class, $options) = @_;
    $options->{templateclass} ||= 'Tenjin::SafeTemplate';
    $options->{preprocessorclass} ||= 'Tenjin::SafePreprocessor';
    my $this = Tenjin::Engine->new($options);
    return bless($this, $class);
}



1;
