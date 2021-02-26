#!/usr/bin/perl

=pod

=head1 Title

B<clean_xmatter.pl>

=head1 Version

0.6

=head1 Description

B<clean_xmatter.pl> takes a collection of Bloom books and "cleans" various bits
of the book metadata ("xmatter"), credits page, and page data in the HTML source
file of each Bloom book. This is needed when a user has created a set of books
using incorrect language settings or has placed front-matter metadata in the
wrong front matter fields.

B<clean_xmatter.pl> applies the same set of changes to all books in a collectio,
but it can operate on more than one set of Bloom collections at
once. You can specifiy changes to be made across-the-board to multiplie
collections, or restrict a set of changes to a specific collection.

=head1 Usage

 $ clean_xmatter.pl --changes path/to/changedefs.xml [--test] path/to/bloomCollection/folder

 B<Warning:> Results are written in-place. Original data is
overwritten. You are highly encouraged to run the script on a copy of the
originals!

=head2 Required arguments

=over

=item C<--changes>

specifies an xml file that specifies the changes to be made to the Bloom book
files. See L</"changes file format"> below for details.

=item C<--sourcedir>

specifies the path to the directory that contains the Bloom books to be processed.
The directory B<must> contain a C<.bloomCollection> file. (The script doesn't
do anything to or with the C<.bloomCollection> file -- it's just a convenient
way to recognize a folder of Bloom books. This allows the script to deal with
nested Bloom book folders.)

=back

=head2 Optional arguments

=over

=item C<--test>
suppresses the output of the script -- useful for debugging.

=back

=head1 Changes XML format

B<Warning:> You should be familiar with the internal structure of Bloom HTML
book files before writing your own change specifications.>

The XML file containing the changes to be worked on the Bloom book files must
have the following structure:

 <?xml version='1.0'?>
 <collections>
   <allCollections>
     <delete>
       <target>I<XPath_expression></target>
     </delete>
   </allCollections>

   <collection name="I<folder name>" l1="I<ISO639_code" l2="ISO639_code>">
     <merge>
       <target>I<XPath_expresssion></target>
       <target>I<XPath_expresssion></target>
     </merge>

     <delete>
       <target>I<XPath_expresssion></target>
     </delete>

     <change>
       <target>I<XPath_expression></target>
       <to data-book="I<XMatter_field_name>" lang="I<ISO639_code>" />
     </change>

     <change>
       <target>I<XPath_expresssion></target>
       <to lang="I<ISO639_code>"/>
     </change>
   </collection>
 </collections>

 C<merge>, C<delete>, and C<change> elements can appear in either
 C<allCollections> or C<collection> elements, in any order.

 The first C<target> child element of a C<merge> element is the element
 that is kept; the other child elements are merged into the first.

=over

=item C<< <collections> >>

C<< <collections> >> is the root of the XML file, but it really just
serves as a wrapper for what is beneath. You should never have to refer to it.

=item C<< <allCollections> >>

C<< <allCollections> >> contains a set of changes that will be applied to
all collections. These will mostly be C<< <delete> >>.

=item C<< <collection name="I<folder_name>" l1="I<aaa>" l2="I<aaa>" [l3="I<aaa>"]> >>

 C<< <collection name="myBloomBooks" l1="dag" l2="en"> >>

C<< <collection> >> contains a list of changes to be applied to a single
Bloom collection, as a series of C<< <change> >> and C<< <delete> >>
elements. C<< <change> >> and C<< <delete> >> may appear in any order.
C<< <change> >> and C<< <delete> >> are applied in the order in which
they appear.

C<< <collection> >> has three required attributes:

=over 2

=item C<name="collection_name">

C<name> specifies the name (i.e., the filename) of the folder/directory  that
contains the Bloom collection. (Note: this is usually (but not always) the same
as the filename (less the C<.bloomCollection> extension) of the
C<.bloomCollection> file that also resides in the folder -- here, we want the
folder name.

=item C<l1="ISO539_code">

Bloom allows for up to three languages to be specified for each book.
B<clean_xmatter.pl> assumes that at least two languages will be specified.

C<l1> specifies the ISO639 code that will be written to the output file in the
C<data-l1> attribute on the HTML C<< <body> >> element. This is the
"vernacular" language, the main language of the book. The code used may be a
two-letter L<ISO639-2|https://www.loc.gov/standards/iso639-2/> or a
three-letter L<ISO639-3|https://iso639-3.sil.org/code_tables/639/data> code.

=item C<l2="ISO539_code">

C<l2> specifies the L<ISO639|https://en.wikipedia.org/wiki/ISO_639>
code that will be written to the output file in the
C<data-l2> attribute on the HTML C<< <body> >> element. This is the
main language of many front-matter metadata elements, such as copyright and
licensing information, and is usually a national language. C<l2> may be the
same as C<l1>.

=item C<l1="ISO539_code"> (optional)

C<l3> specifies the ISO639 code that will be written to the output file in the
C<data-l3> attribute on the HTML C<< <body> >> element. C<data-l3> specifies
a regional or international langugae.

=back

=item C<< <delete> >>

C<< <delete> >> is a convenience wrapper for a C<< <target> >> element.

=item C<< <target> >>

The content of C<< <target> >> is an XPath expression that specifies
an HTML element that should be removed from the Bloom book. The XPath
expression should pick out an element, not an attribute or text content.


For instance, the
following will remove existing copyright metadata element from a Bloom book
(presumably to be replaced by a corrected copyright element).

  <target>//div[@id="bloomDataDiv"]/div[@data-book="copyright"]</target>

Because the XPath search routines are based on
L<XML::XPathEngine|https://metacpan.org/pod/XML::XPathEngine>, you can
use a regular expresssion in the XPath expression:

  <target>//div[@class=~/\bcredits\b/]//div[@data-derived="copyright"]</target>

=item C<< <change> >>

A C<< <change> >> element has two children: a C<< <target> >> element
that specifies the set of elements to be acted on, and a C<< <to> >>
element that specifies the alterations to be made.

=item C<< <to> >>

C<< <to> >> specifies the changes to make in an element that is picked out
by a sibling C<< <target> >> XPath expression. Only attribute values may be
changed: B<clean_xmatter.pl> will not change the tag name of an attribute. The
attributes of C<< <to> >> and their values specifiy the attributes of the
targeted elements that will be changed and their new values.

Typically, this involves a C<data-book> attribute (which specifies a
front-matter metadata field) and a C<lang> attribute, which specifies the
language of that field's contents.

For instance:

  <change>
    <target>//div[@id="bloomDataDiv"]/div[@data-book="bookTitle" and @lang="en"]</target>
    <to data-book="levelInformation" lang="pbt" />
  </change>

The C<< <target> >> XPath expresseion will seek out C<< <div> >>
elements that are children of the
C<< <div id="bloomDataDiv"> >> element, and that contain the content of the
C<bookTitle> front matter field I<and> are tagged as being in English (C<"en">).
clean_xmatter.pl will change all such elements so that their content
is instead tagged as belonging to the front matter C<levelInformation> field,
and as being in the Southern Pashto language (C<"pbt">).

You can change the C<"lang"> attributes of all the I<other>
C<< <div id="bloomDataDiv">/<div> >> elements by placing the
following general C<< <change> >> element I<after> the more specific
C<< <change> >> elements:

  <change>
    <target>//div[@id="bloomDataDiv"]/div</target>
    <to lang="I<new_language_code>" />
  </change>

Similarly, if you change the primary language ("Langauge 1") of a book,
you will typically have to re-tag all the text fields in the body of the book
as belonging to the new language. You can do this with:

  <change>
    <target>//div[@role="textbox" and @lang="I<old_language_code>"]</target>
    <to lang="I<new_language_code>"/>
  </change>

=back

=head1 Required modules

B<clean_xmatter.pl> relies on the following non-core Perl modules:

=over

=item L<Encode|https://metacpan.org/pod/Encode>

=item L<HTML::Element|https://metacpan.org/pod/HTML::Element>

=item L<HTML::Entities|https://metacpan.org/pod/HTML::Entities>

=item L<HTML::TreeBuilder|https://metacpan.org/pod/HTML::TreeBuilder>

=item L<HTML::TreeBuilder::XPath|https://metacpan.org/pod/HTML::TreeBuilder::XPath>

=item L<IO:HTML|https://metacpan.org/pod/IO::HTML>

=item L<XML::LibXML|https://metacpan.org/pod/XML::LibXML>

=item L<String::ShellQuote|https://metacpan.org/pod/String::ShellQuote>

=back

=head1 See also

list_xmatter.pl

=head1 Author

Fraser Bennett,
L<fraser_bennett@sil-lead.org|mailto:fraser_bennett@sil-lead.org>

=head1 Bugs

Please report any bugs or feature requests to
L<fraser_bennett@sil-lead.org|mailto:fraser_bennett@sil-lead.org>.

=head1 Copyright and License

clean_xmatter.pl Copyright 2020 L<SIL LEAD, Inc.|https://www.sil-lead.org>
Licensed under the L<GNU General Public License 3.0|https://www.gnu.org/licenses/gpl-3.0.en.html>

=head1 Acknolwedgements

B<clean_xmatter.pl> was created for the USAID/Afghan Children Read project.

=cut


# use strict; use warnings;
use Encode qw(encode decode);
use Getopt::Long;
use HTML::Element 5 -weak; use HTML::Entities; use HTML::TreeBuilder;
use HTML::TreeBuilder::XPath;
use IO::HTML;
use String::ShellQuote;
use utf8;
use XML::LibXML;

### SETTINGS ###
GetOptions (
  "h|help" => \$help,
  "t|test" => \$test, # don't write out results
  "c|changes=s" => \$changes, # file with field and language mapping specs
);

if ($help or !$changes or !@ARGV) {
  print "Usage: \n";
  print "  clean_xmatter.pl --changes changedefs.xml [--test] sourcedir\n";
  print "For more details, use perldoc clean_xmatter.pl\n";
  exit;
}

my $changes = XML::LibXML->load_xml(location => $changes);

my $sourcedir = shift @ARGV;
$sourcedir = shell_quote($sourcedir);

## collection-level operations: ##
# look for bloomCollections
my @bloomCollections = `find $sourcedir -name '*.bloomCollection'`;
foreach $bloomCollection (@bloomCollections) {
  chomp $bloomCollection;
  my @path = split "/", $bloomCollection;
  my $bloomCollectionName = pop @path;
  $bloomCollectionName = decode('utf8', $bloomCollectionName);
  $bloomCollectionName =~ s/^\s*(.+?)\s*\.bloomCollection$/$1/;
  my $bloomCollectionFolder = $path[$#path];
  $bloomCollectionFolder = decode('utf8', $bloomCollectionFolder);

  my @delete_targets = $changes->gather_delete_targets($bloomCollectionFolder);
  my @changes = $changes->gather_change_targets($bloomCollectionFolder);
  my @merges = $changes->gather_merge_targets($bloomCollectionFolder);
  # global %collection_languages 'cuz we need it all over
  %collection_languages = $changes->get_collection_languages($bloomCollectionFolder);

  ## book-level operations ##
  # look for book files in the folders containing the .bloomCollection files
  my $path = join("/", @path);
  $path = shell_quote($path);
  my @filepaths = `find $path -name '*.htm'`;

  # process each book found
  foreach $filepath (@filepaths) {
    chomp $filepath;
    # open and parse the file
    open my $fh, "<:encoding(utf8)", $filepath;
    my $tree = HTML::TreeBuilder->new();
    $tree->parse_file($fh);
    close $fh;

    # set @data-l1 attributes
    $tree->set_body_languages(%collection_languages);

    # delete unwanted elements
    $tree->delete_elements(@delete_targets);

    # merge fields #
    $tree->merge_fields(@merges);

    # process transforms specified in $transforms file
    $tree->change_targets(@changes);

    # trim white space fore and aft in div/@bloomDataDiv
    $tree->trim_whitespace();

    # output the tree as html
    my $html = $tree->as_HTML('', '  ', {});
    $html = decode_entities($html);
    $html =~ s/\x{FEFF}//g;
    unless ($test) {
      open $fh, ">:encoding(UTF-8)", $filepath;
      print $fh $html;
      close $fh;
    }
    print "$filepath\n";

  } # foreach $filepath (@filepaths)

} # foreach $bloomCollection (@bloomCollections)






### subs below here ###



sub temp_lgs  {
  my %collection_languages = @_;
  my %tmp_lgs;
  foreach my $v (values %collection_languages, '*', 'z', 'Z') {
    $tmp_lgs{$v} = 1;
  }
  return %tmp_lgs;
}


sub HTML::Element::merge_fields {
  my $self = shift;
  my @mergesets = @_;
  for (@mergesets) {
    my @mergeset = @{$_};
    unless (@mergeset) {next;}
    my @divs_to_merge;
    for my $merge_target (@mergeset) {
      my ($h) = $self->findnodes($merge_target);
      unless ($h) {
        my ($databook) = $merge_target =~ /data-book="(.+)"/;
        $h = HTML::Element->new_from_lol(['div', {'data-div' => $databook, 'lang' => $collection_languages{'data-l2'}}]);
        my ($datadiv) = $self->findnodes('//div[@id="bloomDataDiv"]');
        $datadiv->push_content($h);
      }
      push @divs_to_merge, $h;
    }
    my $div0 = shift @divs_to_merge;
    for my $div (@divs_to_merge) {
      my @content_list = $div->content_list();
      for my $content_item (@content_list) {
        unless ($content_item->as_text() =~ /^\s*$/) {
          $div0->push_content($content_item);
        }
      }
      $div->delete();
    }
  }
};


sub HTML::Element::delete_elements {
  my $self = shift;
  @delete_targets = @_;
  for $delete_target (@delete_targets) {
    my @matches = $self->findnodes($delete_target);
    for my $match (@matches) {
      $match->delete();
    }
  }
}


sub HTML::Element::set_body_languages {
  my ($self, %collection_languages) = @_;
  my $body = $self->look_down(_tag => 'body');
  for my $key (keys %collection_languages) {
    $body->attr($key, $collection_languages{$key});
  }
}


sub HTML::Element::change_targets {
  my $self = shift;
  my @changes = @_;
  foreach $change ( @changes ) {
    my %change = %{$change};
    @targets = $self->findnodes( $change{target} );
    foreach $target ( @targets ) {
      foreach my $attr ( keys %{$change{to}} ) {
        $target->attr($attr, ${$change{to}}{$attr});
      }
    }
  }
}


sub HTML::Element::trim_whitespace {
  $self = shift;
  my ($xroot) = $self->findnodes('//div[@id="bloomDataDiv"]');
  $xroot->objectify_text();
  @text_strings = $xroot->look_down(_tag => '~text');
  foreach $text_string (@text_strings) {
    my $t = $text_string->attr(text);
    $t =~ s/^\s*(.+)\s*$/$1/;
    $text_string->attr(text, $t);
  }
  $xroot->deobjectify_text();
}



sub XML::LibXML::Node::get_collection_languages {
  # method sub to get L1/L2/L3 codes for each Bloom book collection in $mapping
  my ($self, $bloomCollectionName) = @_;
  my %collection_languages;
  my $xpath = q{//collection[@name="} . qq{$bloomCollectionName} . q{"]};
  my ($collection) = $self->findnodes($xpath);
  if ($collection->getAttribute(name) eq $bloomCollectionName) {
    for my $attr ($collection->attributes()) {
      if ($attr->name() =~ m/^l\d$/) {
        my $label = 'data-' . $attr->name();
        $collection_languages{$label} = $attr->value();
      }
    }
  }
  return %collection_languages;
}


sub XML::LibXML::Node::gather_change_targets {
  my ($self, $bloomCollectionName) = @_;
  my (@nodelist, @change_targets);
  my $searchpath = '//collection[@name="' . $bloomCollectionName . '"]/change';
  push @nodelist, $self->findnodes('//allCollections/change');
  push @nodelist, $self->findnodes($searchpath);
  for my $node (@nodelist) {
    my %change;
    unless ($node->textContent =~ /^\s*$/) {
      $change{target} = $node->textContent();
      my ($to_node) = $node->findnodes('./to');
      my @to_attribute_nodes = $to_node->attributes();
      for $to_attribute_node (@to_attribute_nodes) {
        my $attribute_name = $to_attribute_node->localname;
        my $attribute_value = $to_attribute_node->getValue();
        ${$change{to}}{$attribute_name} = $attribute_value;
      }
      push @change_targets, \%change;
    }
  }
  return @change_targets;
}


sub XML::LibXML::Node::gather_delete_targets {
  my ($self, $bloomCollectionName) = @_;
  my (@nodelist, @delete_targets);
  my $searchpath = '//collection[@name="' . $bloomCollectionName . '"]/delete/target';
  push @nodelist, $self->findnodes('//allCollections/delete/target');
  push @nodelist, $self->findnodes($searchpath);
  for my $node (@nodelist) {
    push @delete_targets, $node->textContent();
  }
  return @delete_targets;
}


sub XML::LibXML::Node::gather_merge_targets {
  my ($self, $bloomCollectionName) = @_;
  my (@nodelist, @merges);
  my $searchpath = '//collection[@name="' . $bloomCollectionName . '"]/merge';
  push @nodelist, $self->findnodes('//allCollections/merge');
  push @nodelist, $self->findnodes($searchpath);
  for my $node (@nodelist) {
    my @merge;
    my @merge_targets = $node->findnodes('./target');
    for $merge_target (@merge_targets) {
      push @merge, $merge_target->textContent();
    }
    push @merges, \@merge;
  }
  return @merges;
}
