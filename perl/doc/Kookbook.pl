use Kook::Utils qw(read_file write_file);

my $u       = 'users-guide';
my $tagfile = 'html-css';
my $dir     = 'data';
my @htmlfiles = qw(users-guide.html faq.html examples.html);
#my $common_docdir = '../../../rbtenjin/trunk/doc';
my $common_docdir = $ENV{HOME} . '/src/tenjin/common/doc';
my $lang    = 'perl';


#$kook_materials = [
#    "$common_docdir/users-guide.eruby",
#    "$common_docdir/faq.eruby",
#];


recipe "all", [ "doc", "test" ];

recipe "doc", [ @htmlfiles ];

recipe "*.html", [ '$(1).txt' ], {
    byprods => [ '$(1).toc.html' ],
    method => sub {
        my ($c) = @_;
        sys "kwaser -t $tagfile -T $c->{ingred} > $c->{byprod}";
        sys "kwaser -t $tagfile    $c->{ingred} > $c->{product}";
    }
};

recipe "*.txt", {
    #ingreds => [ if_exists('$(1).eruby') ],
    method => sub {
        my ($c) = @_;
        my $ingred = "$common_docdir/$c->{m}->[1].eruby";
        echo $ingred;
        return unless $ingred && -f $ingred;
        sys "erubis -E PercentLine -p '\\[% %\\]' -c '\@lang=%q|$lang|' $ingred > $c->{product}";
        #my $name = $c->m->[1];
        my $name = $c->{product};
        $name =~ s/\.txt$//;
        $name =~ s/-/_/g;
        my $testdir = '../test';
        -d $testdir  or die "testdir not found.";
        my $datadir = "$testdir/$dir/$name";
        rm_rf "$datadir/*" if -d $datadir;
        mkdir $datadir unless -d $datadir;
        sys "retrieve -Fd $datadir $c->{product}";
        #ln_s "$testdir}/$dir", "." unless -e $dir;
        for my $filename (glob "$datadir/*.result2") {
            my $content = read_file $filename;
            rm $filename;
            my @contents = split /^\$ /m, $content;
            my $i = 0;
            for my $content (@contents) {
                next unless $content;
                $i++;
                $content = '$ ' . $content;
                my $fname = $filename;
                $fname =~ s/\.result2$/$i.result/;
                write_file $fname, $content;
            }
        }
    }
};

#recipe '*.eruby', {
#    ingreds => [ if_exists("$common_docdir/\$(1).eruby") ],
#    method => sub {
#        cp $c->{ingred}, $c->{product} if -f $c->{ingred};
#    }
#};

recipe 'test', {
    #ingreds => [ 'test_users_guide', 'test_faq', 'test_examples' ],
    ingreds => [ 'users-guide.txt', 'faq.txt', 'examples.txt', '../test/test_docs.pl' ],
    method => sub {
        my $testdir = '../test';
        cd $testdir, sub {
            sys "perl test_docs.pl";
        };
    }
};

my $test_method = sub {
    my ($c) = @_;
    my $name = $c->{product};
    $name =~ s/test_//;
    cd "../test", sub {
        sys "perl test_docs.pl $name";
    };
};

recipe 'test_users_guide', {
    ingreds => [ 'users-guide.txt', '../test/test_docs.pl' ],
    method  => $test_method,
};

recipe 'test_faq', {
    ingreds => [ 'faq.txt', '../test/test_docs.pl' ],
    method  => $test_method,
};

recipe 'test_examples', {
    ingreds => [ 'examples.txt', '../test/test_docs.pl' ],
    method  => $test_method,
};

recipe 'clean', {
    method => sub {
        rm_rf '*.toc.html', 'users-guide.txt', 'faq.txt', 'data';
    }
};

recipe 'clear', [ 'clean' ], {
    method => sub {
        rm_rf @htmlfiles;
    }
};
