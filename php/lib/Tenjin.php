<?php
//
// $Rev$
// $Release:$
// $Copyright$
//
// Permission is hereby granted, free of charge, to any person obtaining
// a copy of this software and associated documentation files (the
// "Software"), to deal in the Software without restriction, including
// without limitation the rights to use, copy, modify, merge, publish,
// distribute, sublicense, and/or sell copies of the Software, and to
// permit persons to whom the Software is furnished to do so, subject to
// the following conditions:
//
// The above copyright notice and this permission notice shall be
// included in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
// NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
// LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
// OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
// WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

/**
 *  Very fast and light-weight template engine based on include() and extract().
 *
 *  Syntax:
 *  - '<?php ... ?>' represents php statements.
 *  - '{=...=}' represents php expression with escaping HTML.
 *  - '{==...=}' represents php expression.
 *
 *  Features:
 *  - Layout template and nested template
 *  - Including other template files
 *  - Template caching
 *  - Capturing
 *
 *  See help of Tenjin_Template and Tenjin_Engine for details.
 */

error_reporting(E_ALL);
define('Tenjin_RELEASE', '$Release$');


/*
 *  utilities
 */

/** ex. '/show/'+_p('$item["id"]') => "/show/#{item['id']}" */
function _p($arg) {
    return "<`#$arg#`>";    // decoded into #{...} by preprocessor
}

/** ex. '<b>'._P('$item["id"]').'</b>' => '<b>{=$item["id"]=}</b>' */
function _ep($arg) {
    return "<`\$$arg\$`>";   // decoded into ${...} by preprocessor
}

/** decode <`#...#`> and <`$...$`> into #{...} and ${...} */
function _decode_params($s) {
    $s = preg_replace_callback('/%3C%60(?:%23(.+?)%23|%24(.+?)%24)%60%3E/im',
                               '_urldecode_params', $s);
    $s = preg_replace_callback('/&lt;`(?:\#(.+?)\#|\$(.+?)\$)`&gt;/',
                               '_entity_decode_params', $s);
    $s = preg_replace('/<`\#(.+?)\#`>/', '{==$1=}', $s);
    $s = preg_replace('/<`\$(.+?)\$`>/', '{=$1=}', $s);
    return $s;
}

function _urldecode_params($m) {
    if ($m[1])
        return '{==' . urldecode($m[1]) . '=}';     #  <#`...`#>
    else
        return '{=' .  urldecode($m[2]) . '=}';     #  <$`...`$>
}

function _entity_decode_params($m) {
    if ($m[1])
        return '{==' . html_entity_decode($m[1]) . '=}';     #  <#`...`#>
    else
        return '{='  . html_entity_decode($m[2]) . '=}';     #  <$`...`$>
}

function _array_get($array, $key, $default=null) {
    return array_key_exists($key, $array) ? $array[$key] : $default;
}

function Tenjin_read_file($filename, $lock=true) {
    $f = fopen($filename, 'rb') or die("$filename: cannot open to read.");
    if ($lock) flock($f, LOCK_SH) or die("$filename: cannot lock to read.");
    $s = fread($f, filesize($filename));
    //if ($lock) flock($f, LOCK_UN);
    fclose($f);
    return $s;
}

function Tenjin_write_file($filename, $content, $lock=true) {
    $f = fopen($filename, 'wb') or die("$filename: cannot open to write.");
    if ($lock) flock($f, LOCK_EX) or die("$filename: cannot lock to write.");
    fwrite($f, $content);
    //if ($lock) flock($f, LOCK_UN);
    fclose($f);
}

/** return ' checked="checked"' if expr is true. */
function checked($expr) {
    return $expr ? ' checked="checked"' : '';
}

/** return ' selected="selected"' if expr is true. */
function selected($expr) {
    return $expr ? ' selected="selected"' : '';
}

/** return ' disabled="disabled"' if expr is true. */
function disabled($expr) {
    return $expr ? ' disabled="disabled"' : '';
}

/** replace "\n" to "<br />\n" and return it. */
//function nl2br($text) {
//    return $text ? preg_replace('/\n/', "<br />\n") : '';
//}

/** (experimental) escape xml characters, replace "\n" to "<br />\n", and return it. */
function text2html($text) {
    return $text ? nl2br(preg_replace('/  /', ' &nbsp;')) : '';
}

/** return empty string when expr is false value, ' name="value"' when
 *  value is specified, or ' name="expr"' when value is null.
 *  ex.  tagattr('size', 20)  =>  ' size="20"'
 *       tagattr('size', 0)   =>  ''
 *       tagattr('checked', true, 'checked')  => ' checked="checked"'
 *       tagattr('checked', false, 'checked') => ''
 */
function tagattr($name, $expr, $value=null, $escape=true) {
    if (! $expr)
        return '';
    if ($value === null)
        $value = $expr;
    if ($escape)
        $value = htmlspecialchars($value);
    return " $name=\"$value\"";
}


/**
 *   Convert and evaluate embedded php string.
 *
 *   Notation:
 *   - '<?php ... ?>' means php statement code.
 *   - '{=...=}' means php escaped expression code.
 *   - '{==...=}' means php expression code.
 *
 *   ex. example.pyhtml
 *     <table>
 *     <?php $is_odd = false; ?>
 *     <?php foreach ($items as item) { ?>
 *       <?php $is_oddd = ! $is_odd; ?>
 *       <?php $color = $is_odd ? '#FFF' : '#FCF'; ?>
 *       <tr bgcolor="{==$color=}">
 *         <td>{=$item=}</td>
 *       </tr>
 *     <?php } ?>
 *     </table>
 *
 *   ex. main.php
 *     <?php
 *        $filename = 'example.phtml';
 *        require_once('tenjin.php');
 *        $template = new Tenjin_Template($filename);
 *        $script = $template->script;
 *        ### or
 *        #$template = new Tenjin_Template($filename);
 *        #$script = $template->convert_file($filename);
 *        ### or
 *        #$template = new Tenjin_Template();
 *        #$input = file_get_contents($filename);
 *        #$script = $template->convert($input, $filename)  # filename is optional
 *        echo $script;
 *        $context = array('items'=>array('<foo>','bar&bar','"baz"'));
 *        $output = $template->render($context);
 *        echo $output;
 *     ?>
 *
 *   ex. result
 *     <table>
 *      <tr bgcolor="#FFF">
 *       <td>&lt;foo&gt;</td>
 *      </tr>
 *      <tr bgcolor="#FCF">
 *       <td>bar&amp;bar</td>
 *      </tr>
 *      <tr bgcolor="#FFF">
 *       <td>&quot;baz&quot;</td>
 *      </tr>
 *     </table>
 */
class Tenjin_Template {

    /// default value of attributes
    var $filename   = null;
    var $escapefunc = 'htmlspecialchars';
    var $tostrfunc  = null;
    var $preamble   = null;    /// "_buf = []"
    var $postamble  = null;    /// "print ''.join(_buf)"
    var $args       = null;
    var $script     = null;
    var $pi         = 'php';
    var $timestamp  = null;

    /**
     *   constuctor of Template class
     *
     *   $filename:str (=null)
     *     Filename to convert (optional). If null, no convert.
     *   $properties:array (=null)
     *     optional args. the followings are available.
     *     - $escapefunc:str (='htmlescape')
     *     - preamble:str or bool (=null)
     *     - postamble:str or bool (=null)
     *     - pi:str (='php')
     */
    function Tenjin_Template($filename=null, $properties=null) {
        $this->filename = $filename;
        if ($properties) {
            foreach (array('escapefunc', 'preamble', 'postamble', 'pi') as $name) {
                if (array_key_exists($name, $properties)) {
                    $this->$name = $properties[$name];
                }
            }
        }
        if ($filename) {
            $this->convert_file($filename);
        }
    }

    function _reset($input=null, $filename=null) {
        $this->_spaces  = '';
        $this->script   = null;
        $this->bytecode = null;
        $this->input    = $input;
        $this->filename = $filename;
        if ($input !== null) {
            $i = strpos($input, "\n");
            if ($i === false)
                $this->newline = "\n";   # or null
            elseif (strlen($input) >= 2 && substr($input, $i-1, 1) == "\r")
                $this->newline = "\r\n";
            else
                $this->newline = "\n";
        }
    }

    function before_convert(&$buf) {
        if ($this->preamble) {
            array_push($buf, $this->preamble);
        }
    }

    function after_convert(&$buf) {
        if ($this->postamble) {
            //if (count($buf) > 0) {
            //    $s = $buf[count($buf)-1];
            //    if (substr($s, -1) == "\n") {
            //        array_push($buf, "\n");
            //    }
            //}
            array_push($buf, $this->postamble);
        }
    }

    /** Convert file into php script and return it.
        This is equivarent to convert(file_get_contents($filename), $filename). */
    function convert_file($filename) {
        $input = Tenjin_read_file($filename);
        return $this->convert($input, $filename);
    }

    /** Convert string in which php code is embedded into php script and return it. */
    function convert($input, $filename=null) {
        $this->_reset($input, $filename);
        $buf = array(); /// list
        $this->before_convert($buf);
        $this->parse_stmts($buf, $input);
        $this->after_convert($buf);
        $this->script = join('', $buf);
        return $this->script;
    }

    function stmt_pattern() {
        return '/(^[ \t]*)?<\?([-:\w]+)(\s.*?)\?\>([ \t]*\r?\n)?/m';
    }

    function parse_stmts(&$buf, $input) {
        if (! $input) return;
        $pat = $this->stmt_pattern();
        $pos = 0;
        while (preg_match($pat, $input, $m, PREG_OFFSET_CAPTURE, $pos)) {
            $start  = $m[0][1];
            $text   = substr($input, $pos, $start - $pos);
            $lspace = $m[1][0];
            $pi     = $m[2][0];
            $stmt   = $m[3][0];
            $rspace = @$m[4][0];
            $pos    = $start + strlen($m[0][0]);
            $this->parse_exprs($buf, $text);
            if ($pi != $this->pi) {
                //$s = preg_replace('/<\?/', '<<'.'?'.'php ?'.'>?', $m[0][0]);
                $s = $m[0][0];
                $this->parse_exprs($buf, $s);
                continue;
            }
            if ($lspace == '' && $pos != 0 && substr($text, -1) != "\n") {
                $lspace = null;
            }
            $bol_and_eol = $lspace !== null && $rspace;
            if ($bol_and_eol) {
                if ($lspace) $stmt = "$lspace$stmt";
            }
            $stmt = $this->statement_hook($stmt);
            $this->add_stmt($buf, $stmt, $rspace);
        }
        $rest = $pos == 0 ? $input : substr($input, $pos);
        if ($rest) {
            $this->parse_exprs($buf, $rest);
        }
        /// add "\n" if $buf is not ended by "\n"
        if (($n = count($buf)) > 0) {
            $s = $buf[$n-1];
            if (strlen($s) > 0 && substr($s, -1, 1) != "\n") {
                $buf[] = $this->newline;
            }
        }
    }

    /** expand macros and parse '#@ARGS' in a statement. */
    function statement_hook($stmt) {
        /// macro expantion
        if (preg_match('/^(\s*)(\w+)\((.*?)\);?(\s*)$/', $stmt, $m)) {
            $lspace = $m[1];
            $name   = $m[2];
            $arg    = $m[3];
            $rspace = $m[4];
            $handler = $this->get_macro_handler($name);
            return $handler ? $lspace . $this->$handler($arg) . $rspace : $stmt;
        }
        /// template arguments
        if ($this->args === null) {
            if (preg_match('/^ *\/\/@ARGS(?:[ \t]+(.*?))?$/', $stmt, $m)) {
                $this->args = array();  /// list
                $declares = array();    /// list
                $args = split(',', $m[1]);
                foreach ($args as $arg) {
                    $arg = trim($arg);
                    if (! $arg) continue;
                    if (! preg_match('/^[a-zA-Z_]\w*$/', $arg)) {
                        //throw new Exception("$arg: invalid template argument.");
                        die("$arg: invalid template argument.");
                    }
                    $this->args[] = $arg;
                    //$declares[] = " \$$arg = array_key_exists('$arg', \$_context) ? \$_context['$arg'] : null;";
                    $declares[] = " \$$arg = @\$_context['$arg'];";
                }
                return join('', $declares);
            }
        }
        ///
        return $stmt;
    }

    var $macro_handler_table = array(
        'echo'              => 'handle_echo_macro',
        'import'            => 'handle_import_macro',
        'start_capture'     => 'handle_start_capture_macro',
        'stop_capture'      => 'handle_stop_capture_macro',
        'start_placeholder' => 'handle_start_placeholder_macro',
        'stop_placeholder'  => 'handle_stop_placeholder_macro',
        );

    function get_macro_handler($name) {
        return @$this->macro_handler_table[$name];
    }

    function handle_echo_macro($arg) {
        return "echo $arg;";
    }

    function handle_import_macro($arg) {
        return "echo \$_context['_engine']->import($arg, \$_context);";
    }

    function handle_start_capture_macro($arg) {
        return "ob_start(); \$_capture_varname = $arg;";
    }

    function handle_stop_capture_macro($arg) {
        return "\$_context[\$_capture_varname] = ob_get_contents(); ob_end_clean();";
    }

    function handle_start_placeholder_macro($arg) {
        return "if (array_key_exists($arg, \$_context)) { echo \$_context[$arg]; } else {";
    }

    function handle_stop_placeholder_macro($arg) {
        return "}";
    }


    function expr_pattern() {
        return '/\{=(=)?(.*?)=\}/s';
    }

    function get_expr_and_escapeflag(&$match) {
        $expr       = $match[2][0];
        $escapeflag = ! $match[1][0];
        return array($expr, $escapeflag);
    }

    function parse_exprs(&$buf, $input) {
        if (! $input) return '';
        $this->start_text_part($buf);
        $rexp = $this->expr_pattern();
        $pos = 0;
        while (preg_match($rexp, $input, $m, PREG_OFFSET_CAPTURE, $pos)) {
            $start  = $m[0][1];
            $text   = substr($input, $pos, $start - $pos);
            $pos    = $start + strlen($m[0][0]);
            $pair   = $this->get_expr_and_escapeflag($m);
            $expr   = $pair[0];
            $flag_escape = $pair[1];
            $this->add_text($buf, $text);
            $this->add_expr($buf, $expr, $flag_escape);
        }
        $rest = $pos == 0 ? $input : substr($input, $pos);
        if ($rest) {
            $this->add_text($buf, $rest);
        }
        $this->stop_text_part($buf);
        //if (substr($input, -1) == "\n") {
        //    array_push($buf, $this->newline);
        //}
    }

    function start_text_part(&$buf) {
        array_push($buf, "echo ");
        //array_push($buf, "array_push(\$_buf, ");
    }

    function stop_text_part(&$buf) {
        //array_push($buf, "'');");
        $s = $buf[count($buf)-1];
        if (substr($s, -2) == ', ') {
            $buf[count($buf)-1] = substr($s, 0, strlen($s)-2);
            array_push($buf, ";");
        }
        else {
            array_push($buf, "'';");
        }
    }

    function add_text(&$buf, $text) {
        if (! $text) return;
        $text = preg_replace('/[\\\']/', '\\\\$0', $text);
        array_push($buf, "'", $text, "', ");
    }

    function add_expr(&$buf, $expr, $flag_escape) {
        if (! trim($expr)) return;
        if ($flag_escape) {
            array_push($buf, $this->escapefunc, '(', $expr, '), ');
        }
        else {
            array_push($buf, $expr, ', ');
        }
    }

    function add_stmt(&$buf, $stmt, $rspace) {
        array_push($buf, $stmt, $rspace);
    }

    /**
     *  evaluate php code with context data and return the result as string.
     *
     *  $context:array (=null)
     *    Context data to evaluate. If null then new dict is created.
     */
    function render(&$_context=null) {
        if ($this->args === null && $_context) {
            extract($_context);
        }
        ob_start();
        eval($this->script);
        $output = ob_get_contents();
        ob_end_clean();
        return $output;
    }

    function compile() {
        /// nothing
    }

}


/**
 *  template class #2
 */
class Tenjin_Template2 extends Tenjin_Template {

    function start_text_part(&$buf) {
        array_push($buf, "array_push(\$_buf, ");
    }

    function stop_text_part(&$buf) {
        //array_push($buf, "'');");
        $s = $buf[count($buf)-1];
        if (substr($s, -2) == ', ') {
            $buf[count($buf)-1] = substr($s, 0, strlen($s)-2);
            array_push($buf, ");");
        }
        else {
            array_push($buf, "'');");
        }
    }

    function render(&$_context=null) {
        if ($_context) {
            extract($_context);
        }
        $_buf = array();
        eval($this->script);
        return join('', $_buf);
    }

    function handle_echo_macro($arg) {
        return "array_push(\$_buf, $arg);";
    }

    function handle_import_macro($arg) {
        return "array_push(\$_buf, \$_context['_engine']->import($arg, \$_context));";
    }

    function handle_start_capture_macro($arg) {
        return "\$_buf_bkup = \$_buf; \$_buf = array(); \$_capture_varname = $arg;";
    }

    function handle_stop_capture_macro($arg) {
        return "\$_context[\$_capture_varname] = join('', \$_buf); \$buf = \$_buf_bkup;";
    }

    function handle_start_placeholder_macro($arg) {
        return "if (array_key_exists($arg, \$_context)) { array_push(\$_buf, \$_context[$arg]); } else {";
    }

    function handle_stop_placeholder_macro($arg) {
        return "}";
    }



}


/**
 *  preprocessor class
 */
class Tenjin_Preprocessor extends Tenjin_Template {

    function Tenjin_Preprocessor($filename=null, $properties=null) {
        parent::Tenjin_Template(null, $properties);
        $this->pi = 'PHP';
        if ($filename) {
            $this->convert_file($filename);
        }
    }

    function expr_pattern() {
        return '/\{\*=(=)?(.*?)=\*\}/s';
    }

    //function get_expr_and_escapeflag($match) {
    //    return array($match[2], $match[1] != '=');
    //}

    function add_expr(&$buf, $expr, $flag_escape=null) {
        if (! trim($expr)) return;
        $expr = "_decode_params($expr)";
        parent::add_expr($buf, $expr, $flag_escape);
    }

}


/**
 *  template engine class
 *
 *  ex.
 *      $properties = array('prefix'=>'user_', 'postfix'=>'.phtml',
 *                          'layout'=>'layout.phtml', 'path'=>array('.', 'templates'));
 *      $engine = new Tenjin_Engine($properties);
 *      $context = array('title'=>'Create User', 'user'=>$user);
 *      $output = $engine->render(':create', $context);
 *      echo $output;
 */

class Tenjin_Engine {

    /// default value of attributes
    var $prefix     = null;
    var $postfix    = null;
    var $layout     = null;
    var $templateclass = 'Tenjin_Template';
    var $path       = null;
    var $cache      = true;
    var $preprocess = false;
    var $properties = null;
    var $templates  = array();


    /** constructor of Engine class.
     *
     *  prefix:str (='')
     *    Prefix string used to convert template short name to template filename.
     *  postfix:str (='')
     *    Postfix string used to convert template short name to template filename.
     *  layout:str (=null)
     *    Default layout template name.
     *  path:array of str(=null)
     *    List of directory names which contain template files.
     *  cache:bool (=True)
     *    Cache converted php code into file.
     *  preprocess:bool(=False)
     *    Activate preprocessing or not.
     *  templateclass:class (=Template)
     *    Template class which engine creates automatically.
     *
     *  The other properties are passed to Template's constructor.
     *  See document of Template class' constructor for details.
     */
    function Tenjin_Engine(&$properties=null) {
        if ($properties) {
            $names = array('prefix', 'postfix', 'layout', 'templateclass',
                           'path', 'cache', 'preprocess');
            foreach ($names as $name) {
                if (array_key_exists($name, $properties)) {
                    $this->$name = $properties[$name];
                }
            }
            $this->properties = $properties;
        }
        if ($this->prefix === false) { $this->prefix = null; }
        if ($this->postfix === false) { $this->postfix = null; }
    }


    /**
     *  Convert template short name to filename.
     *
     *  ex.
     *    >>> engine = tenjin.Engine(prefix='user_', postfix='.pyhtml')
     *    >>> engine.to_filename('list')
     *    'list'
     *    >>> engine.to_filename(':list')
     *    'user_list.pyhtml'
     */
    function to_filename($template_name) {
        if (substr($template_name, 0, 1) == ':' ) {
            $s = substr($template_name, 1);
            return "$this->prefix$s$this->postfix";
        }
        return $template_name;
    }

    /** Find template file and return it's filename.
     *  When template file is not found, IOError is raised. */
    function find_template_file($template_name) {
        $filename = $this->to_filename($template_name);
        if ($this->path) {
            foreach ($this->path as $dirname) {
                $filepath = $dirname . DIRECTORY_SEPARATOR . $filename;
                if (is_file($filepath)) return $filepath;
            }
        }
        else {
            if (is_file($filename)) return $filename;
        }
        $s = $this->path === null ? 'null' : '[' . join(',',$this->path) . ']';
        //throw new Exception("$filename: file not found (path=$s).");
        die("$filename: file not found (path=$s).");
    }

    /** Register an template object. */
    function register_template($template_name, $template) {
        $this->templates[$template_name] = $template;
    }

    /** load marshaled cache file */
    function load_cachefile($cache_filename, $template) {
        $cache = Tenjin_read_file($cache_filename);
        if (! preg_match('/^<\?php (\/\* \/\/@ARGS (.*?) \*\/)?/', $cache, $m)) {
            die("*** invalid cache format.");
        }
        $start_pos = strlen($m[0]);
        $template->args = isset($m[1]) ? split(', ', $m[2]) : null;
        if (! preg_match('/ ?\?>\r?\n?/', $cache, $m)) {
            die("*** invalid cache format.");
        }
        $len = strlen($cache) - $start_pos - strlen($m[0]);
        $template->script = substr($cache, $start_pos, $len);
        //$template->compile();
    }

    /** store template into marshal file */
    function store_cachefile($cache_filename, $template) {
        $buf = array('<?php ');
        if ($template->args !== null) {
            $buf[] = '/* //@ARGS ';
            $buf[] = join(', ', $template->args);
            $buf[] = ' */';
        }
        $buf[] = $template->script;
        $buf[] = " ?>";
        $buf[] = $template->newline;
        Tenjin_write_file($cache_filename, join('', $buf));
    }

    function cachename($filename) {
        return $filename . '.cache';
    }

    /** Read template file and create template object. */
    function create_template($filename, $_context) {
        $klass = $this->templateclass;
        $template = new $klass(null, $this->properties);
        $template->timestamp = time();  /// or microtime();
        $cache_filename = $this->cachename($filename);
        if (! $this->cache) {
            $input = $this->read_template_file($filename, $_context);
            $template->convert($input, $filename);
            //$template->compile();
        }
        elseif (is_file($cache_filename) and filemtime($cache_filename) >= filemtime($filename)) {
            //$logger->debug("** $filename: cache found.");
            $template->filename = $filename;
            $this->load_cachefile($cache_filename, $template);
            $template->compile();
        }
        else {
            //$logger->debug("** $filename: cache not found.");
            $input = $this->read_template_file($filename, $_context);
            $template->convert($input, $filename);
            $template->compile();
            $this->store_cachefile($cache_filename, $template);
        }
        return $template;
    }

    function read_template_file($filename, $_context=null) {
        if (! $this->preprocess)
            return Tenjin_read_file($filename);
        if ($_context === null)
            $_context = array();   /// hash table
        if (! array_key_exists('_engine', $_context))
            $_context = $this->hook_context($_context);
        $preprocessor = new Tenjin_Preprocessor($filename);
        //$s = $preprocessor->render($_context);
        if ($this->cache) {
            $this->store_cachefile($this->cachename($filename), $preprocessor);
        }
        $s = $this->render_template($preprocessor, $_context, $preprocessor->args===null);
        return $s;
    }

    /** Return template object.
     *  If (template object has not registered, template engine creates
     *  and registers template object automatically.
     */
    function get_template($template_name, $_context=null) {
        $template = @$this->templates[$template_name];
        $t = $template;
        if ($t === null || $t->timestamp && $t->filename && $t->timestamp < filemtime($t->filename)) {
            $filename = $this->find_template_file($template_name);
            /// context data is passed only for preprocessing
            $template = $this->create_template($filename, $_context);
            $this->register_template($template_name, $template);
        }
        return $template;
    }

    /** Evaluate template using current local variables as context. */
    function import($template_name, $_context) {
        # context data is passed to get_template() only for preprocessing.
        $template = $this->get_template($template_name, $_context);
        //return $template->render($_context);
        return $this->render_template($template, $_context);
    }

    /** Evaluate template with layout file and return result of evaluation.
     *
     *  template_name:str
     *    $filename (ex. 'user_list.pyhtml') or short name (ex. ':list') of template.
     *  context:array (=null)
     *    Context object to evaluate. If null then new array is used.
     *  layout:str or bool(=true)
     *    If true, the default layout name specified in constructor is used.
     *    If false, no layout template is used.
     *    If str, it is regarded as layout template name.
     *
     *  If temlate object related with the 'template_name' argument is not exist,
     *  engine generates a template object and register it automatically.
     */
    function render($template_name, &$context=null, $layout=true) {
        if ($context === null)
            $context = array();  /// hash table
        $context = $this->hook_context($context);
        while (true) {
            /// context data is passed to get_template() only for preprocessing
            $template = $this->get_template($template_name, $context);
            $content  = $this->render_template($template, $context);
            if (array_key_exists('_layout', $context)) {
                $layout = $context['_layout'];
                unset($context['_layout']);
            }
            if ($layout === true || $layout === null) {
                $layout = $this->layout;
            }
            if (! $layout) break;
            $template_name = $layout;
            $layout = false;
            $context['_content'] = $content;
        }
        if (array_key_exists('_content', $context)) {
            unset($context['_content']);
        }
        return $content;
    }

    function render_template($template, &$context) {
        if ($this->cache && $template->filename) {
            $cache_filename = $this->cachename($template->filename);
            return Tenjin_include_file($cache_filename, $context, $template->args === null);
        }
        else {
            return $template->render($context);
        }
    }

    function hook_context(&$context) {
        if ($context === null) {
            $context = array();
        }
        $context['_engine'] = $this;
        return $context;
    }
}

function Tenjin_include_file($_filename, &$_context, $_flag_extract=true) {
    if ($_context && $_flag_extract) extract($_context);
    ob_start();
    include($_filename);
    $_output = ob_get_contents();
    ob_end_clean();
    return $_output;
}

?>
