use strict;
use warnings;

print "Welche Bezeichnung suchst du?";

my $stdin = <STDIN>;

print $stdin;

$stdin = "Tochter der Tochter der Tochter der Tochter der Tochter der Tochter der Tochter der Schwester der Mutter meiner Mutter";

my %verwandtschaftIndex = ( 					
				Mutter => "o",
				Tochter => "ur",
				Schwester => "r",
				Nichte => "ru", 
				Tante => "or",
				Cousine => "oru", 
			);
			        
# Index umkehren
my %indexReversed;
foreach (keys %verwandtschaftIndex) {
  $indexReversed{$verwandtschaftIndex{$_}} = $_;
}

#Feststellen der Verwandtschaft von hinten nach vorne
#Format: Mutter der Mutter meiner Mutter

my @aufgespaltet =  $stdin =~ /(mutter|tochter|schwester)/ig;

print "@aufgespaltet\n";

my $index;

foreach (reverse(@aufgespaltet)) {
  $index .= $verwandtschaftIndex{ucfirst($_)};
}

print "Index vor Regelanwendung: $index\n";

# Regeln anwenden
# ou wird gelöscht, da es sich aufhebt.
while ($index =~ s/ou|uo//) {}; #ACHTUNG! z.B. oouu wird nicht gelöscht!
# ro wird durch r ersetzt, da Geschwister die gleichen Eltern haben.
$index =~ s/ro/o/g;
# rr wird durch r ersetzt, da z.B. die Schwester der Schwester meiner Tante
# auch meine Tante ist.
$index =~ s/rr/r/g;
# Nach dem ersten r werden alle r gelöscht.
while ($index =~ s/(o*?)r(.*?)r(.*)/$1r$2$3/) {}; 

print "Index nach Regelanwendung: $index\n";

# Generation bestimmen
my $countO = () = $index =~ /o/g; # Alle o's zählen
my $countU = () = $index =~ /u/g; # Alle u's zählen

my $generation = $countO - $countU; # Und die Differenz berechnen.

print "O\'s: $countO U\'s: $countU\n";

print "Generation: $generation.Generation.\n";

# Verwandtschaftsgrad bestimmen
# Nur wenn $index ein r enthält, sonst $countO + 1 = $verwandtschaftsgrad
my $verwandtschaftsgradReihe = 0; # Bezeichnet den Verwandtschaftsgrad in der Reihe (siehe Übungsblatt).
my $verwandtschaftsgradBezeichnung = 0; # Bezeichnet den Verwandtschaftsgrad in der Bezeichnung also z.B. das "2.Grades".
if ($index =~ /r/) { 
	$verwandtschaftsgradReihe = $countO + 1; 
        if ($generation < 0) {
		$verwandtschaftsgradBezeichnung = $verwandtschaftsgradReihe;
	}
	elsif ($generation == 0) {
		$verwandtschaftsgradBezeichnung = $verwandtschaftsgradReihe - 1;
	}
	else {
		$verwandtschaftsgradBezeichnung = $verwandtschaftsgradReihe - $generation;
	}
}

print "Verwandtschaftsgrad Reihe: $verwandtschaftsgradReihe Bezeichung: $verwandtschaftsgradBezeichnung.Grades.\n";

# Richtige Bezeichnungen suchen
my $bezeichnung;
if ($index eq "r") { # Schwester
  $bezeichnung = "Schwester";
}
elsif ($index =~ /or/ and $generation > 0) { # Tante
    $bezeichnung = Bezeichnung($generation, "Tante");
}
elsif ($index =~ /ru/ and $generation <= 0) { # Cousine oder Nichte
  if ($generation == 0) {
    $bezeichnung = "Cousine";
  }
  else {
    $bezeichnung = Bezeichnung($generation, "Nichte"); # Ruft die Funktion Bezeichung mit dem Argument "Nichte" und $generation auf.
  }
}
elsif ($index =~ /o$/) { # Mutter
    $bezeichnung = Bezeichnung($generation, "Mutter");
}
else { # Tochter
    $bezeichnung = Bezeichnung($generation, "Tochter", "Enkel"); # Ruft die Funktion Bezeichung mit dem Argument "Nichte", "Enkel" und $generation auf.
}

print "Bezeichnung: $bezeichnung";
print " $verwandtschaftsgradBezeichnung.Grades" if ($verwandtschaftsgradBezeichnung > 1);
print "\n";

sub Bezeichnung {
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
