##
#
# verwandt3.pl
#
# perl verwandt3.pl ARGUMENT
# ARGUMENT in der Form: "Tochter des Vaters meiner Mutter"
# verlangt.
#
##

use strict;
use warnings;

#Argument einlesen
my $stdin = $ARGV[0];

#Falls kein Argument vorhanden, dann abbrechen und Meldung ausgeben.
unless ($ARGV[0]) {
  print "Argument fehlt! Keine Auswertung möglich.\n";
  exit;
}

my $breakpoint = -1; #Zur Bestimmung der Eindeutigkeit eines Resultats

#Umwandlungstabellen erstellen
my %mw = ( 	Mutter => "Vater",
		Tochter => "Sohn",
		Schwester => "Bruder",
		Nichte => "Neffe",
		Tante => "Onkel",
		Cousine => "Cousin",
	);


my %verwandtschaftIndex = ( 					
				Mutter => "o",
				Tochter => "ur",
				Schwester => "r",
				Nichte => "ru", 
				Tante => "or",
				Cousine => "oru", 
			);

#Geschlecht bestimmen.
my $geschlecht;
$stdin =~ /^(?:ur)*(?:gross|enkel)*(.*?)(\s|$)/i;
if (defined $verwandtschaftIndex{ucfirst(lc($1))}) { $geschlecht = "w"; }
else { $geschlecht = "m" }

#Begrifflichkeiten auf weiblich ändern (1. s könnten bei eq gefährlich
#werden, 2. weniger schreibarbeit)
$stdin =~ s/vater(s)*/mutter/gi;
$stdin =~ s/bruder(s)*/schwester/gi;
$stdin =~ s/sohn(es)*/tochter/gi;
$stdin =~ s/neffe(n)*/nichte/gi;
$stdin =~ s/onkel(s)*/tante/gi;
$stdin =~ s/cousin(s)* /cousine /gi;

#Feststellen der Verwandtschaft von hinten nach vorne
my @aufgespaltet =  $stdin =~ /(cousine(?:\s\d+\.Grades)*|\w*tante(?:\s\d+\.Grades)*|\w*nichte(?:\s\d+\.Grades)*|\w*mutter|\w*tochter|schwester)/ig;

# Weg bestimmen.
my $index;
foreach (reverse(@aufgespaltet)) {
  my $weg = Weg(lc($_));
  eindeutig($index, $weg);
  $index .= $weg;
  $index = Regel($index) unless ($index eq "ur");
}

#Aus dem Weg die Bezeichnung erstellen.
my $bezeichnung = Bezeichnung($index);

# Richtiges Geschlecht bestimmen. Die Notation stimmt schon, wenn das Geschlecht
# weiblich ist, deshalb wird es nur verändert wenn $geschlecht == "m"

if ($geschlecht eq "m" and not($bezeichnung eq "DU")) {
  $bezeichnung =~ /^(?:ur)*(?:gross|enkel)*(.*?)(\s|$)/i;
  my $bez = $1;
  my $ers = lc($mw{ucfirst(lc($bez))});
  $bezeichnung =~ s/$bez/$ers/;
  $bezeichnung = ucfirst($bezeichnung);
}

#Eindeutigkeit überprüfen und bei Uneindeutigkeit alle Varianten ausgeben.

if ($breakpoint > -1) {
  print "Kein eindeutiges Resultat möglich!\n";
  my @verwandte = findeVerwandteLinks($index);
  print "Möglichkeiten: " . join(", ", @verwandte) . "\n";
}
else {
  print "$bezeichnung\n";
}

###
# 
# findeVerwandteLinks($arg1, $arg2)
# Findet alle Verwandten links aus der gleichen
# Generation, der angegebenen Person.
# $arg[0] verlangt einen Weg auf der Ahnentafel
# (keine Bezeichnung!).
#
###

sub findeVerwandteLinks {
  my $index = $_[0];
  my @verwandte;

  push @verwandte, Bezeichnung($index);
  while ($index =~ /^o/ and $index =~ /u$/) {
    $index =~ s/u//;
    $index =~ s/o//;    
    push @verwandte, Bezeichnung($index);
  }
  $index =~ s/r//;
  push @verwandte, Bezeichnung($index);

  return(@verwandte);
}

###
# 
# eindeutig($arg1, $arg2)
# Überprüft, ob ein beim Hinzufügen eines neuen Weges 
# Uneindeutigkeiten entstehen. Falls der Weg
# nicht eindeutig ist, wird in $breakpoint die
# Generation, ab welcher sie entsteht, abgespeichrt.
# $arg1 verlangt den ursprünglichen Weg. $arg2
# verlangt den Weg, welcher dazugefügt wird.
#
###

sub eindeutig  {
  my $indexStart = $_[0];
  my $indexPlus = $_[1];
  return(1) unless (defined $indexStart);
  my $index = $indexStart . $indexPlus;

  my @generationStart = Generation($indexStart); 
  my @generationPlus = Generation($indexPlus);
  my @generation = Generation($index);

  if ($generation[0] >= 0 and $index =~ /ou/) { # "Tochter der Mutter-Problem" 
	  $breakpoint = $generationStart[0]-1;
  }
  elsif ($indexPlus =~ /r/ and $generationStart[2] != 0 and $generationStart[2] == $generationPlus[1]) { #Schwester der Tante-Problem!
	  $breakpoint = $generationStart[1];
  }
  elsif ($index =~ /rr/) { #"Schwester der Schwester Problem!
	  $breakpoint = $generationStart[1];
  }

  if ($breakpoint > -1 and $generation[0] > $breakpoint) {
	  $breakpoint = -1;
  }
  
  return(1);
}

###
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

  # ro wird durch r ersetzt, da Geschwister die gleichen Eltern haben.
  # In manchen Fällen kann es vorkommen, dass ein ro nach dem entfernen
  # von ou und uo stehen bleibt. Deshalb die Wiederholung.
  $index =~ s/ro/o/;

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
# Gibt im Listenkontext die Generation, die Anzahl os 
# und Anzahl us als zurück. Im skalaren Kontext nur
# die Generation.
#
##

sub Generation {

  my $index = $_[0];
  
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
  my ($generation, $countO, $countU)  = Generation($index);
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
  return wantarray ? ($vgBezeichnung, $vgReihe) : $vgBezeichnung;
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

  if ($index eq "") {
    return("DU");
  }
  elsif ($index eq "r") { # Schwester
    return("Schwester");
  }
  elsif ($index =~ /or/ and $generation > 0) { # Tante
    $bezeichnung = _Bezeichnung($generation, "Tante");
  }
  elsif ($index =~ /ru/ and $generation <= 0) { # Cousine oder Nichte
    if ($generation == 0) {
      $bezeichnung = "Cousine";
    }
    else { # Nichte
      $bezeichnung = _Bezeichnung($generation, "Nichte"); 
    }
  }
  elsif ($index =~ /o$/) { # Mutter
    $bezeichnung = _Bezeichnung($generation, "Mutter");
  }
  else { # Tochter
    $bezeichnung = _Bezeichnung($generation, "Tochter", "Enkel"); 
  }  

  my $vg = Verwandtschaftsgrad($index);
  $bezeichnung .= abs($vg) > 1 ? " $vg.Grades" : ''; 

  return ($bezeichnung);
}

###
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
###

sub _Bezeichnung {
  my $generation = $_[0];
  my $bezeichnung = lc($_[1]);
  my $anders = lc($_[2]);
  my $genNeutral = abs($generation);
  if ($genNeutral > 1) {
    $bezeichnung = ($anders?$anders:"gross") . $bezeichnung;
    foreach(1..($genNeutral-2)) {
      $bezeichnung = "ur" . $bezeichnung;
    }
  }
  $bezeichnung = ucfirst($bezeichnung);
  return ($bezeichnung);
}

###
#
# Weg($arg1)
# Findet zu einer Bezeichnung den kürzesten Weg auf der
# Ahnentafel.
# $arg[0] wird als Bezeichnung eines Verwandten erwartet,
# z.B. Grossonkel.
#
###

sub Weg {
  my $bezeichnung = $_[0];

  $bezeichnung =~ /(.*)(mutter|cousine|schwester|nichte|tante|tochter)\s*(\d*)(\.Grades)*/i;
  my $zusatz = $1;
  my $grundBezeichnung = lc($2);
  my $vg = $3?$3:0;

  my $grundWeg = $verwandtschaftIndex{ucfirst($grundBezeichnung)};

  return($grundWeg) if ($grundBezeichnung eq "schwester");

  if (		$grundBezeichnung eq "tochter" 
	     or $grundBezeichnung eq "nichte" ) {
    if ($zusatz) {
      $grundWeg = Regel($grundWeg); #Da Tochter ur ist kann.
      $grundWeg .= "u";
      while ($zusatz =~ /ur/g) { $grundWeg .= "u" }
      $grundWeg .= "r" if ($grundBezeichnung eq "tochter");
    }
  }
  elsif ($grundBezeichnung eq "mutter" or $grundBezeichnung eq "tante") {
    if ($zusatz) {
      $grundWeg = "o" . $grundWeg;
      while ($zusatz =~ /ur/ig) { $grundWeg = "o" . $grundWeg; }
    }
  }

  return($grundWeg) unless ($vg);

  if ($vg) {
    foreach(2..$vg) {
      $grundWeg = "o" . $grundWeg . "u";
    }
  } 
  return($grundWeg);
}
