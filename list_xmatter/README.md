# Title

**list_xmatter.pl**

# Version

0.6

# Description

**list_xmatter.pl** takes one or more Bloom book files and returns a tab-separated text file containing a table of all the front matter ('xmatter') field contents. Rows are collection name, file name, and field name, columns are language tags. This is useful in diagnosing the changes that need to be made to a Bloom collection that was incorrectly set up for language tags, or where the user has entered data into the wrong front matter fields.

# Usage

    $ list_xmatter.pl --output path/to/outfile.csv [--help] path/to/bloomCollection/folder

## Required arguments

- `-o, --output`

    specifies a CSV file where the results will be written.

## Optional arguments

- `-h, --help`

    displays a brief usage message and exits

# Required modules

**list_xmatter.pl** relies on the following non-core Perl modules:

- [Encode](https://metacpan.org/pod/Encode)
- [HTML::Element](https://metacpan.org/pod/HTML::Element)
- [HTML::Entities](https://metacpan.org/pod/HTML::Entities)
- [HTML::TreeBuilder](https://metacpan.org/pod/HTML::TreeBuilder)
- [HTML::TreeBuilder::XPath](https://metacpan.org/pod/HTML::TreeBuilder::XPath)
- [IO:HTML](https://metacpan.org/pod/IO::HTML)
- [String::ShellQuote](https://metacpan.org/pod/String::ShellQuote)
- [Text::CSV](https://metacpan.org/pod/Text::CSV)

# See also

clean_xmatter.pl

# Author

Fraser Bennett,
[fraser_bennett@sil-lead.org](mailto:fraser_bennett@sil-lead.org)

# Bugs

Please report any bugs or feature requests to
[fraser_bennett@sil-lead.org](mailto:fraser_bennett@sil-lead.org).

# Copyright and License

list_xmatter.pl Copyright 2020 [SIL LEAD, Inc.](https://www.sil-lead.org)
[CC-BY 4.0 International](https://creativecommons.org/licenses/by/4.0/)

# Acknolwedgements

**list_xmatter.pl** was created for the USAID/Afghan Children Read project.
