#!/usr/bin/perl


=pod

=head1 Title

B<list_xmatter.pl>

=head1 Version

0.6

=head1 Description

B<list_xmatter.pl> takes one or more Bloom book files and returns a tab-separated text file containing a table of all the front matter ('xmatter') field contents. Rows are collection name, file name, and field name, columns are language tags. This is useful in diagnosing the changes that need to be made to a Bloom collection that was incorrectly set up for language tags, or where the user has entered data into the wrong front matter fields.

=head1 Usage

 $ list_xmatter.pl --output path/to/outfile.csv [--help] path/to/bloomCollection/folder

=head2 Required arguments

=over

=item C<-o, --output>

specifies a CSV file where the results will be written.

=back

=head2 Optional arguments

=over

=item C<-h, --help>

displays a brief usage message and exits

=back

=head1 Required modules

B<list_xmatter.pl> relies on the following non-core Perl modules:

=over

=item L<Encode|https://metacpan.org/pod/Encode>

=item L<HTML::Element|https://metacpan.org/pod/HTML::Element>

=item L<HTML::Entities|https://metacpan.org/pod/HTML::Entities>

=item L<HTML::TreeBuilder|https://metacpan.org/pod/HTML::TreeBuilder>

=item L<HTML::TreeBuilder::XPath|https://metacpan.org/pod/HTML::TreeBuilder::XPath>

=item L<IO:HTML|https://metacpan.org/pod/IO::HTML>

=item L<String::ShellQuote|https://metacpan.org/pod/String::ShellQuote>

=item L<Text::CSV|https://metacpan.org/pod/Text::CSV>

=back

=head1 See also

clean_xmatter.pl

=head1 Author

Fraser Bennett,
L<fraser_bennett@sil-lead.org|mailto:fraser_bennett@sil-lead.org>

=head1 Bugs

Please report any bugs or feature requests to
L<fraser_bennett@sil-lead.org|mailto:fraser_bennett@sil-lead.org>.

=head1 Copyright and License

list_xmatter.pl Copyright 2020 L<SIL LEAD, Inc.|https://www.sil-lead.org>
L<CC-BY 4.0 International|https://creativecommons.org/licenses/by/4.0/>

=head1 Acknolwedgements

B<list_xmatter.pl> was created for the USAID/Afghan Children Read project.

=cut

use Encode qw(encode decode);
use Getopt::Long;
use IO::HTML;
use HTML::Element 5 -weak; use HTML::Entities; use HTML::TreeBuilder;
use String::ShellQuote;
use Text::CSV qw(csv);
# use utf8;

GetOptions ('h|help' => \$help,
  'o|output=s' => \$opt_o);
if ($help or !$opt_o) {
  print "Usage: \n";
  print "  list_xmatter.pl --output sourcdir\n";
  print "For more details, use perldoc list_xmatter.pl\n";
  exit;
}

# the hash we'll use to collect all the data-book attributes
my %data;
# the hash we'll use to keep track of all languages referenced
my %lgs;
# we need the following to get around the limitation on hyphens in hash keys
my $db = "data-book";

my $sourcedir = shift @ARGV;
$sourcedir = shell_quote($sourcedir);

## collection-level operations: ##
# look for bloomCollections
my @bloom_collections = `find $sourcedir -name '*.bloomCollection'`;
foreach $bloom_collection (@bloom_collections) {
  chomp $bloom_collection;
  my @bloom_collection = split "/", $bloom_collection;
  my $collection_name = pop @bloom_collection;
  # @collectionPath now ends with the enclosing folder
  $collection_folder = decode('utf8', @bloom_collection[$#bloom_collection]);

  ## book-level operations ##
  # look for book files in the folders containing the .bloomCollection files
  my $collection_path = shell_quote(join("/", @bloom_collection));
  my @htm_files= `find $collection_path -name '*.htm'`;

  foreach (@htm_files) {
    chomp;
    my @path = split "/";
    my $book_title = pop @path;
    $book_title = decode ("utf8", $book_title);

    # read in each file in turn, parse a tree from it
    open ($fh, "<:utf8", $_) || die "Can't open file $_";
    my $tree = HTML::TreeBuilder->new();
    $tree->parse_file($fh);
    close $fh;

    # find the bloomDataDiv <div> element
    my $root = $tree->look_down('id', 'bloomDataDiv');

    if ($root) {
      my @divs = $root->look_down(_tag => "div", 'data-book' => qr/.+/);
      foreach my $div (@divs) {
        my %attr = $div->all_external_attr();
        my ($lg, $dbtype) = ($attr{lang}, $attr{'data-book'});
        # add the content to the %data hash
        $data{$collection_folder}{$book_title}{$dbtype}{$lg} = \$div->content_list();
        # add the $lg to the list of %lgs if needed
        unless ($lgs{$lg}) {
          $lgs{$lg} = 1;
        }
      }
    }
    print "parsed $_\n";
  }
  print "All html files parsed\n";
}



# this is the array of arrays we'll use to hold the output
my @aoa;
# compose the header
my @header = ("Bloom Collection", "Book title", "data-book");
foreach (sort keys %lgs) {
  push @header, $_;
}
# push the header into $aoa
push @aoa, \@header;

# cycle through each bookset
for my $bkset (sort keys %data) {
  # cycle through each book title
  for my $book_title (sort keys %{$data{$collection_folder}}) {
    # cycle through the data-book types
    for $dbtype (sort keys %{$data{$collection_folder}{$book_title}} ) {
      my @line = ($collection_folder, $book_title, $dbtype);
      # cycle through the languages
      for $lg (sort keys %lgs) {
        my $content = "";
        my $r = ${$data{$collection_folder}{$book_title}{$dbtype}{$lg}};
        if (ref $r eq 'HTML::Element') {
          $content = $r->as_HTML('', '', {});
        }
        $content = decode_entities($content);
        $content =~ s/\x{FEFF}//g;
        push @line, $content;
      }
      push @aoa, \@line;
    }
  }
}

# write the array of arrays @aoa to a $infile
my $csv = Text::CSV->new({binary => 1, auto_diag => 1});
open ($outfile, ">:utf8", $opt_o) or die "$opt_o: $!";
$csv->say ($outfile, $_) for @aoa;
close $outfile or die "$opt_o: $!";
