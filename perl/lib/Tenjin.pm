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

## $Rev$
## $Release: 0.0.0 $


package Tenjin;
#use strict;


our $USE_STRICT = 0;

our $TEMPLATE_CLASS = 'Tenjin::Template';

our $CONTEXT_CLASS = 'Tenjin::Context';



##
## utility package
##
package Tenjin::Util;


sub read_file {
    my ($filename, $lock_required) = @_;
    open(my $fh, $filename) or die("$filename: $!");
    binmode($fh);
    my $content = '';
    my $size = 8192;
    flock($fh, 1) if ($lock_required);
    read($fh, my $data, -s $filename);
    close($fh);
    return $data;
}


sub write_file {
    my ($filename, $content, $lock_required) = @_;
    open(my $fh, ">$filename") or die("$filename: $!");
    binmode($fh);
    flock($fh, 2) if $lock_required;
    print $fh $content;
    close($fh);
}


sub expand_tabs {
    my ($str, $tabwidth) = @_;
    $tabwidth = 8 unless defined($tabwidth);
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
## HTML Helper
##
package Tenjin::Helper::Html;


our %_escape_table = ( '&'=>'&amp;', '<'=>'&lt;', '>'=>'&gt;', '"'=>'&quot;', "'"=>'&#039;');


sub escape_xml {
    my ($s) = @_;
    #return HTML::Entities::encode_entities($s);
    $s =~ s/[&<>"]/$_escape_table{$&}/ge if ($s);
    return $s;
}


our %_unescape_table = ('lt'=>'<', 'gt'=>'>', 'amp'=>'&', 'quot'=>'"', '#039'=>"'");


sub unescape_xml {
    my ($s) = @_;
    $s =~ tr/+/ /;
    $s =~ s/&(lt|gt|amp|quot|#039);/$_unescape_table{$1}/ge if ($s);
    return $s;
}


sub encode_url {
    my ($s) = @_;
    $s =~ s/([^-A-Za-z0-9_.\/])/sprintf("%%%02X", ord($1))/sge;
    $s =~ tr/ /+/;
    return $s;
}


sub decode_url {
    my ($s) = @_;
    #$s =~ s/\%([a-fA-F0-9][a-fA-F0-9])/pack('H2', $1)/sge;
    $s =~ s/\%([a-fA-F0-9][a-fA-F0-9])/pack('C', hex($1))/sge;
    return $s;
}


sub checked {
    my ($expr) = @_;
    return $expr ? ' checked="checked"' : '';
}


sub selected {
    my ($expr) = @_;
    return $expr ? ' selected="selected"' : '';
}


sub disabled {
    my ($expr) = @_;
    return $expr ? ' disabled="disabled"' : '';
}


sub nl2br {
    my ($text) = @_;
    #$text = Tenjin::Helper::Html::escape_xml($text);
    $text =~ s/(\r?\n)/<br \/>$1/g;
    return $text;
}


sub text2html {
    my ($text) = @_;
    $text = Tenjin::Helper::Html::escape_xml($text);
    $text =~ s/(\r?\n)/<br \/>$1/g;
    return $text;
}


sub tagattr {   ## [experimental]
    my ($name, $expr, $value) = @_;
    return '' unless $expr;
    $value = $expr unless defined($value);
    return " $name=\"".escape_xml($value)."\"";
}


sub tagattrs {   ## [experimental]
    my (%attrs) = @_;
    my $s = "";
    while (my ($k, $v) = each %attrs) {
        $s .= " $k=\"".escape_xml($v)."\"" if defined($v);
    }
    return $s;
}


sub new_cycle {   ## [experimental]
    my @items = @_;
    my $len = @items;
    my $i = 0;
    return sub {
        return $items[$i++ % $len];
    };
}



##
## base colass of context object
##
package Tenjin::BaseContext;


sub new {
    my $class = shift;
    my ($this) = @_;
    $this = { } unless defined($this);
    return bless($this, $class);
}


## ex. {'x'=>10, 'y'=>20} ==> "my $x = $_context->{'x'}; my $y = $_context->{'y'}; "
sub _build_decl {
    my ($context) = @_;
    my $s = '';
    while (my ($k, ) = each %$context) {
        $s .= "my \$$k = \$_context->{'$k'}; " if $k ne '_context';
    }
    return $s;
}


$Tenjin::BaseContext::defun = <<'END';
sub evaluate {
    my ($_this, $_script, $_filename) = @_;
    my $_context = $_this;
    $_script = "# line 1 \"$_filename\"\n".$_script if $_filename;  # line directive
    return eval $_script unless $Tenjin::USE_STRICT;
    use strict;
    return eval $_script;
}


sub to_func {    # returns closure
    my ($_klass, $_script, $_filename) = @_;
    my $_s = $_filename ? "# line 1 \"$_filename\"\n" : '';  # line directive
    my $_s = "${_s}sub { my (\$_context) = \@_; $_script }";
    return eval($_s) unless $Tenjin::USE_STRICT;
    use strict;
    return eval($_s);
}
END

eval $Tenjin::BaseContext::defun;


sub escape {
    my ($arg) = @_;
    return $arg;
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

*_p = *Tenjin::Util::_p;

*_P = *Tenjin::Util::_P;

*escape     = *Tenjin::Helper::Html::escape_xml;

*escape_xml = *Tenjin::Helper::Html::escape_xml;

*encode_url = *Tenjin::Helper::Html::encode_url;

*checked    = *Tenjin::Helper::Html::checked;

*selected   = *Tenjin::Helper::Html::selected;

*disabled   = *Tenjin::Helper::Html::disabled;

*nl2br      = *Tenjin::Helper::Html::nl2br;

*text2html  = *Tenjin::Helper::Html::text2html;

*tagattr    = *Tenjin::Helper::Html::tagattr;

*new_cycle  = *Tenjin::Helper::Html::new_cycle;

*tagattrs   = *Tenjin::Helper::Html::tagattrs;



##
## template class
##
## ex.
##   ## convert file into perl script
##   use Tenjin;
##   $Tenjin::USE_STRICT = 1;  ## optional
##   my $template = new Tenjin::Template('example.plhtml');
##   print $template->{script};
##   ## or
##   my $template = new Tenjin::Template();
##   my $input = Tenjin::Util::read_file('example.plhtml');
##   print $template->convert($input, 'example.plhtml');   # filename is optional
##   ## evaluate converted perl script with context data
##   my $context = { 'title'=>'Example', 'items'=>['A','B','C'], };
##   #$template->compile();  ## optional
##   print $template->render($context);
##
package Tenjin::Template;


sub new {
    my $class = shift;
    my ($filename, $opts) = @_;
    my $escapefunc = defined($opts) && exists($opts->{escapefunc}) ? $opts->{escapefunc} : 'escape';
    my $this = {
        'filename'   => $filename,
        'script'     => undef,
        'escapefunc' => $escapefunc,
        'timestamp'  => undef,
        'args'       => undef,
    };
    #return bless($this, $class);
    $this = bless($this, $class);
    if ($filename) {
        $this->convert_file($filename);
    };
    return $this;
}


sub _render {
    my $this = shift;
    my ($context) = (@_);
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
        $script = Tenjin::BaseContext::_build_decl($context) . $script unless ($this->{args});
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
    my $this = shift;
    my ($filename) = @_;
    my $input = Tenjin::Util::read_file($filename, 1);
    my $script = $this->convert($input);
    $this->{filename} = $filename;
    #$this->{input}    = $input;
    return $script;
}


sub convert {
    my $this = shift;
    my ($input, $filename) = @_;
    $this->{filename} = $filename;
    my @buf = ('my $_buf = ""; ', );
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
    my $this = shift;
    my ($bufref, $input) = @_;
    my $pos = 0;
    my $pat = $this->stmt_pattern();
    while ($input =~ /$pat/g) {
        my ($pi, $lspace, $mspace, $stmt, $rspace) = ($1, $2, $3, $4, $5);
        my $start = $-[0];
        my $text = substr($input, $pos, $start - $pos);
        $pos = $start + length($pi);
        if ($text) {
            $this->parse_expr($bufref, $text);
        }
        $mspace = '' if $mspace eq ' ';
        $stmt = $this->hook_stmt($stmt);
        $this->add_stmt($bufref, $lspace . $mspace . $stmt . $rspace);
    }
    my $rest = $pos == 0 ? $input : substr($input, $pos);
    $this->parse_expr($bufref, $rest) if $rest;
}


sub hook_stmt {
    my $this = shift;
    my ($stmt) = @_;
    ## macro expantion
    if ($stmt =~ /\A(\s*)(\w+)\((.*?)\);?(\s*)\Z/) {
        my ($lspace, $funcname, $arg, $rspace) = ($1, $2, $3, $4);
        my $s = $this->expand_macro($funcname, $arg);
        if (defined($s)) {
            return $lspace . $s . $rspace;
        }
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
                $arg =~ m/\A[a-zA-Z_]\w*\Z/ or die("'$arg': invalid template argument.");
                push(@args, $arg);
                push(@declares, "my \$$arg = \$_context->{$arg}; ");
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
    my $this = shift;
    my ($funcname, $arg) = @_;
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
    my $this = shift;
    my ($m1, $m2, $m3) = @_;
    my ($not_escape, $expr, $delete_newline) = ($m1, $m2, $m3);
    return $expr, $not_escape eq '', $delete_newline eq '=',
}


sub parse_expr {
    my $this = shift;
    my ($bufref, $input) = @_;
    my $pos = 0;
    $this->start_text_part($bufref);
    my $pat = $this->expr_pattern();
    while ($input =~ /$pat/g) {
        my $start = $-[0];
        my $text = substr($input, $pos, $start - $pos);
        my ($expr, $flag_escape, $delete_newline) = $this->get_expr_and_escapeflag($1, $2, $3);
        $pos = $start + length($&);
        $this->add_text($bufref, $text) if ($text);
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
    my ($this) = shift;
    my ($bufref) = @_;
    $bufref->[0] .= ' $_buf .= ';
}


sub stop_text_part {
    my ($this) = shift;
    my ($bufref) = @_;
    $bufref->[0] .= "; ";
}


sub add_text {
    my $this = shift;
    my ($bufref, $text) = @_;
    return unless $text;
    $text =~ s/[`\\]/\\$&/g;
    if ($bufref->[0] =~ / \$_buf \.= \Z/) {
        $bufref->[0] .= "q`$text`";
    } else {
        $bufref->[0] .= " . q`$text`";
    }
}


sub add_stmt {
    my $this = shift;
    my ($bufref, $stmt) = @_;
    $bufref->[0] .= $stmt;
}


sub add_expr {
    my $this = shift;
    my ($bufref, $expr, $flag_escape) = @_;
    my $dot = $bufref->[0] =~ / \$_buf \.= \Z/ ? "" : " . ";
    $bufref->[0] .= $flag_escape ? "$dot$this->{escapefunc}($expr)"
                                 : "$dot($expr)";
}


sub defun {   ## (experimental)
    my $this = shift;
    my $funcname = shift;
    my @args = @_;
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
    my $this = shift;
    if ($this->{args}) {
        #my $f = $Tenjin::CONTEXT_CLASS . '::to_func';
        #my $func = $f->($this->{script});
        my $func = $Tenjin::CONTEXT_CLASS->to_func($this->{script}, $this->{filename});
        $@ and die("*** Error: " . $this->{filename} . "\n", $@);
        return $this->{func} = $func;
    }
    return;
}



##
## preprocessor
##
package Tenjin::Preprocessor;
our @ISA = ('Tenjin::Template');


my $STMT_PATTERN = Tenjin::Template::compile_stmt_pattern('PL');

sub stmt_pattern {
    my $this = shift;
    return $STMT_PATTERN;
}


my $EXPR_PATTERN = qr/\[\*=(=?)(.*?)(=?)=\*\]/s;

sub expr_pattern {
    my $this = shift;
    return $EXPR_PATTERN;
}


sub add_expr {
    my $this = shift;
    my ($bufref, $expr, $flag_escape) = @_;
    $expr = "Tenjin::Util::_decode_params($expr)";
    $this->SUPER::add_expr($bufref, $expr, $flag_escape);
}



##
## engine class which handles several template objects.
##
## ex.
##   use Tenjin;
##   $Tenjin::USE_STRICT = 1;  ## optional
##   my $engine = new Tenjin::Engine({'layout'=>'layout.plhtml'});
##   my $context = { 'title'=>'Example', 'items'=>['A','B','C'], };
##   print $engine->render('example.plhtml', $context);
##
package Tenjin::Engine;

sub new {
    my $class = shift;
    my ($options) = @_;
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


sub to_filename {
    my $this = shift;
    my ($template_name) = @_;
    if (substr($template_name, 0, 1) eq ':') {
        return $this->{prefix} . substr($template_name, 1) . $this->{postfix};
    }
    return $template_name;
}


sub find_template_file {
    my $this = shift;
    my ($filename) = @_;
    my $path = $this->{path};
    if ($path) {
        my $sep = $^O eq 'MSWin32' ? '\\\\' : '/';
        for my $dirname (@$path) {
            my $filepath = $dirname . $sep . $filename;
            return $filepath if (-f $filepath);
        }
    }
    else {
        return $filename if (-f $filename);
    }
    my $s = $path ? ("['" . join("','", @$path) . "']") : '[]';
    die "$filename: not found. (path=$s)";
}


sub register_template {
    my $this = shift;
    my ($template_name, $template) = @_;
    $this->{templates}->{$template_name} = $template;
}


sub get_template {
    my $this = shift;
    my ($template_name, $_context) = @_;
    my $template = $this->{templates}->{$template_name};
    my $t = $template;
    if (! $t || $t->{timestamp} && $t->{filename} && $t->{timestamp} < _mtime($t->{filename})) {
        my $filename = $this->to_filename($template_name);
        my $filepath = $this->find_template_file($filename);
        $template = $this->create_template($filepath, $_context);  # $_context is passed only for preprocessor
        $this->register_template($template_name, $template);
    }
    return $template;
}


sub read_template_file {
    my $this = shift;
    my ($template, $filename, $_context) = @_;
    my $input;
    if ($this->{preprocess}) {
        if (! defined($_context) || ! $_context->{_engine}) {
            $_context = {};
            $this->hook_context($context);
        }
        $input = (new Tenjin::Preprocessor($filename))->render($_context);
    } else {
        $input = Tenjin::Util::read_file($filename, 1);
    }
    return $input;
}


sub store_cachefile {
    my $this = shift;
    my ($cachename, $template) = @_;
    my $cache = $template->{script};
    if (defined($template->{args})) {
        my $args = $template->{args};
        $cache = "\#\@ARGS " . join(',', @$args) . "\n" . $cache;
    }
    Tenjin::Util::write_file($cachename, $cache, 1);
}


sub load_cachefile {
    my $this = shift;
    my ($cachename, $template) = @_;
    my $cache = Tenjin::Util::read_file($cachename, 1);
    if ($cache =~ s/\A\#\@ARGS (.*)\r?\n//) {
        my $argstr = $1;
        $argstr =~ s/\A\s+|\s+\Z//g;
        my @args = split(',', $argstr);
        $template->{args} = \@args;
    }
    $template->{script} = $cache;
}


sub cachename {
    my $this = shift;
    my ($filename) = @_;
    return $filename . '.cache';
}

sub create_template {
    my $this = shift;
    my ($filename, $_context) = @_;
    my $cachename = $this->cachename($filename);
    my $klass = $this->{templateclass} || $Tenjin::TEMPLATE_CLASS; # Tenjin::Template;
    my $template = $klass->new(undef, $this->{init_opts_for_template});
    $template->{timestamp} = time();
    if (! $this->{cache}) {
        #print STDERR "*** debug: caching is off.\n";
        my $input = $this->read_template_file($template, $filename, $_context);
        $template->convert($input, $filename);
    }
    elsif (!(-f $cachename) ||
           ((-f $filename) && _mtime($cachename) < _mtime($filename)) ) {
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


sub _mtime {
    my ($filename) = @_;
    return (stat($filename))[9];
}


sub _render {
    my $this = shift;
    my ($template_name, $context, $layout) = @_;
    $context = {} unless defined($context);
    $layout = 1 unless defined($layout);
    $this->hook_context($context);
    my $output;
    while (1) {
        my $template = $this->get_template($template_name, $context); # pass $context only for preprocessing
        $output = $template->_render($context);
        return $template->{filename} if ($@); # return template filename when error happened
        $layout = $context->{_layout} if exists($context->{_layout});
        $layout = $this->{layout} if $layout == 1;
        last unless $layout;
        $template_name = $layout;
        $layout = undef;
        $context->{_content} = $output;
        delete($context->{_layout});
    }
    return $output;
}


sub render {
    my $this = shift;
    my $ret = $this->_render(@_);
    if ($@) {  # error happened
        my $template_filename = $ret;
        die "*** ERROR: $template_filename\n", $@;
    }
    my $output = $ret;
    return $output;
}


sub hook_context {
    my $this = shift;
    my ($context) = @_;
    $context->{_engine} = $this;
}



1;
