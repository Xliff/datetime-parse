my class X::DateTime::CannotParse is Exception {
    has $.invalid-str;
    method message() { "Unable to parse [{$!invalid-str}]" }
}

class DateTime::Parse is DateTime {
    grammar Grammar {
        regex TOP {
          <dt>
        }

        regex dt {
          <mysql-date>      | <rfc3339-date>    | <rfc1123-date>  |
          <rfc850-date>     | <asctime-date>    | <nginx-date>    |
          <curl-dt>         | <date6>           | <us-date>       |
          <intl-date>       | <kern-log>        | <yyyy-mm-dd>
        }


        token rfc3339-date {
            <date=.date5> [ <[Tt \x0020]> <time=.time2> ]?
        }

        token date6 {
            <year=.D4-year> <month=.D2> <day=.D2>
        }

        token yyyy-mm-dd {
          <year=.D4-year> '-' <month=.D2> '-' <day=.D2>
        }

        token nginx-date {
            <date=.date6Slashes> ':' <time=.time3>
        }

        token time2 {
            <part=.partial-time> <offset=.time-offset>?
        }

        token time3 {
            <time=.partial-time> ' ' <time-numoffset>
        }

        token partial-time {
            <hour=.D2> ':' <minute=.D2> ':' <second=.D2> <frac=.time-secfrac>?
        }

        token time-secfrac {
            '.' \d+
        }

        token time-offset {
            [ 'Z' | 'z' | <offset=.time-numoffset>]
        }

        token time-numoffset {
            <sign=[+-]> <hour=.D2> ':'? <minute=.D2>
        }

        token time-houroffset {
            <sign=[+-]> <hour>
        }

        token hour {
            \d \d?
        }

        token gmt-or-numeric-tz {
          'GMT' | 'UTC' | [ <[-+]>? <[0..9]> ** 4 ]
        }

        token rfc1123-date {
            <.wkday> ',' <.SP> <date=.date1> <.SP> <time> <.SP> <gmt-or-numeric-tz>
        }

        token rfc850-date {
            [
              <.weekday> ',' |
              <.wkday>
            ]  <.SP>
            [
              <date=.date2> |
              <date=.date4>
            ] <.SP>
            <time> <.SP> <gmt-or-numeric-tz>
        }

        token asctime-date {
          <asctime-date-year> | <asctime-date-zone>
        }
        token asctime-date-year {
            <.wkday>        <.SP>
            <date=.date3>   <.SP>
            <time>          <.SP>
            <year=.D4-year>       <asctime-t1z>?
        }
        token asctime-date-zone {
          <.wkday>      <.SP>
          <date=.date3> <.SP>
          <time>        <.SP>
          <gmt-or-numeric-tz> <.SP>
          <year=.D4-year>
        }

        token asctime-tz {
            <.SP> <asctime-tzname> <time-houroffset>?
        }

        token asctime-tzname {
            \w+
        }

        token date1 { # e.g., 02 Jun 1982
            <day=.D2> <.SP> <month> <.SP> <year=.D4-year>
        }

        token date2 { # e.g., 02-Jun-82
            <day=.D2> '-' <month> '-' <year=.D2>
        }

        token date3 { # e.g., Jun  2
            <month> <.SP> <day>
        }

        token date4 { # e.g., 02-Jun-1982
            <day=.D2> '-' <month> '-' <year=.D4-year>
        }

        token date5 {
            <year=.D4-year>  '-' <month=.D2> '-' <day=.D2>
        }

        token us-date {
             <month=.D2> '/' <day=.D2> '/' <year=.D4-year>
        }

        token intl-date {
             <year=.D4-year> '/' <month=.D2> '/' <day=.D2>
        }

        token date6Slashes {
            <day=.D2> '/' <month> '/' <year=.D4-year>
        }

        token curl-dt {
            <month>             <.ws>
            <day>               <.ws>
            <time>              <.ws>
            <year=.D4-year>     <.ws>
            <gmt-or-numeric-tz>
        }

        token mysql-date {
          <date5> <.ws> <time=partial-time>
        }

        token kern-log {
          <month>                <.ws>
          <day>                  <.ws>
          [',' <year=.D4-year>]? <.ws>
          <time>
        }

        token time {
            <hour=.D2> ':' <minute=.D2> ':' <second=.D2>
        }

        token day {
            <.D1> | <.D2>
        }

        token wkday {
            'Mon' | 'Tue' | 'Wed' | 'Thu' | 'Fri' | 'Sat' | 'Sun'
        }

        token weekday {
            'Monday' | 'Tuesday' | 'Wednesday' | 'Thursday' | 'Friday' | 'Saturday' | 'Sunday'
        }

        token month {
            'Jan' | 'Feb' | 'Mar' | 'Apr' | 'May' | 'Jun' | 'Jul' | 'Aug' | 'Sep' | 'Oct' | 'Nov' | 'Dec'
        }

        token D4-year {
            \d ** 4
        }

        token D2-year {
            \d ** 2
        }

        token SP {
            \s+
        }

        token D1 {
            \d
        }

        token D2 {
            \d ** 2
        }
    }

    class Actions {
        has $!timezone is built;

        method TOP($/) {
          make $/<dt>.made;
        }

        method dt ($/) {
          for <
              mysql-date   rfc3339-date    rfc1123-date
              rfc850-date  rfc850-var-date rfc850-var-date-two
              asctime-date nginx-date      curl-dt
              us-date      intl-date       date6
              kern-log
          > {
              return make $/{$_}.made if $/{$_};
          }
        }

        method rfc3339-date($/) {
            make $<time> ?? DateTime.new(|$<date>.made, |$<time>.made)
                         !! DateTime.new(|$<date>.made);
        }

        method rfc1123-date($/) {
            make DateTime.new(|$<date>.made, |$<time>.made, |$<gmt-or-numeric-tz>.made)
        }

        method rfc850-date($/) {
            make DateTime.new(|$<date>.made, |$<time>.made, |$<gmt-or-numeric-tz>.made)
        }

        # method rfc850-var-date($/) {
        #     make DateTime.new(|$<date>.made, |$<time>.made, |$<gmt-or-numeric-tz>.made)
        # }

        method gmt-or-numeric-tz($/) {
            $/.make: %( timezone =>
                    "$/" eq 'UTC' | 'GMT' | 'Z' ?? 0 !! +$/ * 36
                );
        }

        # method rfc850-var-date-two($/) {
        #     make DateTime.new(|$<date>.made, |$<time>.made, |$<gmt-or-numeric-tz>.made)
        # }

        method asctime-date($/) {
          my $z = $<asctime-date-zone>.made;
          my $y = $<asctime-date-year>.made;

          make do {
            when $z.defined { $z }
            when $y.defined { $y }

            default { Nil }
          }
        }

        method asctime-date-year ($/) {
            my $date = $<date>.made;
            $date<year> = $<year>.made;

            my $tz = ($<asctime-tz>.made<offset-hours> // 0) × 3600;

            make DateTime.new(
              |$date,
              |$<time>.made,
              :timezone($!timezone // $tz)
            )
        }

        method asctime-date-zone ($/) {
            my $date    = $<date>.made;
            $date<year> = $<year>.made;

            my $time    = $<time>.made;
            my $tz      = $<gmt-or-numeric-tz>.made<timezone>;

            my $dt = DateTime.new(
              |$date,
              |$time,
              :timezone($tz)
            );

            make $dt;
        }

        method curl-dt ($/) {
          make DateTime.new(
            month => $<month>.made,
            day   => $<day>.made,
            year  => $<year>.made,

            |$<time>.made
          );
        }

        method nginx-date($/) {
            make DateTime.new(|$<date>.made, |$<time>.made);
        }

        method mysql-date($/) {
            make DateTime.new(
              year   => $<date5><year>.made,
              month  => $<date5><month>.made,
              day    => $<date5><day>.made,
              hour   => $<time><hour>.made,
              minute => $<time><minute>.made,
              second => $<time><second>.made
            );
        }

        method kern-log ($/) {
          make DateTime.new(
            year   => $<year>.made // DateTime.now.year,
            month  => $<month>.made,
            day    => $<day>.made,
            hour   => $<time><hour>.made,
            minute => $<time><minute>.made,
            second => $<time><second>.made
          );
        }

        method !genericDate($/) {
            make { year => $<year>.made, month => $<month>.made, day => $<day>.made }
        }

        method date1($/) { # e.g., 02 Jun 1982
            self!genericDate($/);
        }

        method date2($/) { # e.g., 02-Jun-82
            self!genericDate($/);
        }

        method date3($/) { # e.g., Jun  2
            self!genericDate($/);
        }

        method date4($/) { # e.g., 02-Jun-1982
            self!genericDate($/);
        }

        method date5($/) { # e.g. 1996-12-19
            self!genericDate($/);
        }

        method date6 ($/) { # e.g. 19961219
          make DateTime.new( |self!genericDate($/) );
        }

        method yyyy-mm-dd ($/) {
          make DateTime.new( |self!genericDate($/) );
        }

        method date6Slashes ($/) { # e.g. 02/Feb/2000
            make DateTime.new( |self!genericDate($/) );
        }

        method us-date ($/) { # e.g. 02/28/2000
          make DateTime.new( |self!genericDate($/) );
        }

        method intl-date ($/) { # e.g. 2000/02/28
          make DateTime.new( |self!genericDate($/) );
        }

        my %timezones =
            UTC => 0,
            GMT => 0,
        ;

        method asctime-tz($/) {
            my $offset =
              (%timezones{$<asctime-tzname>.made} // 0) +
              ($<time-houroffset>.made            // 0);

            make { offset-hours => $offset }
        }

        method asctime-tzname($/) {
            make ~$/
        }

        method time-houroffset($/) {
            make +$/
        }

        method time($/) {
            make {
              hour   => +$<hour>,
              minute => +$<minute>,
              second => +$<second>
            }
        }

        method time2($/) {
            my $p = $<part>;
            my $offset = 0;
            with $<offset> {
              unless $_ eq 'Z'|'z' {
                  if ~.<offset><sign> eq '-' {
                      $offset = 3600 * ~.<offset><hour>.Int;
                      $offset += 60 * ~.<offset><minute>.Int;
                  }
              }
            }
            my %res =
              hour     => ~$p<hour>,
              minute   => ~$p<minute>,
              second   => ~$p<second>,
              timezone => -$offset;

            make %res;
        }

        method time3($/) {
            my Int $offset = 0;

            $offset += +$<time-numoffset><hour> × 60;
            $offset += +$<time-numoffset><minute>;

            make {
                hour     => +$<time><hour>,
                minute   => +$<time><minute>,
                second   => +$<time><second>,
                timezone => $offset,
            };
        }

        my %wkday = Mon => 0, Tue => 1, Wed => 2, Thu => 3, Fri => 4, Sat => 5, Sun => 6;
        method wkday($/) {
            make %wkday{~$/}
        }

        my %weekday = Monday => 0, Tuesday => 1, Wednesday => 2, Thursday => 3,
                      Friday => 4, Saturday => 5, Sunday => 6;
        method weekday($/) {
            make %weekday{~$/}
        }

        my %month = Jan => 1, Feb => 2, Mar => 3, Apr =>  4, May =>  5, Jun =>  6,
                    Jul => 7, Aug => 8, Sep => 9, Oct => 10, Nov => 11, Dec => 12;

        method month($/) {
            make %month{~$/}
        }

        method day($/) {
            make +$/
        }

        method D4-year($/) {
            make +$/
        }

        method D2-year($/) {
            my $yy = +$/;
            make $yy < 34 ?? 2000 + $yy !! 1900 + $yy
        }

        method D2($/) {
            make +$/
        }
    }

    method new (Str $format, :$timezone is copy, :$rule = 'TOP') {
      my $p = DateTime::Parse::Grammar.parse(
         $format,
        :$rule,
        actions   => $timezone ?? DateTime::Parse::Actions.new(:$timezone)
                               !! DateTime::Parse::Actions.new
      );

      return $p.made if $rule ne 'TOP';

      $p or X::DateTime::CannotParse.new( invalid-str => $format ).throw;

      $/.made
    }
}

=begin pod

=head1 NAME

DateTime::Parse - DateTime parser

=head1 SYNOPSIS

    use DateTime::Parse;
    my $date = DateTime::Parse.new('Sun, 06 Nov 1994 08:49:37 GMT');
    say $date.Date > Date.new('12-12-2014');

=head1 DESCRIPTION

=head2 Available formats:

=item asctime

=head1 METHODS

=head2 method new

    method new(Str $format, :$timezone is copy = 0, :$rule = 'TOP')

A constructor, where:

=item $format is the text we want to parse
=item $timezone is the timezone we want to get the date in (nyi)
=item $rule specifies which rule to use, in case we know what format we want to parse (see L<#Available_Formats>)

=head1 AUTHOR

Filip Sergot (sergot)
Website: filip.sergot.pl
Contact: filip (at) sergot.pl

=end pod

# vim: et sw=4 ts=4
