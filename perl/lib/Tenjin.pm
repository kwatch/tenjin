##
## $Copyright$
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

sub import {
    my ($klass, %opts) = @_;
    $USE_STRICT = $opts{strict} if defined $opts{strict};
}

our %_H = ( '&'=>'&amp;', '<'=>'&lt;', '>'=>'&gt;', '"'=>'&quot;', "'"=>'&#039;' );


##
## utility package
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
    my ($filename, $content, $lock_required) = @_;
    my $fname = $filename;
    $fname .= rand() if $lock_required;
    open(my $fh, ">$fname")  or die "$filename: $!";
    binmode($fh);
    #flock($fh, 2) if $lock_required
    print $fh $content;
    close($fh);
    rename($fname, $filename) if $lock_required;
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
## raw string
##
package Tenjin::RawString;


sub new {
    #my ($class, $str) = @_;
    #return bless { str => $str }, $class;
    bless { str => $_[1] }, $_[0];
}


sub to_str {
    #my ($this) = @_;
    #return $this->{str};
    $_[0]->{str};
}



##
## HTML Helper
##
package Tenjin::Helper::Html;


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
## base colass of context object
##
package Tenjin::BaseContext;


sub new {
    my ($class, $this) = @_;
    $this = { } unless defined $this;
    return bless $this, $class;
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
END

eval $defun;


sub escape {
    #my $arg = $_[0];  return $arg;
    $_[0];      # returns as is
}


*_p = *Tenjin::Util::_p;
*_P = *Tenjin::Util::_P;



##
## common context object class which supports HTML helpers
##
package Tenjin::Context;
our @ISA = ('Tenjin::BaseContext');

our $defun = $Tenjin::BaseContext::defun;
eval $defun;

*_p           = *Tenjin::Util::_p;
*_P           = *Tenjin::Util::_P;
*escape       = *Tenjin::Helper::Html::escape_xml;
*escape_xml   = *Tenjin::Helper::Html::escape_xml;
*unescape_xml = *Tenjin::Helper::Html::unescape_xml;
*encode_url   = *Tenjin::Helper::Html::encode_url;
*decode_url   = *Tenjin::Helper::Html::decode_url;
*checked      = *Tenjin::Helper::Html::checked;
*selected     = *Tenjin::Helper::Html::selected;
*disabled     = *Tenjin::Helper::Html::disabled;
*nl2br        = *Tenjin::Helper::Html::nl2br;
*text2html    = *Tenjin::Helper::Html::text2html;
*tagattr      = *Tenjin::Helper::Html::tagattr;
*tagattrs     = *Tenjin::Helper::Html::tagattrs;
*new_cycle    = *Tenjin::Helper::Html::new_cycle;



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
    my $rawclass   = defined($opts) && exists($opts->{rawclass}) ? $opts->{rawclass} : undef;
    my $this = {
        'filename'   => $filename,
        'script'     => undef,
        'escapefunc' => $escapefunc,
        'rawclass'   => $rawclass,
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
    my @buf = ('my $_buf = ""; my $_V; ', );
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
        " \$_buf .= \$_context->{_engine}->render($arg, \$_context, 0);";
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


## ex. get_expr_and_escapeflag('=', '$item->{name}', '')  => 1, '$item->{name}', 0
sub get_expr_and_escapeflag {
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
        my ($expr, $flag_escape, $delete_newline) = $this->get_expr_and_escapeflag($1, $2, $3);
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
    if ($this->{escapefunu}) {
        return "$this->{escapefunc}($expr)";
    }
    if ($this->{rawclass}) {
        return "(ref(\$_V = ($expr)) eq '$this->{rawclass}' ? \$_V->{str} : (\$_V =~ s/[&<>\"]/\$Tenjin::_H{\$&}/ge, \$_V))";
    }
    #return "((\$_V = ($expr)) =~ s/[&<>\"]/\$ESCAPE_HTML{\$&}/ge, \$_V)";
    return "((\$_V = ($expr)) =~ s/[&<>\"]/\$Tenjin::_H{\$&}/ge, \$_V)";
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
    return;
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
## engine class which handles several template objects.
##
## ex.
##   use Tenjin strict=>1;    ## 'strict=>1' is optional
##   my $engine = new Tenjin::Engine({layout=>'layout.plhtml'});
##   my $context = { title=>'Example', items=>['A','B','C'], };
##   print $engine->render('example.plhtml', $context);
##
package Tenjin::Engine;


sub new {
    my ($class, $options) = @_;
    my $this = {};
    for my $key (qw[prefix postfix layout path cache preprocess templateclass]) {
        $this->{$key} = delete($options->{$key});
        #$this->{$key} = $options->{$key};
    }
    $this->{cache} = 1 unless defined($this->{cache});
    $this->{init_opts_for_template} = $options;
    $this->{templates} = {};
    $this->{prefix} = '' if (! $this->{prefix});
    $this->{postfix} = '' if (! $this->{postfix});
    return bless($this, $class);
}


sub _read_file {
    my $this = shift;
    return Tenjin::Util::read_file(@_);
}


sub _write_file {
    my $this = shift;
    return Tenjin::Util::write_file(@_);
}


sub to_filename {
    my ($this, $template_name) = @_;
    if (substr($template_name, 0, 1) eq ':') {
        return $this->{prefix} . substr($template_name, 1) . $this->{postfix};
    }
    return $template_name;
}


sub find_template_file {
    my ($this, $filename) = @_;
    my $path = $this->{path};
    if ($path) {
        my $sep = $^O eq 'MSWin32' ? '\\\\' : '/';
        for my $dirname (@$path) {
            my $filepath = $dirname . $sep . $filename;
            return $filepath if -f $filepath;
        }
    }
    else {
        return $filename if -f $filename;
    }
    my $s = $path ? ("['" . join("','", @$path) . "']") : '[]';
    die "$filename: not found. (path=$s)";
}


sub register_template {
    my ($this, $template_name, $template) = @_;
    $this->{templates}->{$template_name} = $template;
}


sub get_template {
    my ($this, $template_name, $_context) = @_;
    ## get cached template
    my $template = $this->{templates}->{$template_name};
    ## check whether template file is updated or not
    my $now = time();
    if ($template && $template->{timestamp} && $template->{filename}) {
        if ($now >= $template->{_last_checked_at} + 10) {
            $template->{_last_checked_at} = $now;
            $template = undef if $template->{timestamp} < (stat $template->{filename})[9];
        }
    }
    ## load and register template
    if (! $template) {
        my $filename = $this->to_filename($template_name);
        my $filepath = $this->find_template_file($filename);
        $template = $this->create_template($filepath, $_context);  # $_context is passed only for preprocessor
        $template->{_last_checked_at} = $now;
        $this->register_template($template_name, $template);
    }
    return $template;
}


sub read_template_file {
    my ($this, $template, $filename, $_context) = @_;
    my $input = $this->_read_file($filename);
    if ($this->{preprocess}) {
        if (! defined($_context) || ! $_context->{_engine}) {
            $_context = {};
            $this->hook_context($_context);
        }
        #$input = Tenjin::Preprocessor->new($filename)->render($_context);
        $input = $this->_read_file($filename);
        my $pp = $Tenjin::PREPROCESSOR_CLASS->new();
        #$pp->compile();   # DON'T COMPILE!
        $pp->convert($input);
        $input = $pp->render($_context);
    }
    return $input;
}


sub store_cachefile {
    my ($this, $cachename, $template) = @_;
    my $cache = $template->{script};
    if (defined($template->{args})) {
        my $args = $template->{args};
        $cache = "\#\@ARGS " . join(',', @$args) . "\n" . $cache;
    }
    $this->_write_file($cachename, $cache, 1);
}


sub load_cachefile {
    my ($this, $cachename, $template) = @_;
    my $cache = $this->_read_file($cachename);
    if ($cache =~ s/\A\#\@ARGS (.*)\r?\n//) {
        my $argstr = $1;
        $argstr =~ s/\A\s+|\s+\Z//g;
        my @args = split(',', $argstr);
        $template->{args} = \@args;
    }
    $template->{script} = $cache;
}


sub cachename {
    my ($this, $filename) = @_;
    return $filename . '.cache';
}


sub create_template {
    my ($this, $filename, $_context) = @_;
    my $cachename = $this->cachename($filename);
    my $klass = $this->{templateclass} || $Tenjin::TEMPLATE_CLASS; # Tenjin::Template;
    my $template = $klass->new(undef, $this->{init_opts_for_template});
    $template->{timestamp} = time();
    if (! $this->{cache}) {
        #print STDERR "*** debug: caching is off.\n";
        my $input = $this->read_template_file($template, $filename, $_context);
        $template->convert($input, $filename);
    }
    elsif (! -f $cachename || (stat $cachename)[9] < (stat $filename)[9]) {
        #print STDERR "*** debug: $cachename: cache file is not found or old.\n";
        my $input = $this->read_template_file($template, $filename, $_context);
        $template->convert($input, $filename);
        $this->store_cachefile($cachename, $template);
    }
    else {
        #print STDERR "*** debug: $cachename: cache file is found.\n";
        $template->{filename} = $filename;
        $this->load_cachefile($cachename, $template);
    }
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
}



1;
