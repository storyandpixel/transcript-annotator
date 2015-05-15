# Transcript Annotator

Marries an FCP XML file and a Markdown transcript

# Architecture

* Transcripts are in Markdown
* Export Premiere sequence to XML
* Script input
	* markdown file
	* final cut xml file
	* sequence name
* Script output
	* content blocks for Realtime Board

# TODO

- [X] Parse XML file and output clip timestamps
- [ ] Parse Markdown transcript to round up highlighted sections
- [ ] Compare count of clips from XML and Markdown transcript, fail if mismatched
- [ ] Output result of combining timestamps and transcript portions

# MaybeDO

- [ ] Add `Choice` lib to allow for named script args
