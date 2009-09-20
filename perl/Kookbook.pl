use Data::Dumper;
use File::Basename;
use Kook::Utils qw(write_file);

my $project = prop('project', 'tenjin');
my $release = prop('release', '0.0.2');

my $copyright  = 'copyright(c) 2007-2009 kuwata-lab.com all rights reserved.';
my @textfiles  = qw(MIT-LICENSE README Changes Kookbook.pl);
my @docfiles   = qw(doc/users-guide.html doc/faq.html doc/examples.html doc/docstyle.css);
my @binfiles   = qw(bin/pltenjin);
my @libfiles   = qw(lib/Tenjin.pm);
my @testfiles  = qw(t/*.t t/test_*.yaml t/TestHelper.pm t/data/**/*);
my @benchfiles = qw(benchmark/Makefile benchmark/bench.pl benchmark/bench_context.pl benchmark/templates/*);

$kook_default = 'test';

recipe "package", [ "dist/$project-$release.tar.gz" ];

recipe "test", {
    desc   => "do test",
    method => sub {
        cd "t", sub {
            #sys "prove test_template.pl test_engine.pl test_helper_html.pl";
            sys "prove *.t";
        };
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


recipe "dist/$project-$release.tar.gz", [ "examples" ], {
    method => sub {
        -d "dist" ? rm_rf "dist/*" : mkdir "dist";
        my ($c) = @_;
        ## create directory
        $c->{product} =~ /^dist\/(.*)\.tar\.gz$/;
        my $base = $1  or die;
        my $dir = "dist/$base";
        -d $dir ? rm_rf "$dir/*" : mkdir $dir;
        ## copy files
        store @textfiles, @docfiles, @binfiles, @libfiles, @benchfiles, $dir;
        store @testfiles, $dir;
        store "examples/**/*", $dir;
        rm_f "$dir/t/data/**/*.cache";
        ## edit files
        edit "$dir/**/*", sub {
            s/\$Release\$/$release/eg;
            #s/\$Release: .*? \$/\$Release: $release \$/eg;
            #s/\$Copyright\$/$copyright/eg;
            $_;
        };
        ## chmod
        chmod 0755, "$dir/bin/*";
        ## create tar.gz file
        cd "dist", sub { sys "tar czf $base.tar.gz $base"; };
    }
};


recipe "clean", {
    method => sub {
        rm_rf 'prof.out', 'nytprof*';
        cd 'benchmark', sub { sys "make clean" };
        cd 'doc', sub { sys "plkook clean" };
    }
};
