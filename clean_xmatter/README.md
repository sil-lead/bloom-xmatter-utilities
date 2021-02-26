# Title

**clean_xmatter.pl**

# Version

0.6

# Description

**clean_xmatter.pl** takes a collection of Bloom books and "cleans" various bits
of the book metadata ("xmatter"), credits page, and page data in the HTML source
file of each Bloom book. This is needed when a user has created a set of books
using incorrect language settings or has placed front-matter metadata in the
wrong front matter fields.

**clean_xmatter.pl** applies the same set of changes to all books in a collectio,
but it can operate on more than one set of Bloom collections at
once. You can specifiy changes to be made across-the-board to multiplie
collections, or restrict a set of changes to a specific collection.

# Usage
```
    $ clean_xmatter.pl --changes path/to/changedefs.xml [--test] path/to/bloomCollection/folder
```
    **Warning:** Results are written in-place. Original data is
   overwritten. You are highly encouraged to run the script on a copy of the
   originals!

## Required arguments

- `--changes`

    specifies an xml file that specifies the changes to be made to the Bloom book
    files. See ["changes file format"](#changes-file-format) below for details.

- `--sourcedir`

    specifies the path to the directory that contains the Bloom books to be processed.
    The directory **must** contain a `.bloomCollection` file. (The script doesn't
    do anything to or with the `.bloomCollection` file -- it's just a convenient
    way to recognize a folder of Bloom books. This allows the script to deal with
    nested Bloom book folders.)

## Optional arguments

- `--test`
suppresses the output of the script -- useful for debugging.

# Changes XML format

**Warning:** You should be familiar with the internal structure of Bloom HTML
book files before writing your own change specifications.>

The XML file containing the changes to be worked on the Bloom book files must
have the following structure:
```
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
```
    C<merge>, C<delete>, and C<change> elements can appear in either
    C<allCollections> or C<collection> elements, in any order.

    The first C<target> child element of a C<merge> element is the element
    that is kept; the other child elements are merged into the first.

- `<collections>`

    `<collections>` is the root of the XML file, but it really just
    serves as a wrapper for what is beneath. You should never have to refer to it.

- `<allCollections>`

    `<allCollections>` contains a set of changes that will be applied to
    all collections. These will mostly be `<delete>`.

- `<collection name="_folder_name_" l1="_aaa_" l2="_aaa_" [l3="_aaa_"]>`
```
        <collection name="myBloomBooks" l1="dag" l2="en">
```
    `<collection>` contains a list of changes to be applied to a single
    Bloom collection, as a series of `<change>` and `<delete>`
    elements. `<change>` and `<delete>` may appear in any order.
    `<change>` and `<delete>` are applied in the order in which
    they appear.

    `<collection>` has three required attributes:

    - `name="collection_name"`

        `name` specifies the name (i.e., the filename) of the folder/directory  that
        contains the Bloom collection. (Note: this is usually (but not always) the same
        as the filename (less the `.bloomCollection` extension) of the
        `.bloomCollection` file that also resides in the folder -- here, we want the
        folder name.

    - `l1="ISO539_code"`

        Bloom allows for up to three languages to be specified for each book.
        **clean_xmatter.pl** assumes that at least two languages will be specified.

        `l1` specifies the ISO639 code that will be written to the output file in the
        `data-l1` attribute on the HTML `<body>` element. This is the
        "vernacular" language, the main language of the book. The code used may be a
        two-letter [ISO639-2](https://www.loc.gov/standards/iso639-2/) or a
        three-letter [ISO639-3](https://iso639-3.sil.org/code_tables/639/data) code.

    - `l2="ISO539_code"`

        `l2` specifies the [ISO639](https://en.wikipedia.org/wiki/ISO_639)
        code that will be written to the output file in the
        `data-l2` attribute on the HTML `<body>` element. This is the
        main language of many front-matter metadata elements, such as copyright and
        licensing information, and is usually a national language. `l2` may be the
        same as `l1`.

    - `l1="ISO539_code"` (optional)

        `l3` specifies the ISO639 code that will be written to the output file in the
        `data-l3` attribute on the HTML `<body>` element. `data-l3` specifies
        a regional or international langugae.

- `<delete>`

    `<delete>` is a convenience wrapper for a `<target>` element.

- `<target>`

    The content of `<target>` is an XPath expression that specifies
    an HTML element that should be removed from the Bloom book. The XPath
    expression should pick out an element, not an attribute or text content.

    For instance, the
    following will remove existing copyright metadata element from a Bloom book
    (presumably to be replaced by a corrected copyright element).
```
        <target>//div[@id="bloomDataDiv"]/div[@data-book="copyright"]</target>
```
    Because the XPath search routines are based on
    [XML::XPathEngine](https://metacpan.org/pod/XML::XPathEngine), you can
    use a regular expresssion in the XPath expression:
```
        <target>//div[@class=~/\bcredits\b/]//div[@data-derived="copyright"]</target>
```
- `<change>`

    A `<change>` element has two children: a `<target>` element
    that specifies the set of elements to be acted on, and a `<to>`
    element that specifies the alterations to be made.

- `<to>`

    `<to>` specifies the changes to make in an element that is picked out
    by a sibling `<target>` XPath expression. Only attribute values may be
    changed: **clean\_xmatter.pl** will not change the tag name of an attribute. The
    attributes of `<to>` and their values specifiy the attributes of the
    targeted elements that will be changed and their new values.

    Typically, this involves a `data-book` attribute (which specifies a
    front-matter metadata field) and a `lang` attribute, which specifies the
    language of that field's contents.

    For instance:
```
        <change>
          <target>//div[@id="bloomDataDiv"]/div[@data-book="bookTitle" and @lang="en"]</target>
          <to data-book="levelInformation" lang="pbt" />
        </change>
```
    The `<target>` XPath expresseion will seek out `<div>`
    elements that are children of the
    `<div id="bloomDataDiv">` element, and that contain the content of the
    `bookTitle` front matter field _and_ are tagged as being in English (`"en"`).
    clean\_xmatter.pl will change all such elements so that their content
    is instead tagged as belonging to the front matter `levelInformation` field,
    and as being in the Southern Pashto language (`"pbt"`).

    You can change the `"lang"` attributes of all the _other_
    `<div id="bloomDataDiv">/<div>` elements by placing the
    following general `<change>` element _after_ the more specific
    `<change>` elements:
```
        <change>
          <target>//div[@id="bloomDataDiv"]/div</target>
          <to lang="I<new_language_code>" />
        </change>
```
    Similarly, if you change the primary language ("Langauge 1") of a book,
    you will typically have to re-tag all the text fields in the body of the book
    as belonging to the new language. You can do this with:
```
        <change>
          <target>//div[@role="textbox" and @lang="I<old_language_code>"]</target>
          <to lang="I<new_language_code>"/>
        </change>
```
# Required modules

**clean_xmatter.pl** relies on the following non-core Perl modules:

- [Encode](https://metacpan.org/pod/Encode)
- [HTML::Element](https://metacpan.org/pod/HTML::Element)
- [HTML::Entities](https://metacpan.org/pod/HTML::Entities)
- [HTML::TreeBuilder](https://metacpan.org/pod/HTML::TreeBuilder)
- [HTML::TreeBuilder::XPath](https://metacpan.org/pod/HTML::TreeBuilder::XPath)
- [IO:HTML](https://metacpan.org/pod/IO::HTML)
- [XML::LibXML](https://metacpan.org/pod/XML::LibXML)
- [String::ShellQuote](https://metacpan.org/pod/String::ShellQuote)

# See also

list_xmatter.pl

# Author

Fraser Bennett,
[fraser_bennett@sil-lead.org](mailto:fraser_bennett@sil-lead.org)

# Bugs

Please report any bugs or feature requests to
[fraser_bennett@sil-lead.org](mailto:fraser_bennett@sil-lead.org).

# Copyright and License

clean_xmatter.pl Copyright 2020 [SIL LEAD, Inc.](https://www.sil-lead.org)
[CC-BY 4.0 International](https://creativecommons.org/licenses/by/4.0/)

# Acknolwedgements

**clean_xmatter.pl** was created for the USAID/Afghan Children Read project.