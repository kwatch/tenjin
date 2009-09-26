use Data::Dumper;
use File::Basename;
use Kook::Utils qw(write_file);
use Cwd;

my $project = prop('project', 'tenjin');
my $package = prop('package', 'Tenjin');
my $release = prop('release', '0.0.2');

my $copyright  = 'copyright(c) 2007-2009 kuwata-lab.com all rights reserved.';
my $license    = 'MIT License';
my @textfiles  = qw(MIT-LICENSE README Changes Kookbook.pl);
my @docfiles   = qw(doc/users-guide.html doc/faq.html doc/examples.html doc/docstyle.css);
my @binfiles   = qw(bin/pltenjin);
my @libfiles   = qw(lib/Tenjin.pm);
my @testfiles  = qw(t/*.t t/test_*.yaml t/Specofit.pm t/data/**/*);
my @benchfiles = qw(benchmark/Makefile benchmark/bench.pl benchmark/bench_context.pl benchmark/templates/* benchmark/MicroTemplate.pm.patch);
my @makefiles  = qw(MANIFEST.SKIP Makefile.PL);
my $common_path = getcwd();
$common_path =~ s/\/perl\.git.*/\/common.git\/common/g;

$kook_default = 'test';

recipe "test", [ "t/Specofit.pm" ], {
    desc   => "do test",
    method => sub {
        cd "t", sub {
            sys "prove *.t";
        };
    }
};

recipe "t/test_*.yaml", {
    ingreds => [ "$common_path/test/test_\$(1).yaml.eruby" ],
    method => sub {
        my ($c) = @_;
        sys "erubis -E PercentLine -p '%%%: :%%%' -c '\@lang=%q|perl|' $c->{ingred} > $c->{product}";
    }
};

$_ = getcwd();
$_ =~ /(.*?)\/tenjin\//;
my $specofit_path = $1.'/specofit/perl/lib/Specofit.pm';

recipe "t/Specofit.pm", [ $specofit_path ], {
    method => sub {
        my ($c) = @_;
        cp $c->{ingred}, $c->{product};
    }
};


recipe "package", [ "$package-$release.tar.gz" ];

recipe "$package-$release.tar.gz", [ "examples" ], {
    method => sub {
        my ($c) = @_;
        ## base name
        $c->{product} =~ /^(.*)\.tar\.gz$/;
        my $base = $1  or die;
        ## create temporary dir
        #my $dir = "dist/tmp";
        my $dir = "dist/$base";
        rm_rf "dist";
        mkdir_p $dir;
        ## copy files
        store @textfiles, @docfiles, @binfiles, @libfiles, @benchfiles, $dir;
        store @makefiles, $dir;
        store @testfiles, $dir;
        store "examples/**/*", $dir;
        rm_f "$dir/t/data/**/*.cache";
        rm_f "$dir/benchmark/templates/*.mt2";
        ## edit files
        edit "$dir/**/*", sub {
            s/\$Release\$/$release/g;
            s/\$Release:.*?\$/\$Release: $release \$/g;
            s/\$Copyright\$/$copyright/g;
            s/\$License\$/$license/g;
            $_;
        };
        ## chmod
        chmod 0755, "$dir/bin/*";
        ## create tar.gz file
        #cd "dist", sub { sys "tar czf $base.tar.gz $base" };
        ## create cpan package
        cd $dir, sub {
            sys "perl Makefile.PL";
            sys "make";
            sys "make manifest";
            sys "make dist";
        };
        mv "$dir/$base.tar.gz", ".";
        ## remove temporary dir
        rm_rf $dir;
        ## expand tar.gz
        cd "dist", sub {
            sys "tar xzf ../$base.tar.gz";
        };
    }
};

recipe "examples", {
    #ingreds => [ "doc/examples.txt" ],
    desc  => "create examples",
    method => sub {
        my ($c) = @_;
        ## get filenames
        my $ingred = 'doc/examples.txt';
        my $result = `retrieve -l $ingred`;
        #print STDERR "*** debug: result=", Dumper($result), "\n";
        ## get dirnames
        my %dirs;
        my @filenames = split "\n", $result;
        #print STDERR Dumper(\@filenames);
        for (@filenames) {
            my $d = dirname $_;
            $dirs{$d} = $d if $d;
        }
        my @dirs = keys %dirs;
        #print STDERR "*** debug: dirs=", Dumper(\@dirs), "\n";
        ## create directories
        my $base = "examples";
        -d $base ? rm_rf "$base/*" : mkdir $base;
        mkdir "$base/$_" for (@dirs);
        ## retrieve files
        sys "retrieve -d $base $ingred";
        rm_f "$base/**/*.result";
        ## create Makefile
        for (@dirs) {
            my $plfile;
            if    (-f "$base/$_/main.pl")  { $plfile = 'main.pl'; }
            elsif (-f "$base/$_/table.pl") { $plfile = 'table.pl'; }
            my $fname = "$base/$_/Makefile";
            my $s =
                "all:\n" .
                "\tpltenjin $plfile\n" .
                "\n" .
                "clear:\n" .
                "\trm -f *.cache\n";
            write_file($fname, $s);
        }
    }
};


recipe "profile", {
    desc   => "profiling with Devel::Profile",
    spices => [ "-v: view result (invoke 'less' command)" ],
    method => sub {
        my ($c, $opts, $rest) = @_;
        my $filename = $rest->[0] || "try.pl";
        rm "prof.out" if -f "prof.out";
        sys "perl -d:Profile $filename";
        sys "less prof.out" if $opts->{v};
    }
};

recipe "nytprof", {
    desc   => "profiling with Devel::NYTProf",
    spices => [ "-v: view result (open 'nytprof/index.html')" ],
    method => sub {
        my ($c, $opts, $rest) = @_;
        my $filename = $rest->[0] || "try.pl";
        rm_rf "nytprof*";
        sys "perl -d:NYTProf $filename";
        sys "nytprofhtml";
        sys "open nytprof/index.html" if $opts->{v};
    }
};


recipe "clean", {
    method => sub {
        rm_rf 'prof.out', 'nytprof*', 'dist';
        cd 'benchmark', sub { sys "make clean" };
        cd 'doc', sub { sys "plkook clean" };
    }
};
