==========
 Function
==========

1. Crawl from "start_url" and get links of target page and next page.
   - target page is judged by DataHandler::is_target_url
   - next page is judged by DataHandler::is_page_url
2. Get data of target page by DataHander::execute and export the data to Excel file
3. After getting all the data of target pages of 1., Go to next page. (Repeat from 1.)
4. After go through all links or time is over(max_running_time_seconds), close Excel file and save parameter data.

- Sleep a little time after getting one page (the time is random value from 0 to max_wait_seconds.)
- UserAgent
- Proxy

Excel file
- one sheet has 10000 rows
- utf8

============
 How to run
============

1. Check installation of Perl
$ /usr/bin/perl -v

This is perl 5, version... (will be displayed.)

2. Add modules of Perl
$ sudo cpan
cpan> install LWP::UserAgent
cpan> install LWP::Simple
cpan> install HTML::TreeBuilder
cpan> install HTML::TreeBuilder::XPath
cpan> install Text::Trim
cpan> install Spreadsheet::WriteExcel
cpan> install LWP::Protocol::https
cpan> install Net::SSL
cpan> exit

3. Set parameters
$ vi main.pl

4. Backup previous data if necessary

5. Run
$ perl main.pl

6. Result
- Excel file is placed at the path of "filename" parameter.

* "cookies.txt", "cont.dat" are also created. If you continue the crawling(cont:1), these files are needed.


EOF
