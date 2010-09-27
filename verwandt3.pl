use strict;
use warnings;

my $stdin = $ARGV[0];

my %mw = ( 	Mutter => "Vater",
		Tochter => "Sohn",
		Schwester => "Bruder",
		Nichte => "Neffe",
		Tante => "Onkel",
		Cousine => "Cousin"
	);


%verwandtschaftIndex = ( 					
				Mutter => "o",
				Tochter => "ur",
				Schwester => "r",
				Nichte => "ru", 
				Tante => "or",
				Cousine => "oru", 
			);

#Geschlecht bestimmen.
my $geschlecht;
$stdin =~ /^(?:ur)*(?:gross|enkel)*(.*?)\s/i;
if (defined $verwandtschaftIndex{ucfirst(lc($1))}) { $geschlecht = "w"; }
else { $geschlecht = "m" }

#Begrifflichkeiten auf weiblich ändern (1.keine s, 2. weniger schreibarbeit)
$stdin =~ s/vater(s)*/mutter/gi;
$stdin =~ s/bruder(s)*/schwester/gi;
$stdin =~ s/sohn(es)*/tochter/gi;
$stdin =~ s/neffe(n)*/nichte/gi;
$stdin =~ s/onkel(s)*/tante/gi;
$stdin =~ s/cousin(s)* /cousine /gi;
#Feststellen der Verwandtschaft von hinten nach vorne

my @aufgespaltet =  $stdin =~ /(cousine(?:\s\d+\.Grades)*|\w*tante|\w*nichte|\w*mutter|\w*tochter|schwester)/ig;

my $index;

foreach (reverse(@aufgespaltet)) {
  my $weg = Weg(lc($_));
  $index .= $weg;
  $index = Regel($index) unless ($index eq "ur");
}

my $bezeichnung = Bezeichnung($index);

my $weg = Weg($bezeichnung);

#Richtiges Geschlecht bestimmen. Die Notation stimmt schon, wenn das Geschlecht
# weiblich ist, deshalb wird es nur verändert wenn $geschlecht == "m"

if ($geschlecht eq "m") {
  $bezeichnung =~ /^(?:ur)*(?:gross|enkel)*(.*?)(\s|$)/i;
  my $bez = $1;
  my $ers = lc($mw{ucfirst(lc($bez))});
  $bezeichnung =~ s/$bez/$ers/;
  $bezeichnung = ucfirst($bezeichnung);
}

print "$bezeichnung\n";

##
# 
# Regel($arg1)
# Wendet Regeln auf einen Weg auf der Ahnentafel an, so dass daraus der
# kürzeste Weg entsteht. Wenn in Beschreibungen der Begriff "korrekter Weg
# verwendet wird, ist ein Weg nach Anwendung von Regel() gemeint.
# $arg1 ist irgend ein Weg auf der Ahnentafel
# z.B. uuuurrroooruu
#
###

sub Regel {

  my $index = $_[0];

  # ro wird durch r ersetzt, da Geschwister die gleichen Eltern haben.
  $index =~ s/ro/o/g;
  # ou wird gelöscht, da es sich aufhebt.
  while ($index =~ s/ou|uo//) {};
  # rr wird durch r ersetzt, da z.B. die Schwester der Schwester meiner Tante
  # auch meine Tante ist.
  $index =~ s/rr/r/g;
  # Nach dem ersten r werden alle r gelöscht.
  while ($index =~ s/(o*?)r(.*?)r(.*)/$1r$2$3/) {}; 
  #Alle r entfernen, wenn u zu beginn. Da alle Nachkommen der Tochter immer die gleiche Bezeichnung haben (z.B. Die Schwester meiner Enkeltochter ist ebenfalls meine Enkeltochter.
  $index =~ s/r// if ($index =~ /^u/); 
  return($index);
}

##
#
# Generation($arg1);
# $arg1 wird als Weg auf der Ahnentafel benötigt
# z.B. für Cousine "oru" (oben-rechts-unten)
#
##

sub Generation {

  my $index = $_[0];
  # Generation bestimmen
  my $countO = () = $index =~ m/o/g; # Alle o's zählen
  my $countU = () = $index =~ m/u/g; # Alle u's zählen

  my $generation = $countO - $countU; # Und die Differenz berechnen.

  return wantarray ? ($generation, $countO, $countU) : $generation;
}

##
#
#  Verwandtschaftsgrad($arg1);
#  Bestimmt mit Hilfe eines korrekten Weges auf der Ahnentafel den
#  Verwandtschaftsgrad.
#  $arg1 ist ein Weg auf der Ahnentafel.
#
##

sub Verwandtschaftsgrad {
  my $index = $_[0];
  my ($generation, $countO)  = Generation($index);
  my $vgReihe = 0; # Bezeichnet den Verwandtschaftsgrad in der Reihe (siehe Übungsblatt).
  my $vgBezeichnung = 0; # Bezeichnet den Verwandtschaftsgrad in der Bezeichnung also z.B. das "2.Grades".
  if ($index =~ /r/) { 
    $vgReihe = $countO + 1; 
    if ($generation < 0) {
      $vgBezeichnung = $vgReihe;
    }
    elsif ($generation == 0) {
      $vgBezeichnung = $vgReihe - 1;
    }
    else {
      $vgBezeichnung = $vgReihe - $generation;
    }
  }
  return ($vgBezeichnung);
}

##
#
#  Bezeichnung($arg1)
#  Findet zu einem Weg auf dem Ahnentafel die richtige Bezeichnung
#  $arg1 wird als korrekter Weg erwartet (z.B "ooru")
#
###

sub Bezeichnung {
  my $index = $_[0];
  my $bezeichnung;
  my $generation = Generation($index);

  if ($index eq "r") { # Schwester
    return("Schwester");
  }
  elsif ($index =~ /or/ and $generation > 0) { # Tante
    $bezeichnung = _Bezeichnung($generation, "Tante");
  }
  elsif ($index =~ /ru/ and $generation <= 0) { # Cousine oder Nichte
    if ($generation == 0) {
      $bezeichnung = "Cousine";
    }
    else {
      $bezeichnung = _Bezeichnung($generation, "Nichte"); # Ruft die Funktion Bezeichung mit dem Argument "Nichte" und $generation auf.
    }
  }
  elsif ($index =~ /o$/) { # Mutter
    $bezeichnung = _Bezeichnung($generation, "Mutter");
  }
  else { # Tochter
    $bezeichnung = _Bezeichnung($generation, "Tochter", "Enkel"); # Ruft die Funktion Bezeichung mit dem Argument "Nichte", "Enkel" und $generation auf.
  }  

  my $vg = Verwandtschaftsgrad($index);
  $bezeichnung .= abs($vg) > 1 ? " $vg.Grades" : '';

  return ($bezeichnung);
}

##
#
# _Bezeichnung($arg1, $arg2, [$arg3])
# Eine Helferfunktion für Bezeichung, die die grobe erste Bezeichnung 
# mit Hilfe der Generation komplettiert.
# z.B. "or" (oben-rechts) für Tante.
# $arg1 wird als Integer erwartet und bezeichnet die Generation.
# $arg2 wird als Begriff erwartet (z.B. "Tante 2.Grades");
# $arg3 ist optional und wird dann verwendet, wenn im Begriff eine
# andere Bezeichnung als gross verwendet wird (z.B. bei Enkeltochter).
#
##

sub _Bezeichnung {
  my $generation = $_[0];
  my $bezeichnung = lc($_[1]); #Bitte alles in Kleinbuchstaben.
  my $anders = lc($_[2]); # Falls wir eine andere Beizeichnung als gross benötigen.
  my $genNeutral = abs($generation); #Ich möchte gerne positive Zahlen
  if ($genNeutral > 1) { # Nur wenn über oder unter Generation 0
    $bezeichnung = ($anders?$anders:"gross") . $bezeichnung; # Wir fügen gross hinzu
    foreach(1..($genNeutral-2)) { #Für jede Generation über 1 und unter 1 wird ein ur dazugefügt.
      $bezeichnung = "ur" . $bezeichnung;
    }
  }
  $bezeichnung = ucfirst($bezeichnung); # Den ersten Buchstaben bitte gross;
  return ($bezeichnung); #Und den Wert bitte zurückgeben.
}


sub Weg {
  my $bezeichnung = $_[0];

  $bezeichnung =~ /(.*)(mutter|cousine|schwester|nichte|tante|tochter)\s*(\d*)(\.Grades)*/i;
  my $zusatz = $1;
  my $grundBezeichnung = lc($2);
  my $vg = $3?$3:0;

  my $grundWeg = $verwandtschaftIndex{ucfirst($grundBezeichnung)};

  return($grundWeg) if ($grundBezeichnung eq "schwester");

  if ($grundBezeichnung eq "tochter" or $grundBezeichnung eq "nichte") {
    return($grundWeg) unless ($zusatz);
    if ($zusatz) {
      $grundWeg = Regel($grundWeg); #Da Tochter ur ist kann.
      $grundWeg .= "u";
      while ($zusatz =~ /ur/g) { $grundWeg .= "u" }
    }
  }
  elsif ($grundBezeichnung eq "mutter" or $grundBezeichnung eq "tante") {
    return($grundWeg) unless ($zusatz);
    if ($zusatz) {
      $grundWeg = "o" . $grundWeg;
      while ($zusatz =~ /ur/ig) { $grundWeg = "o" . $grundWeg; }
    }
  }

  return($grundWeg) unless ($vg);

  if ($zusatz) {
    $grundWeg .= "u";
    while ($zusatz =~ /ur/g) {
      $grundWeg .= "u";
    }
  }
  if ($vg) {
    foreach(2..$vg) {
      $grundWeg = "o" . $grundWeg . "u";
    }
  } 
  return($grundWeg);
}
