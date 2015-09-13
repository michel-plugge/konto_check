# vi: ft=ruby:set si:set fileencoding=UTF-8

# load the c extension
require 'konto_check_raw'

#This is a C/Ruby library to check the validity of German Bank Account
#Numbers. All currently defined test methods by Deutsche Bundesbank
#(April 2015: 00 to E2) are implemented. 
#
#<b>ATTENTION:</b> There are a few important changes in the API between version 0.0.2 (version
#by Peter Horn/Provideal), version 0.0.6 (jeanmartin) and this version:
#
#* The function KontoCheck::load_bank_data() is no longer used; it is replaced by KontoCheck::init() and KontoCheck::generate_lutfile().
#* The function KontoCheck::konto_check( blz,kto) changed the order of parameters from (kto,blz) to (blz,kto)
#
#Another change affects only the version 0.0.6 by jeanmartin:
#
#* In KontoCheck::init( level,name,set) the order of the two first parameters is now free; the order is determined by the type of the variable (level is integer, filename string). 
#
#Because this class is inteded for german bank accounts, the rest of the
#documentation is in german too.
#
#Diese Bibliothek implementiert die Prüfziffertests für deutsche Bankkonten.
#Die meisten Konten enthalten eine Prüfziffer; mit dieser kann getestet
#werden, ob eine Bankleitzahl plausibel ist oder nicht. Auf diese Weise
#können Zahlendreher oder Zifferverdopplungen oft festgestellt werden. Es ist
#natürlich nicht möglich, zu bestimmen, ob ein Konto wirklich existiert; dazu
#müßte jeweils eine Anfrage bei der Bank gemacht werden ;-).
#
#Die Bibliothek ist in zwei Teile gesplittet: KontoCheckRaw bildet die direkte
#Schnittstelle zur C-Bibliothek und ist daher manchmal etwas sperrig;
#KontoCheck ist dagegen mehr Ruby-artig ausgelegt. KontoCheck gibt meist nur
#eine Teilmenge von KontoCheckRaw zurück, aber (hoffentlich) die Teile, die man
#unmittelbar von den jeweiligen Funktionen erwartet. Eine Reihe einfacher
#Funktionen sind auch in beiden Versionen identisch.
#
#Die Bankleitzahldaten werden in einem eigenen (komprimierten) Format in einer
#sogenannten LUT-Datei gespeichert. Diese Datei läßt sich mit der Funktion
#KontoCheck::generate_lutfile bzw. KontoCheckRaw::generate_lutfile aus der
#Datei der Deutschen Bundesbank (online erhältlich unter
#http://www.bundesbank.de/zahlungsverkehr/zahlungsverkehr_bankleitzahlen_download.php)
#erzeugen. Die LUT-Datei hat den großen Vorteil, daß die Datenblocks (BLZ,
#Prüfziffer, Bankname, Ort, ...) unabhängig voneinander gespeichert sind; jeder
#Block kann für sich geladen werden. In einer Datei können zwei Datensätze der
#Bundesbank mit unterschiedlichem Gültigkeitsdatum enthalten sein. Wenn bei der
#Initialisierung kein bestimmter Datensatz ausgewählt wird, prüft die
#Bibliothek aufgrund des mit jedem Datensatz gespeicherten Gültigkeitszeitraums
#welcher Satz aktuell gültig ist und lädt diesen dann in den Speicher.
#
#Numerische Werte (z.B. Bankleitzahlen, Kontonummern, PLZ,...) können als
#Zahlwerte oder als String angegeben werden; sie werden automatisch
#konvertiert. Prüfziffermethoden können ebenfalls als Zahl oder String
#angegeben werden; die Angabe als Zahl ist allerdings nicht immer eindeutig. So
#kann z.B. 131 sowohl für D1 als auch 13a stehen; daher ist es besser, die
#Prüfziffermethode als String anzugeben (in diesem Beispiel würde 131 als 13a
#interpretiert).

module KontoCheck

#mögliche Suchschlüssel für die Funktion KontoCheck::suche()
#
#:ort, :plz, :pz, :bic, :blz, :namen, :namen_kurz
  SEARCH_KEYS = [:ort, :plz, :pz, :bic, :blz, :namen, :namen_kurz, :regel, :volltext, :multiple]
#Aliasnamen für einige Suchschlüssel der Funktion KontoCheck::suche()
#
#:bankleitzahl, :city, :zip, :name, :kurzname, :shortname, :pruefziffer
  SEARCH_KEY_MAPPINGS = {
    :bankleitzahl => :blz,
    :city         => :ort,
    :zip          => :plz,
    :name         => :namen,
    :kurzname     => :namen_kurz,
    :shortname    => :namen_kurz,
    :pruefziffer  => :pz,
    :regel        => :regel,
    :vt           => :volltext,
    :fulltext     => :volltext,
    :m            => :multiple,
    :x            => :multiple
  }

  class << self

#===KontoCheck::lut_info()
#=====KontoCheckRaw::lut_info( [lutfile])
#=====KontoCheck::lut_info1( lutfile)
#=====KontoCheck::lut_info2( lutfile)
#
#Diese Funktion liefert den Infoblock des Datensatzes zurück, der mittels
#init() in den Speichergeladen wurde. Weitere Infos über die LUT-Datei
#lassen sich mit der Funktion KontoCheckRaw::lut_info() sowie
#KontoCheck::dump_lutfile() erhalten.

    def lut_info()
      KontoCheckRaw::lut_info()[3]
    end

#===KontoCheck::lut_info1( lutfile)
#=====KontoCheck::lut_info()
#=====KontoCheck::lut_info2()
#=====KontoCheckRaw::lut_info()
#
#Diese Funktion liefert den Infoblock des ersten Datensatzes der angegebenen
#LUT-Datei zurück. Weitere Infos über die LUT-Datei lassen sich mit der
#Funktion KontoCheckRaw::lut_info() sowie KontoCheck::dump_lutfile() erhalten.

    def lut_info1(filename)
      KontoCheckRaw::lut_info(filename)[3]
    end

#===KontoCheck::lut_info2( lutfile)
#=====KontoCheck::lut_info()
#=====KontoCheck::lut_info1( lutfile)
#=====KontoCheckRaw::lut_info( [lutfile])
#
#Diese Funktion liefert den Infoblock des zweiten Datensatzes der angegebenen
#LUT-Datei zurück. Weitere Infos über die LUT-Datei lassen sich mit der
#Funktion KontoCheckRaw::lut_info() sowie KontoCheck::dump_lutfile() erhalten.

    def lut_info2(filename)
      KontoCheckRaw::lut_info(filename)[4]
    end


#===KontoCheck::dump_lutfile( lutfile)
#=====KontoCheckRaw::dump_lutfile( lutfile)
#
#Diese Funktion liefert detaillierte Informationen über alle Blocks, die in der
#LUT-Datei gespeichert sind, sowie noch einige Internas der LUT-Datei. Im
#Fehlerfall wird nil zurückgegeben.

    def dump_lutfile(filename)
      KontoCheckRaw::dump_lutfile(filename).first
    end

#===KontoCheck::encoding( [mode])
#=====KontoCheckRaw::encoding( [mode])
#=====KontoCheck::encoding_str( [mode])
#=====KontoCheckRaw::keep_raw_data( mode)
#
#Diese Funktion legt den benutzten Zeichensatz für Fehlermeldungen durch die
#Funktion KontoCheck::retval2txt() und einige Felder der LUT-Datei (Name,
#Kurzname, Ort) fest. Wenn die Funktion nicht aufgerufen wird, wird der Wert
#DEFAULT_ENCODING aus konto_check.h benutzt.
#
#_Achtung_: Das Verhalten der Funktion hängt von dem Flag keep_raw_data der
#C-Bibliothek ab. Falls das Flag gesetzt ist, werden die Rohdaten der Blocks
#Name, Kurzname und Ort im Speicher gehalten; bei einem Wechsel der Kodierung
#wird auch für diese Blocks die Kodierung umgesetzt. Falls das Flag nicht
#gesetzt ist, sollte die Funktion *vor* der Initialisierung aufgerufen werden,
#da in dem Fall die Daten der LUT-Datei nur bei der Initialisierung konvertiert
#werden. Mit der Funktion KontoCheckRaw::keep_raw_data() kann das Flag gesetzt
#oder gelöscht werden.
#
#Für den Parameter mode werden die folgenden Werte akzeptiert (die Strings sind
#nicht case sensitiv; Mi oder mI oder MI ist z.B. auch möglich; wird der
#Parameter nicht angegeben, wird die aktuelle Kodierung ausgegeben):
#
#   0:            aktuelle Kodierung ausgeben
#   1,  'i', 'I': ISO-8859-1
#   2,  'u', 'U': UTF-8
#   3,  'h', 'H': HTML
#   4,  'd', 'D': DOS CP 850
#   51, 'mi':     ISO-8859-1, Makro für Fehlermeldungen
#   52, 'mu':     UTF-8, Makro für Fehlermeldungen
#   53, 'mh':     HTML, Makro für Fehlermeldungen
#   54, 'md':     DOS CP 850, Makro für Fehlermeldungen
#
#Rückgabewert ist die aktuelle Kodierung als Integer (falls zwei Kodierungen
#angegeben sind, ist die erste die der Statusmeldungen, die zweite die der
#LUT-Blocks):
#
#    0:  "noch nicht spezifiziert" (vor der Initialisierung)
#    1:  "ISO-8859-1";
#    2:  "UTF-8";
#    3:  "HTML entities";
#    4:  "DOS CP 850";
#    12: "ISO-8859-1/UTF-8";
#    13: "ISO-8859-1/HTML";
#    14: "ISO-8859-1/DOS CP 850";
#    21: "UTF-8/ISO-8859-1";
#    23: "UTF-8/HTML";
#    24: "UTF-8/DOS CP-850";
#    31: "HTML entities/ISO-8859-1";
#    32: "HTML entities/UTF-8";
#    34: "HTML entities/DOS CP-850";
#    41: "DOS CP-850/ISO-8859-1";
#    42: "DOS CP-850/UTF-8";
#    43: "DOS CP-850/HTML";
#    51: "Makro/ISO-8859-1";
#    52: "Makro/UTF-8";
#    53: "Makro/HTML";
#    54: "Makro/DOS CP 850";

    def encoding(*args)
      KontoCheckRaw::encoding(*args)
    end

#===KontoCheck::pz_aenderungen_enable( set)
#=====KontoCheckRaw::pz_aenderungen_enable( set)
#
# Die Funktion pz_aenderungen_enable() dient dazu, den Status des Flags
# pz_aenderungen_aktivieren abzufragen bzw. zu setzen. Falls die Variable
# set 1 ist, werden die Änderungen aktiviert, falls sie 0 ist, werden die
# Änderungen deaktiviert. Beim Aufruf ohne Parameter oder mit einem anderen
# Wert wird das aktuelle Flag nicht verändert, sondern nur der Status
# zurückgegeben.
#
#====Parameter:
#
# set:           0 oder 1: Änderungen deaktivieren/aktivieren
#                anderer Wert: nur Abfrage des Status
#
#====Rückgabe:
# Rückgabe:      aktueller Status des Flags                                                                                             #

    def pz_aenderungen_enable(*args)
      KontoCheckRaw::pz_aenderungen_enable(*args)
    end

#===KontoCheck::encoding_str( [mode])
#=====KontoCheckRaw::encoding_str( [mode])
#=====KontoCheck::encoding( [mode])
#=====KontoCheckRaw::keep_raw_data( mode)
#
#Diese Funktion entspricht der Funktion KontoCheck::encoding(). Allerdings
#ist der Rückgabewert nicht numerisch, sondern ein String, der die aktuelle
#Kodierung angibt. Die folgenden Rückgabewerte sind möglich (falls zwei
#Kodierungen angegeben sind, ist die erste die der Statusmeldungen, die
#zweite die der LUT-Blocks):
#     
#    "noch nicht spezifiziert" (vor der Initialisierung)
#    "ISO-8859-1";
#    "UTF-8";
#    "HTML entities";
#    "DOS CP 850";
#    "ISO-8859-1/UTF-8";
#    "ISO-8859-1/HTML";
#    "ISO-8859-1/DOS CP 850";
#    "UTF-8/ISO-8859-1";
#    "UTF-8/HTML";
#    "UTF-8/DOS CP-850";
#    "HTML entities/ISO-8859-1";
#    "HTML entities/UTF-8";
#    "HTML entities/DOS CP-850";
#    "DOS CP-850/ISO-8859-1";
#    "DOS CP-850/UTF-8";
#    "DOS CP-850/HTML";
#    "Makro/ISO-8859-1";
#    "Makro/UTF-8";
#    "Makro/HTML";
#    "Makro/DOS CP 850";

    def encoding_str(*args)
      KontoCheckRaw::encoding_str(*args)
    end

#===KontoCheck::retval2txt( retval)
#=====KontoCheckRaw::retval2txt( retval)
#
#Diese Funktion konvertiert einen numerischen Rückgabewert in einen String. Der
#benutzte Zeichensatz wird über die Funktion KontoCheck::encoding() festgelegt.
#Falls diese Funktion nicht aufgerufen wurde, wird der Wert des Makros
#DEFAULT_ENCODING aus konto_check.h benutzt.

    def retval2txt(retval)
      KontoCheckRaw::retval2txt(retval)
    end

#===KontoCheck::retval2iso( retval)
#=====KontoCheckRaw::retval2iso( retval)
#
#Diese Funktion konvertiert einen numerischen Rückgabewert in einen String.
#Der benutzte Zeichensatz ist ISO 8859-1. 

    def retval2iso(retval)
      KontoCheckRaw::retval2iso(retval)
    end

#===KontoCheck::retval2txt_short( retval)
#=====KontoCheckRaw::retval2txt_short( retval)
#=====KontoCheck::retval2txt_kurz( retval)
#
#Diese Funktion konvertiert einen numerischen Rückgabewert in einen kurzen
#String. Die Ausgabe ist der Makroname, wie er in C benutzt wird.

    def retval2txt_short(retval)
      KontoCheckRaw::retval2txt_short(retval)
    end
    alias_method :retval2txt_kurz, :retval2txt_short

#===KontoCheck::retval2txt_kurz( retval)
#=====KontoCheckRaw::retval2txt_short( retval)
#=====KontoCheck::retval2txt_short( retval)
#
#Diese Funktion konvertiert einen numerischen Rückgabewert in einen kurzen
#String. Die Ausgabe ist der Makroname, wie er in C benutzt wird. Die Funktion
#ist ein Alias zu KontoCheck::retval2txt_short().

    def retval2txt_kurz(retval)
      KontoCheckRaw::retval2txt_short(retval)
    end

#===KontoCheck::retval2dos( retval)
#=====KontoCheckRaw::retval2dos( retval)
#
#Diese Funktion konvertiert einen numerischen Rückgabewert in einen String.
#Der benutzte Zeichensatz ist cp850 (DOS).
#
    def retval2dos(retval)
      KontoCheckRaw::retval2dos(retval)
    end

#===KontoCheck::retval2html( retval)
#=====KontoCheckRaw::retval2html( retval)
#
#Diese Funktion konvertiert einen numerischen Rückgabewert in einen String.
#Für Umlaute werden HTML-Entities benutzt.

    def retval2html(retval)
      KontoCheckRaw::retval2html(retval)
    end

#===KontoCheck::retval2utf8( retval)
#=====KontoCheckRaw::retval2utf8( retval)
#
#Diese Funktion konvertiert einen numerischen Rückgabewert in einen String.
#Der benutzte Zeichensatz ist UTF-8.

    def retval2utf8(retval)
      KontoCheckRaw::retval2utf8(retval)
    end

#===KontoCheck::generate_lutfile( inputfile,outputfile [,user_info [,gueltigkeit [,felder [,filialen [,set [,iban_file]]]]]])
#=====KontoCheckRaw::generate_lutfile( inputfile,outputfile [,user_info [,gueltigkeit [,felder [,filialen [,set [,iban_file]]]]]])
#
#Diese Funktion generiert eine neue LUT-Datei aus der BLZ-Datei der Deutschen Bundesbank. Die folgenden
#Parameter werden unterstützt:
#* inputfile: Eingabedatei (Textdatei) der Bundesbank
#* outputfile: Name der Ausgabedatei
#* user_info: Info-String der in die LUT-Datei geschrieben wird (frei wählbar; wird in den Info-Block aufgenommen)
#* gueltigkeit: Gültigkeit des Datensatzes im Format JJJJMMTT-JJJJMMTT. Diese Angabe wird benutzt, um festzustellen, ob ein Datensatz aktuell noch gültig ist.
#* felder: (0-9) Welche Daten aufgenommmen werden sollen (PZ steht in der folgenden Tabelle für Prüfziffer, NAME_NAME_KURZ ist ein Block, der sowohl den Namen als auch den Kurznamen der Bank enthält; dieser läßt sich besser komprimieren als wenn beide Blocks getrennt sind):
#   0. BLZ,PZ
#   1. BLZ,PZ,NAME_KURZ
#   2. BLZ,PZ,NAME_KURZ,BIC
#   3. BLZ,PZ,NAME,PLZ,ORT
#   4. BLZ,PZ,NAME,PLZ,ORT,BIC
#   5. BLZ,PZ,NAME_NAME_KURZ,PLZ,ORT,BIC
#   6. BLZ,PZ,NAME_NAME_KURZ,PLZ,ORT,BIC,NACHFOLGE_BLZ
#   7. BLZ,PZ,NAME_NAME_KURZ,PLZ,ORT,BIC,NACHFOLGE_BLZ,AENDERUNG
#   8. BLZ,PZ,NAME_NAME_KURZ,PLZ,ORT,BIC,NACHFOLGE_BLZ,AENDERUNG,LOESCHUNG
#   9. BLZ,PZ,NAME_NAME_KURZ,PLZ,ORT,BIC,NACHFOLGE_BLZ,AENDERUNG,LOESCHUNG,PAN,NR
#* filialen: (0 oder 1) Flag, ob nur die Daten der Hauptstellen (0) oder auch die der Filialen aufgenommen werden sollen
#* set (0, 1 oder 2): Datensatz-Nummer. Jede LUT-Datei kann zwei Datensätze enthalten. Falls bei der Initialisierung nicht ein bestimmter Datensatz ausgewählt wird, wird derjenige genommen, der (laut Gültigkeitsstring) aktuell gültig ist. Bei 0 wird eine neue LUT-Datei generiert, bei 1 oder 2 wird der entsprechende Datensatz angehängt.
#* iban_blacklist: Datei der Banken, die einer Selbstberechnung des IBAN nicht zugestimmt haben, bzw. von der IBAN-Berechnung ausgeschlossen werden sollen
#
#Mögliche Rückgabewerte:
#
#   -112  (KTO_CHECK_UNSUPPORTED_COMPRESSION) "die notwendige Kompressions-Bibliothek wurden beim Kompilieren nicht eingebunden"
#    -57  (LUT2_GUELTIGKEIT_SWAPPED)   "Im Gültigkeitsdatum sind Anfangs- und Enddatum vertauscht"
#    -56  (LUT2_INVALID_GUELTIGKEIT)   "Das angegebene Gültigkeitsdatum ist ungültig (Soll: JJJJMMTT-JJJJMMTT)"
#    -32  (LUT2_COMPRESS_ERROR)        "Fehler beim Komprimieren eines LUT-Blocks"
#    -31  (LUT2_FILE_CORRUPTED)        "Die LUT-Datei ist korrumpiert"
#    -30  (LUT2_NO_SLOT_FREE)          "Im Inhaltsverzeichnis der LUT-Datei ist kein Slot mehr frei"
#    -15  (INVALID_BLZ_FILE)           "Fehler in der blz.txt Datei (falsche Zeilenlänge)"
#    -11  (FILE_WRITE_ERROR)           "kann Datei nicht schreiben"
#    -10  (FILE_READ_ERROR)            "kann Datei nicht lesen"
#     -9  (ERROR_MALLOC)               "kann keinen Speicher allokieren"
#     -7  (INVALID_LUT_FILE)           "die blz.lut Datei ist inkosistent/ungültig"
#      1  (OK)                         "ok"
#      7  (LUT1_FILE_GENERATED)        "ok; es wurde allerdings eine LUT-Datei im alten Format (1.0/1.1) generiert"

    def generate_lutfile(*args)
      KontoCheckRaw::generate_lutfile(*args)
    end


#===KontoCheck::rebuild_blzfile( inputfile,outputfile,set)
#=====KontoCheckRaw::rebuild_blzfile( inputfile,outputfile,set)
#
#Die Funktion rebuild_blzfile() war ursprünglich als Härtetest für die
#LUT2-Routinen konzipiert: mit ihr lässt sich die BLZ-Datei komplett aus
#einer LUT-Datei neu generieren. Die Funktion ist allerdings auch so
#interessant, so daß sie in alle Ports eingebunden wurde. Die generierte
#BLZ-Datei sollte (bis auf die Sortierung und die vier Testbanken) keinen
#Unterschied zur originalen BLZ-Datei aufweisen.
#
#Falls der Parameter set 1 oder 2 ist, wird als Eingabedatei eine LUT-
#datei erwartet; bei einem set-Parameter von 0 eine Klartextdatei
#(Bundesbankdatei).
#
#Copyright (C) 2014 Michael Plugge <m.plugge@hs-mannheim.de>
#
#====Aufruf:
#retval=KontoCheck::rebuild_blzfile(inputname,outputname,set)
#
#====Parameter:
#
#* inputfile: Eingabedatei (LUT-Datei oder Textdatei der Deutschen Bundesbank)
#* outputfile: Name der Ausgabedatei
#* set: (0, 1 oder 2)
#   0: Die Eingabedatei ist eine Textdatei; es wird eine LUT-Datei generieret und diese wieder zurück umgewandlt.
#   1. Das erste Set der LUT-Datei wird extrahiert
#   2. Das zweite Set der LUT-Datei wird extrahiert
#
#====Rückgabe:
#Rückgabe ist ein skalarer Statuscode, der die folgenden Werte annehmen kann:
#
#====Mögliche Statuscodes:
#  -112  (KTO_CHECK_UNSUPPORTED_COMPRESSION) "die notwendige Kompressions-Bibliothek wurde beim Kompilieren nicht eingebunden"
#   -64  (INIT_FATAL_ERROR)           "Initialisierung fehlgeschlagen (init_wait geblockt)"
#   -57  (LUT2_GUELTIGKEIT_SWAPPED)   "Im Gültigkeitsdatum sind Anfangs- und Enddatum vertauscht"
#   -56  (LUT2_INVALID_GUELTIGKEIT)   "Das angegebene Gültigkeitsdatum ist ungültig (Soll: JJJJMMTT-JJJJMMTT)"
#   -38  (LUT2_PARTIAL_OK)            "es wurden nicht alle Blocks geladen"
#   -36  (LUT2_Z_MEM_ERROR)           "Memory error in den ZLIB-Routinen"
#   -35  (LUT2_Z_DATA_ERROR)          "Datenfehler im komprimierten LUT-Block"
#   -34  (LUT2_BLOCK_NOT_IN_FILE)     "Der Block ist nicht in der LUT-Datei enthalten"
#   -33  (LUT2_DECOMPRESS_ERROR)      "Fehler beim Dekomprimieren eines LUT-Blocks"
#   -32  (LUT2_COMPRESS_ERROR)        "Fehler beim Komprimieren eines LUT-Blocks"
#   -31  (LUT2_FILE_CORRUPTED)        "Die LUT-Datei ist korrumpiert"
#   -20  (LUT_CRC_ERROR)              "Prüfsummenfehler in der blz.lut Datei"
#   -15  (INVALID_BLZ_FILE)           "Fehler in der blz.txt Datei (falsche Zeilenlänge)"
#   -13  (FATAL_ERROR)                "schwerer Fehler im Konto_check-Modul"
#   -11  (FILE_WRITE_ERROR)           "kann Datei nicht schreiben"
#   -10  (FILE_READ_ERROR)            "kann Datei nicht lesen"
#    -9  (ERROR_MALLOC)               "kann keinen Speicher allokieren"
#    -7  (INVALID_LUT_FILE)           "die blz.lut Datei ist inkosistent/ungültig"
#    -6  (NO_LUT_FILE)                "die blz.lut Datei wurde nicht gefunden"
#     1  (OK)                         "ok"

    def rebuild_blzfile(*args)
      KontoCheckRaw::rebuild_blzfile(*args)
    end

#===KontoCheck::init( [p1 [,p2 [,set]]])
#=====KontoCheckRaw::init( [p1 [,p2 [,set]]])
#Die Variablen p1 und p2 stehen für level und lutfile (in beliebiger
#Reihenfolge); die Zuordnung der beiden Parameter erfolgt on the fly durch eine
#Typüberprüfung.
#
#Diese Funktion initialisiert die Bibliothek und lädt die gewünschten
#Datenblocks in den Speicher. Alle Argumente sind optional; in konto_check.h
#werden die Defaultwerte definiert.
#
#Die beiden ersten Parameter sind der Dateiname und der
#Initialisierungslevel. Der Dateiname ist immer als String anzugeben, der
#Initialisierungslevel immer als Zahl, ansonsten wird eine TypeError
#Exception geworfen. Auf diese Weise ist es problemlos möglich festzustellen,
#wie die Parameter p1 und p2 den Variablen lutfile und level zuzuordnen
#sind.
#
#Für die LUT-Datei ist als Defaultwert sowohl für den Pfad als auch den
#Dateinamen eine Liste möglich, die sequenziell abgearbeitet wird; diese wird
#in konto_check.h spezifiziert (Compilerzeit-Konstante der C-Bibliothek). Die
#folgenden Werte sind in der aktuellen konto_check.h definiert:
#
#   DEFAULT_LUT_NAME blz.lut, blz.lut2f, blz.lut2
#   DEFAULT_LUT_PATH ., /usr/local/etc/, /etc/, /usr/local/bin/, /opt/konto_check/ (für nicht-Windows-Systeme)
#   DEFAULT_LUT_PATH ., C:\\, C:\\Programme\\konto_check  (für Windows-Systeme)
#
#Der Defaultwert für level ist ebenfalls in konto_check.h definiert; in der
#aktuellen Version ist er 5. Bei diesem Level werden die Blocks BLZ,
#Prüfziffer, Name, Kurzname, PLZ, Ort und BIC geladen.
#
#Falls der Parameter set nicht angegeben ist, wird versucht, das aktuell
#gültige Set aus dem Systemdatum und dem Gültigkeitszeitraum der in der
#LUT-Datei gespeicherten Sets zu bestimmen.
#
#Hier noch einmal ein Überblick über die Parameter:
#
#* lutfile: die LUT-Datei, mit der initialisiert werden soll
#* level: (0-9) Welche Daten geladen werden sollen (PZ steht in der folgenden Tabelle für Prüfziffer, NAME_NAME_KURZ ist ein Block, der sowohl den Namen als auch den Kurznamen der Bank enthält; dieser läßt sich besser komprimieren als wenn beide Blocks getrennt sind):
#   0. BLZ,PZ
#   1. BLZ,PZ,NAME_KURZ
#   2. BLZ,PZ,NAME_KURZ,BIC
#   3. BLZ,PZ,NAME,PLZ,ORT
#   4. BLZ,PZ,NAME,PLZ,ORT,BIC
#   5. BLZ,PZ,NAME_NAME_KURZ,PLZ,ORT,BIC
#   6. BLZ,PZ,NAME_NAME_KURZ,PLZ,ORT,BIC,NACHFOLGE_BLZ
#   7. BLZ,PZ,NAME_NAME_KURZ,PLZ,ORT,BIC,NACHFOLGE_BLZ,AENDERUNG
#   8. BLZ,PZ,NAME_NAME_KURZ,PLZ,ORT,BIC,NACHFOLGE_BLZ,AENDERUNG,LOESCHUNG
#   9. BLZ,PZ,NAME_NAME_KURZ,PLZ,ORT,BIC,NACHFOLGE_BLZ,AENDERUNG,LOESCHUNG,PAN,NR
#* set (1 oder 2): Datensatz
#
#Mögliche Rückgabewerte:
#
#   -112  (KTO_CHECK_UNSUPPORTED_COMPRESSION) "die notwendige Kompressions-Bibliothek wurden beim Kompilieren nicht eingebunden"
#    -64  (INIT_FATAL_ERROR)        "Initialisierung fehlgeschlagen (init_wait geblockt)"
#    -63  (INCREMENTAL_INIT_NEEDS_INFO)            "Ein inkrementelles Initialisieren benötigt einen Info-Block in der LUT-Datei"
#    -62  (INCREMENTAL_INIT_FROM_DIFFERENT_FILE)   "Ein inkrementelles Initialisieren mit einer anderen LUT-Datei ist nicht möglich"
#    -38  (LUT2_PARTIAL_OK)         "es wurden nicht alle Blocks geladen"
#    -36  (LUT2_Z_MEM_ERROR)        "Memory error in den ZLIB-Routinen"
#    -35  (LUT2_Z_DATA_ERROR)       "Datenfehler im komprimierten LUT-Block"
#    -34  (LUT2_BLOCK_NOT_IN_FILE)  "Der Block ist nicht in der LUT-Datei enthalten"
#    -33  (LUT2_DECOMPRESS_ERROR)   "Fehler beim Dekomprimieren eines LUT-Blocks"
#    -31  (LUT2_FILE_CORRUPTED)     "Die LUT-Datei ist korrumpiert"
#    -20  (LUT_CRC_ERROR)           "Prüfsummenfehler in der blz.lut Datei"
#    -10  (FILE_READ_ERROR)         "kann Datei nicht lesen"
#     -9  (ERROR_MALLOC)            "kann keinen Speicher allokieren"
#     -7  (INVALID_LUT_FILE)        "die blz.lut Datei ist inkosistent/ungültig"
#     -6  (NO_LUT_FILE)             "die blz.lut Datei wurde nicht gefunden"
#
#      1  (OK)                      "ok"
#      6  (LUT1_SET_LOADED)         "Die Datei ist im alten LUT-Format (1.0/1.1)"
#
#Anmerkung: Falls der Statuscode LUT2_PARTIAL_OK ist, waren bei der
#Initialisierung nicht alle Blocks in der LUT-Datei enthalten.

    def init(*args)
      KontoCheckRaw::init(*args)
    end

#===KontoCheck::lut_blocks( )
#=====KontoCheckRaw::lut_blocks1( )
#=====KontoCheckRaw::lut_blocks( mode)
#Die Funktion gibt Auskunft, ob bei der Initialisierung alle angeforderten
#Blocks der LUT-Datei geladen wurden. Die korrespondierende Funktion
#KontoCheckRaw::lut_blocks( mode) gibt noch einige weitere Infos über die
#geladenen Blocks aus.
#
#====Aufruf:
#ret=KontoCheck::lut_blocks( )
#
#====Rückgabe:
#Rückgabe ist ein skalarer Wert, der Information über den Initialisierungsprozess gibt:
#
#* -136  LUT2_BLOCKS_MISSING       "ok, bei der Initialisierung konnten allerdings ein oder mehrere Blocks nicht geladen werden"
#*  -40  LUT2_NOT_INITIALIZED      "die Programmbibliothek wurde noch nicht initialisiert"
#*   -9  ERROR_MALLOC              "kann keinen Speicher allokieren"
#*    1  OK                        "ok"

    def lut_blocks()
      KontoCheckRaw::lut_blocks1()
    end

#===KontoCheck::load_bank_data( datafile)
#=====KontoCheckRaw::load_bank_data( datafile)
#
#Diese Funktion war die alte Initialisierungsroutine für konto_check; es ist
#nun durch die Funktionen KontoCheck::init() und KontoCheck::generate_lutfile()
#ersetzt. Zur Initialisierung  benutzte sie die Textdatei der Deutschen
#Bundesbank und generiertge daraus eine LUT-Datei, die dann von der
#Initialisierungsroutine der C-Bibliothek benutzt wurde.
#
#Die init() Funktion ist wesentlich schneller (7..20 mal so schnell) und hat
#eine Reihe weiterer Vorteile. So ist es z.B. möglich, zwwei Datensätze mit
#unterschiedlichem Gültigkeitszeitraum in einer Datei zu halten und den jeweils
#gültigen Satz automatisch (nach der Systemzeit) auswählen zu lassen. Die
#einzelnen Datenblocks (Bankleitzahlen, Prüfziffermethoden, PLZ, Ort...) sind
#in der LUT-Datei in jeweils unabhängigen Blocks gespeichert und können einzeln
#geladen werden; die Bankdatei von der Deutschen Bundesbank enthält alle Felder
#in einem linearen Format, so daß einzelne Blocks nicht unabhängig von anderen
#geladen werden können.
#
#Die Funktion load_bank_data() wird nur noch als ein schibbolet benutzt, um
#zu testen, ob jemand das alte Interface benutzt. Bei der Routine
#KontoCheck::konto_check() wurde die Reihenfolge der Parameter getauscht, so
#daß man in dem Falle den alten Code umstellen muß.

   def load_bank_data(*args)
      KontoCheckRaw::load_bank_data(*args)
   end

#===KontoCheck::current_lutfile_name()
#=====KontoCheckRaw::current_lutfile_name()
#=====KontoCheck::current_lutfile_set()
#=====KontoCheck::current_init_level()
#
#Diese Funktion bestimmt den Dateinamen der zur Initialisierung benutzten LUT-Datei.

    def current_lutfile_name()
      KontoCheckRaw::current_lutfile_name().first
    end

#===KontoCheck::current_lutfile_set()
#=====KontoCheckRaw::current_lutfile_name()
#=====KontoCheck::current_lutfile_name()
#=====KontoCheck::current_init_level()
#
#Diese Funktion bestimmt das Set der LUT-Datei, das bei der Initialisierung benutzt wurde.

    def current_lutfile_set()
      raw_results = KontoCheckRaw::current_lutfile_name()
      raw_results[1]
    end

#===KontoCheck::current_init_level()
#=====KontoCheckRaw::current_lutfile_name()
#=====KontoCheckRaw::current_lutfile_name()
#=====KontoCheck::current_lutfile_set()
#
#Diese Funktion bestimmt den aktuell benutzten Initialisierungslevel

    def current_init_level()
      raw_results = KontoCheckRaw::current_lutfile_name()
      raw_results[2]
    end

#===KontoCheck::free()
#=====KontoCheckRaw::free()
#Diese Funktion gibt allen allokierten Speicher wieder frei.

    def free()
      KontoCheckRaw::free()
    end

#===KontoCheck::konto_check( blz,kto)
#=====KontoCheckRaw::konto_check( blz,kto)
#=====KontoCheck::valid( blz,kto)
#Test, ob eine BLZ/Konto-Kombination eine gültige Prüfziffer enthält. Die Funktion gibt einen skalaren
#Statuswert zurück, der das Ergebnis der Prüfung enthält. Mögliche Rückgabewerte sind:
#
#   -69  MISSING_PARAMETER       "Bei der Kontoprüfung fehlt ein notwendiger Parameter (BLZ oder Konto)"
#   -40  LUT2_NOT_INITIALIZED    "die Programmbibliothek wurde noch nicht initialisiert"
#        
#   -77  BAV_FALSE               "BAV denkt, das Konto ist falsch (konto_check hält es für richtig)"
#   -29  UNDEFINED_SUBMETHOD     "Die (Unter)Methode ist nicht definiert"
#   -12  INVALID_KTO_LENGTH      "ein Konto muß zwischen 1 und 10 Stellen haben"
#    -5  INVALID_BLZ_LENGTH      "die Bankleitzahl ist nicht achtstellig"
#    -4  INVALID_BLZ             "die Bankleitzahl ist ungültig"
#    -3  INVALID_KTO             "das Konto ist ungültig"
#    -2  NOT_IMPLEMENTED         "die Methode wurde noch nicht implementiert"
#    -1  NOT_DEFINED             "die Methode ist nicht definiert"
#     0  FALSE                   "falsch"
#     1  OK                      "ok"
#     2  OK_NO_CHK               "ok, ohne Prüfung"

    def konto_check(blz,kto)
      KontoCheckRaw::konto_check(blz,kto)
    end

#===KontoCheck::valid( blz,kto)
#=====KontoCheck::konto_check( blz,kto)
#=====KontoCheckRaw::konto_check( blz,kto)
#Dies ist ein Alias für die Funktion KontoCheck::konto_check()

    def valid(blz,kto)
      KontoCheckRaw::konto_check( blz,kto)
    end

#===KontoCheck::konto_check?( blz, kto)
#=====KontoCheck::konto_check( blz,kto)
#=====KontoCheckRaw::konto_check( blz,kto)
#Test, ob eine BLZ/Konto-Kombination eine gültige Prüfziffer enthält. Die
#Funktion gibt einen skalaren Statuswert zurück, der das Ergebnis der Prüfung
#enthält. Mögliche Rückgabewerte sind einfach true und false (convenience
#function für konto_check()).

    def konto_check?(blz,kto)
      KontoCheckRaw::konto_check(blz,kto)>0?true:false
    end

#===KontoCheck::valid?( blz, kto)
#=====KontoCheck::valid( blz, kto)
#=====KontoCheckRaw::konto_check (blz, kto)
#Dies ist einn Alias für die Funktion KontoCheck::konto_check?. Mögliche Rückgabewerte sind true oder false.

    def valid?(blz,kto)
      KontoCheckRaw::konto_check(blz, kto)>0?true:false
    end

#===KontoCheck::konto_check_pz (pz,kto [,blz])
#=====KontoCheckRaw::konto_check_pz (pz,kto [,blz])
#=====KontoCheck::valid_pz (pz,kto [,blz])
#Diese Funktion testet, ob eine gegebene Prüfziffer/Kontonummer-Kombination gültig ist.
#
#Der zusätzliche Parameter blz ist nur für die Verfahren 52, 53, B6 und C0 notwendig; bei
#diesen Verfahren geht die BLZ in die Berechnung der Prüfziffer ein. Bei allen anderen
#Prüfzifferverfahren wird er ignoriert. Wird er bei einem dieser Verfahren nicht angegeben,
#wird stattdessen eine Test-BLZ eingesetzt.
#
#Die Funktion gibt einen skalaren Statuswert zurück, der das Ergebnis der
#Prüfung enthält. Mögliche Rückgabewerte sind:
#
#   -69  (MISSING_PARAMETER)       "bei der Kontoprüfung fehlt ein notwendiger Parameter (BLZ oder Konto)"
#   -40  (LUT2_NOT_INITIALIZED)    "die Programmbibliothek wurde noch nicht initialisiert"
#
#   -77  (BAV_FALSE)               "BAV denkt, das Konto ist falsch (konto_check hält es für richtig)"
#   -29  (UNDEFINED_SUBMETHOD)     "die (Unter)Methode ist nicht definiert"
#   -12  (INVALID_KTO_LENGTH)      "ein Konto muß zwischen 1 und 10 Stellen haben"
#    -3  (INVALID_KTO)             "das Konto ist ungültig"
#    -2  (NOT_IMPLEMENTED)         "die Methode wurde noch nicht implementiert"
#    -1  (NOT_DEFINED)             "die Methode ist nicht definiert"
#     0  (FALSE)                   "falsch"
#     1  (OK)                      "ok"
#     2  (OK_NO_CHK)               "ok, ohne Prüfung"

    def konto_check_pz(*args)
      KontoCheckRaw::konto_check_pz(*args)
    end

#===KontoCheck::konto_check_pz?( pz,kto [,blz])
#=====KontoCheckRaw::konto_check_pz (pz,kto [,blz])
#=====KontoCheck::valid_pz?( pz,kto [,blz])
#Diese Funktion testet, ob eine gegebene Prüfziffer/Kontonummer-Kombination
#gültig ist. Der Rückgabewert dieser Funktion ist true oder false (convenience
#function für KontoCheck::konto_check_pz()).
#
#Der zusätzliche Parameter blz ist nur für die Verfahren 52, 53, B6 und C0 notwendig; bei
#diesen Verfahren geht die BLZ in die Berechnung der Prüfziffer ein. Bei allen anderen
#Prüfzifferverfahren wird er ignoriert. Wird er bei einem dieser Verfahren nicht angegeben,
#wird stattdessen eine Test-BLZ eingesetzt.

    def konto_check_pz?(*args)
      KontoCheckRaw::konto_check_pz(*args)>0?true:false
    end

#===KontoCheck::valid_pz( pz,kto [,blz])
#=====KontoCheck::konto_check_pz( pz,kto [,blz])
#=====KontoCheckRaw::konto_check_pz( pz,kto [,blz])
#Diese Funktion ist ein Alias für KontoCheck::konto_check_pz

    def valid_pz(*args)
      KontoCheckRaw::konto_check_pz(*args)
    end

#===KontoCheck::valid_pz?( pz,kto [,blz])
#=====KontoCheck::valid_pz( pz,kto [,blz])
#=====KontoCheckRaw::konto_check_pz( pz,kto [,blz])
#Diese Funktion ist ein Alias für KontoCheck::konto_check_pz?()

    def valid_pz?(*args)
      KontoCheckRaw::konto_check_pz(*args)>0?true:false
    end

#===KontoCheck::konto_check_regel( blz,kto)
#=====KontoCheck::konto_check_regel?( blz,kto)
#=====KontoCheckRaw::konto_check_regel( blz,kto)
#=====KontoCheckRaw::konto_check_regel_dbg( blz,kto)
#Test, ob eine BLZ/Konto-Kombination eine gültige Prüfziffer enthält. Die Funktion gibt einen skalaren
#Statuswert zurück, der das Ergebnis der Prüfung enthält. Vor dem Test werden die IBAN-Regeln angewendet,
#dadurch werden u.U. Konto und BLZ ersetzt.
#Falls nicht alle für IBAN-Berechnung notwendigen Blocks geladen sind, werden diese automatisch noch
#nachgeladen. Dadurch tauchen hier auch die Rückgabewerte für die Initialisierung auf.
#Mögliche Rückgabewerte sind:
#
#  -135  FALSE_UNTERKONTO_ATTACHED "falsch, es wurde ein Unterkonto hinzugefügt (IBAN-Regel)"
#  -133  BLZ_MARKED_AS_DELETED     "Die BLZ ist in der Bundesbank-Datei als gelöscht markiert und somit ungültig"
#  -128  IBAN_INVALID_RULE         "Die BLZ passt nicht zur angegebenen IBAN-Regel"
#  -127  IBAN_AMBIGUOUS_KTO        "Die Kontonummer ist nicht eindeutig (es gibt mehrere Möglichkeiten)"
#  -125  IBAN_RULE_UNKNOWN         "Die IBAN-Regel ist nicht bekannt"
#  -124  NO_IBAN_CALCULATION       "Für die Bankverbindung ist keine IBAN-Berechnung erlaubt"
#  -112  KTO_CHECK_UNSUPPORTED_COMPRESSION "die notwendige Kompressions-Bibliothek wurden beim Kompilieren nicht eingebunden"
#   -77  BAV_FALSE                 "BAV denkt, das Konto ist falsch (konto_check hält es für richtig)"
#   -69  MISSING_PARAMETER         "Für die aufgerufene Funktion fehlt ein notwendiger Parameter"
#   -64  INIT_FATAL_ERROR          "Initialisierung fehlgeschlagen (init_wait geblockt)"
#   -63  INCREMENTAL_INIT_NEEDS_INFO "Ein inkrementelles Initialisieren benötigt einen Info-Block in der LUT-Datei"
#   -62  INCREMENTAL_INIT_FROM_DIFFERENT_FILE "Ein inkrementelles Initialisieren mit einer anderen LUT-Datei ist nicht möglich"
#   -40  LUT2_NOT_INITIALIZED      "die Programmbibliothek wurde noch nicht initialisiert"
#   -38  LUT2_PARTIAL_OK           "es wurden nicht alle Blocks geladen"
#   -36  LUT2_Z_MEM_ERROR          "Memory error in den ZLIB-Routinen"
#   -35  LUT2_Z_DATA_ERROR         "Datenfehler im komprimierten LUT-Block"
#   -34  LUT2_BLOCK_NOT_IN_FILE    "Der Block ist nicht in der LUT-Datei enthalten"
#   -33  LUT2_DECOMPRESS_ERROR     "Fehler beim Dekomprimieren eines LUT-Blocks"
#   -31  LUT2_FILE_CORRUPTED       "Die LUT-Datei ist korrumpiert"
#   -29  UNDEFINED_SUBMETHOD       "Die (Unter)Methode ist nicht definiert"
#   -20  LUT_CRC_ERROR             "Prüfsummenfehler in der blz.lut Datei"
#   -12  INVALID_KTO_LENGTH        "ein Konto muß zwischen 1 und 10 Stellen haben"
#   -10  FILE_READ_ERROR           "kann Datei nicht lesen"
#    -9  ERROR_MALLOC              "kann keinen Speicher allokieren"
#    -7  INVALID_LUT_FILE          "die blz.lut Datei ist inkosistent/ungültig"
#    -6  NO_LUT_FILE               "die blz.lut Datei wurde nicht gefunden"
#    -5  INVALID_BLZ_LENGTH        "die Bankleitzahl ist nicht achtstellig"
#    -4  INVALID_BLZ               "die Bankleitzahl ist ungültig"
#    -3  INVALID_KTO               "das Konto ist ungültig"
#    -2  NOT_IMPLEMENTED           "die Methode wurde noch nicht implementiert"
#    -1  NOT_DEFINED               "die Methode ist nicht definiert"
#     0  FALSE                     "falsch"
#     1  OK                        "ok"
#     1  OK                        "ok"
#     2  OK_NO_CHK                 "ok, ohne Prüfung"
#     6  LUT1_SET_LOADED           "Die Datei ist im alten LUT-Format (1.0/1.1)"
#    18  OK_KTO_REPLACED           "ok, die Kontonummer wurde allerdings ersetzt"
#    21  OK_IBAN_WITHOUT_KC_TEST   "ok, die Bankverbindung ist (ohne Test) als richtig anzusehen"
#    25  OK_UNTERKONTO_ATTACHED    "ok, es wurde ein (weggelassenes) Unterkonto angefügt"

    def konto_check_regel(blz,kto)
      KontoCheckRaw::konto_check_regel(blz,kto)
    end

#===KontoCheck::konto_check_regel?( blz,kto)
#=====KontoCheck::konto_check_regel( blz,kto)
#=====KontoCheckRaw::konto_check_regel( blz,kto)
#=====KontoCheckRaw::konto_check_regel_dbg( blz,kto)
#Diese Funktion testet, ob eine gegebene Prüfziffer/Kontonummer-Kombination
#gültig ist (mit IBAN-Regeln). Der Rückgabewert dieser Funktion ist nur true
#oder false (convenience function für KontoCheck::konto_check_regel()).

    def konto_check_regel?(*args)
      KontoCheckRaw::konto_check_regel(*args)>0?true:false
    end

#==== KontoCheck::bank_valid( blz [,filiale])
#======KontoCheckRaw::bank_valid( blz [,filiale])
#======KontoCheck::bank_valid?( blz [,filiale])
#Diese Funktion testet, ob eine gegebene BLZ gültig ist. Der Rückgabewert ist ein
#Statuscode mit den unten angegebenen Werten. Falls das Argument filiale auch
#angegeben ist, wird zusätzlich noch getestet, ob eine Filiale mit dem gegebenen
#Index existiert.
#
#Mögliche Rückgabewerte sind:
#
#    -55  (LUT2_INDEX_OUT_OF_RANGE)    "Der Index für die Filiale ist ungültig"
#    -53  (LUT2_BLZ_NOT_INITIALIZED)   "Das Feld BLZ wurde nicht initialisiert"
#     -5  (INVALID_BLZ_LENGTH)         "die Bankleitzahl ist nicht achtstellig"
#     -4  (INVALID_BLZ)                "die Bankleitzahl ist ungültig"
#      1  (OK)                         "ok"

    def bank_valid(*args)
      KontoCheckRaw::bank_valid(*args)
    end

#====KontoCheck::bank_valid?( blz [,filiale])
#======KontoCheckRaw::bank_valid( blz [,filiale])
#======KontoCheck::bank_valid( blz [,filiale])
#Dies ist eine convenience function zu KontoCheck::bank_valid(). Es wird getestet, ob
#die gegebene BLZ (und evl. noch der Filialindex) gültig ist. Der Rückgabewert ist
#nur true oder false.

    def bank_valid?(*args)
      KontoCheckRaw::bank_valid(*args)>0?true:false
    end

#===KontoCheck::bank_filialen( blz)
#=====KontoCheckRaw::bank_filialen(blz)
#
#Diese Funktion liefert die Anzahl Filialen einer Bank (inklusive Hauptstelle).
#Die LUT-Datei muß dazu natürlich mit den Filialdaten generiert sein, sonst
#wird für alle Banken nur 1 zurückgegeben.

    def bank_filialen(*args)
      KontoCheckRaw::bank_filialen(*args).first
    end

#===KontoCheck::bank_name( blz [,filiale])
#=====KontoCheckRaw::bank_name(blz [,filiale])
#
#Diese Funktion liefert den Namen einer Bank, oder nil im Fehlerfall.

    def bank_name(*args)
      KontoCheckRaw::bank_name(*args).first
    end

#===KontoCheck::bank_name_kurz( blz [,filiale])
#=====KontoCheckRaw::bank_name_kurz(blz [,filiale])
#
#Diese Funktion liefert den Kurznamen einer Bank, oder nil im Fehlerfall.

    def bank_name_kurz(*args)
      KontoCheckRaw::bank_name_kurz(*args).first
    end

#===KontoCheck::bank_ort( blz [,filiale])
#=====KontoCheckRaw::bank_ort(blz [,filiale])
#
#Diese Funktion liefert den Ort einer Bank. Falls der Parameter filiale nicht
#angegeben ist, wird der Sitz der Hauptstelle ausgegeben. Im Fehlerfall wird
#für den Ort nil zurückgegeben.

    def bank_ort(*args)
      KontoCheckRaw::bank_ort(*args).first
    end

#===KontoCheck::bank_plz( blz [,filiale])
#=====KontoCheckRaw::bank_plz(blz [,filiale])
#
#Diese Funktion liefert die Postleitzahl einer Bank. Falls der Parameter
#filiale nicht angegeben ist, wird die PLZ der Hauptstelle ausgegeben. Im
#Fehlerfall wird für die PLZ nil zurückgegeben.

    def bank_plz(*args)
      KontoCheckRaw::bank_plz(*args).first
    end

#===KontoCheck::bank_pz( blz)
#=====KontoCheckRaw::bank_pz(blz)
#
#Diese Funktion liefert die Prüfziffer einer Bank. Die Funktion unterstützt
#keine Filialen; zu jeder BLZ kann es in der LUT-Datei nur eine
#Prüfziffermethode geben.

    def bank_pz(blz)
      KontoCheckRaw::bank_pz(blz).first
    end

#===KontoCheck::bank_bic( blz [,filiale])
#=====KontoCheckRaw::bank_bic(blz [,filiale])
#
#Diese Funktion liefert den BIC (Bank Identifier Code) einer Bank. Im
#Fehlerfall wird nil zurückgegeben.

    def bank_bic(*args)
      KontoCheckRaw::bank_bic(*args).first
    end

#===KontoCheck::bank_aenderung( blz [,filiale])
#=====KontoCheckRaw::bank_aenderung(blz [,filiale])
#
#Diese Funktion liefert das  'Änderung' Flag einer Bank (als string). Mögliche
#Werte sind: A (Addition), M (Modified), U (Unchanged), D (Deletion).

    def bank_aenderung(*args)
      KontoCheckRaw::bank_aenderung(*args).first
    end

#===KontoCheck::bank_loeschung( blz [,filiale])
#=====KontoCheckRaw::bank_loeschung(blz [,filiale])
#
#Diese Funktion liefert das Lösch-Flag für eine Bank zurück (als Integer;
#mögliche Werte sind 0 und 1); im Fehlerfall wird nil zurückgegeben.

    def bank_loeschung(*args)
      KontoCheckRaw::bank_loeschung(*args).first
    end

#===KontoCheck::bank_nachfolge_blz( blz [,filiale])
#=====KontoCheckRaw::bank_nachfolge_blz(blz [,filiale])
#Diese Funktion liefert die Nachfolge-BLZ für eine Bank, die gelöscht werden
#soll (bei der das 'Löschung' Flag 1 ist).

    def bank_nachfolge_blz(*args)
      KontoCheckRaw::bank_nachfolge_blz(*args).first
    end

#===KontoCheck::bank_pan( blz [,filiale])
#=====KontoCheckRaw::bank_pan(blz [,filiale])
#
#Diese Funktion liefert den PAN (Primary Account Number) einer Bank.

    def bank_pan(*args)
      KontoCheckRaw::bank_pan(*args).first
    end

#===KontoCheck::bank_nr( blz [,filiale])
#=====KontoCheckRaw::bank_nr(blz [,filiale])
#
#Diese Funktion liefert die laufende Nummer einer Bank (internes Feld der BLZ-Datei). Der Wert
#wird wahrscheinlich nicht oft benötigt, ist aber der Vollständigkeit halber enthalten.

    def bank_nr(*args)
      KontoCheckRaw::bank_nr(*args).first
    end

#===KontoCheck::bank_alles( blz [,filiale])
#=====KontoCheckRaw::bank_alles(blz [,filiale])
#
#Dies ist eine Mammutfunktion, die alle vorhandenen Informationen über eine
#Bank zurückliefert. Das Ergebnis ist ein Array mit den folgenden Komponenten:
#   0:  Statuscode
#   1:  Anzahl Filialen
#   2:  Name
#   3:  Kurzname
#   4:  PLZ
#   5:  Ort
#   6:  PAN
#   7:  BIC
#   8:  Prüfziffer
#   9:  Laufende Nr.
#   10: Änderungs-Flag
#   11: Löeschung-Flag
#   12: Nachfolge-BLZ
#
#Der Statuscode (Element 0) kann folgende Werte annehmen:
#
#    -40  (LUT2_NOT_INITIALIZED)       "die Programmbibliothek wurde noch nicht initialisiert"
#    -38  (LUT2_PARTIAL_OK)            "es wurden nicht alle Blocks geladen"
#     -5  (INVALID_BLZ_LENGTH)         "die Bankleitzahl ist nicht achtstellig"
#     -4  (INVALID_BLZ)                "die Bankleitzahl ist ungültig"
#      1  (OK)                         "ok"
#
#Anmerkung: Falls der Statuscode LUT2_PARTIAL_OK ist, wurden bei der
#Initialisierung nicht alle Blocks geladen (oder es sind nicht alle verfügbar);
#die entsprechenden Elemente haben dann den Wert nil.

    def bank_alles(*args)
      KontoCheckRaw::bank_alles(*args)
    end

#===KontoCheck::iban2bic( iban)
#=====KontoCheckRaw::iban2bic(iban)
#
#Diese Funktion bestimmt zu einer (deutschen!) IBAN den zugehörigen BIC (Bank
#Identifier Code). Der BIC wird für eine EU-Standard-Überweisung im
#SEPA-Verfahren (Single Euro Payments Area) benötigt; für die deutschen Banken
#ist er in der BLZ-Datei enthalten. Nähere Infos gibt es z.B. unter
#http://www.bic-code.de/ .

    def iban2bic(*args)
      KontoCheckRaw::iban2bic(*args).first
    end

#===KontoCheck::ci_check( ci)
#=====KontoCheckRaw::ci_check( ci)
#
#Diese Funktion testet eine Gläubiger-Identifikationsnummer (Credit Identifier, ci)
#
#Mögliche Rückgabewerte sind:
#
#   -146  (INVALID_PARAMETER_TYPE)     "Falscher Parametertyp für die Funktion"
#      0  (FALSE)                      "falsch"
#      1  (OK)                         "ok"

    def ci_check(*args)
      KontoCheckRaw::ci_check(*args)
    end

#===KontoCheck::bic_check( bic)
#=====KontoCheckRaw::bic_check( bic)
#
#Diese Funktion testet die Existenz eines (deutschen) BIC. Die Rückgabe ist ein
#skalarer Wert, der das Testergebnis für den BIC angibt. Der BIC muß mit genau
#8 oder 11 Stellen angegeben werden. Intern wird dabei die Funktion
#lut_suche_bic() verwendet.
#
#Die Funktion arbeitet nur für deutsche Banken, da für andere keine Infos
#vorliegen.
#
#Mögliche Rückgabewerte sind:
#
#   -146  (INVALID_PARAMETER_TYPE)     "Falscher Parametertyp für die Funktion"
#   -145  (BIC_ONLY_GERMAN)            "Es werden nur deutsche BICs unterstützt"
#   -144  (INVALID_BIC_LENGTH)         "Die Länge des BIC muß genau 8 oder 11 Zeichen sein"
#      0  (FALSE)                      "falsch"
#      1  (OK)                         "ok"

    def bic_check(*args)
      KontoCheckRaw::bic_check(*args).first
    end

#===KontoCheck::iban_check( iban)
#=====KontoCheckRaw::iban_check( iban)
#
#Diese Funktion testet einen IBAN. Dabei wird sowohl die Prüfziffer des IBAN
#getestet als auch (bei deutschen Konten) die Prüfziffer der Bankverbindung
#(aus der Kontonummer). Diese Funktion gibt nur den globalen Status zurück;
#bei der Funktion KontoCheckRaw::iban_check() kann man zusätzlich noch den
#Status der Kontenprüfung abfragen.
#
#Mögliche Rückgabewerte sind:
#
#    -67  (IBAN_OK_KTO_NOT)            "Die Prüfziffer der IBAN stimmt, die der Kontonummer nicht"
#    -66  (KTO_OK_IBAN_NOT)            "Die Prüfziffer der Kontonummer stimmt, die der IBAN nicht"
#      0  (FALSE)                      "falsch"
#      1  (OK)                         "ok"

    def iban_check(*args)
      KontoCheckRaw::iban_check(*args).first
    end

#===KontoCheck::iban_gen( kto,blz)
#=====KontoCheckRaw::iban_gen( kto,blz)
#Diese Funktion generiert aus (deutscher) BLZ und Konto einen IBAN.
#
#Nachdem im Mai 2013 die IBAN-Regeln zur Berechnung von IBAN und BIC aus
#Kontonummer und BLZ veröffentlicht wurden, gibt es endlich ein verbindliches
#Verfahren zur Bestimmung der IBAN. Die definierten IBAN-Regeln wurden in der
#C-Datei eingearbeitet und werden automatisch ausgewertet, falls der Block mit
#den IBAN-Regeln in der LUT-Datei enthalten ist. Andere LUT-Dateien sollten
#für die IBAN-Berechnung möglichst nicht verwendet werden, da die Anzahl der
#BLZs mit Sonderregelungen doch sehr groß ist.
#
#Es ist möglich, sowohl die Prüfung auf Stimmigkeit der Kontonummer als auch
#die "schwarze Liste" (ausgeschlossene BLZs) zu deaktivieren. Falls die IBAN
#ohne Test der Blacklist berechnet werden soll, ist vor die BLZ ein @ zu
#setzen; falls auch bei falscher Bankverbindung ein IBAN berechnet werden
#soll, ist vor die BLZ ein + zu setzen. Um beide Prüfungen zu deaktiviern,
#kann @+ (oder +@) vor die BLZ gesetzt werden. Die so erhaltenen IBANs sind
#dann u.U. allerdings wohl nicht gültig.
#
#Rückgabewert ist der generierte IBAN oder nil, falls ein Fehler aufgetreten
#ist. Die genauere Fehlerursache läßt sich mit der Funktion
#KontoCheckRaw::iban_gen() feststellen.
#
#Bei vielen Banken wird die BLZ und damit der BIC ebenfalls ersetzt. Der
#gültige BIC sowie viele andere Werte interessante Werte lassen sich durch die
#Funktion KontoCheckRaw::iban_gen() ermitteln.

    def iban_gen(*args)
      KontoCheckRaw::iban_gen(*args).first
    end

#===KontoCheck::ipi_gen( zweck)
#=====KontoCheckRaw::ipi_gen( zweck)
#
#Diese Funktion generiert einen "Strukturierten Verwendungszweck" für SEPA-Überweisungen.
#Der Rückgabewert ist der Strukturierte Verwendungszweck als String oder nil, falls ein Fehler
#aufgetreten ist.
#
#Der String für den Strukturierten Verwendungszweck darf maximal 18 Byte lang sein und nur
#alphanumerische Zeichen enthalten (also auch keine Umlaute). Die Funktion KontoCheckRaw::ipi_gen()
#gibt einen Statuscode zurück, der etwas nähere Infos im Fehlerfall enthält.

    def ipi_gen(zweck)
      KontoCheckRaw::ipi_gen(zweck).first
    end

#===KontoCheck::ipi_check( zweck)
#=====KontoCheckRaw::ipi_check( zweck)
#
#Die Funktion testet, ob ein Strukturierter Verwendungszweck gültig ist (Anzahl Zeichen, Prüfziffer). Der
#Rückgabewert ist true oder false.

    def ipi_check(zweck)
      KontoCheckRaw::ipi_check(zweck)>0?true:false
    end

#===KontoCheck::suche()
#=====KontoCheck::search()
#=====KontoCheck::SEARCH_KEYS
#=====KontoCheck::SEARCH_KEY_MAPPINGS
#=====KontoCheckRaw::bank_suche_bic(search_bic)
#=====KontoCheckRaw::bank_suche_blz(blz1 [,blz2])
#=====KontoCheckRaw::bank_suche_namen(name)
#=====KontoCheckRaw::bank_suche_namen_kurz(short_name)
#=====KontoCheckRaw::bank_suche_plz(plz1 [,plz2])
#=====KontoCheckRaw::bank_suche_pz(pz1 [,pz2])
#=====KontoCheckRaw::bank_suche_ort(suchort)
#=====KontoCheckRaw::bank_suche_regel(regel1 [,regel2])
#=====KontoCheckRaw::bank_suche_volltext(suchwort)
#=====KontoCheckRaw::bank_suche_multiple(suchworte)
#
#Diese Funktion sucht alle Banken, die auf bestimmte Suchmuster passen.
#Mit dem Schlüssel multiple ist auch eine Suche nach mehreren Kriterien
#möglich; näheres findet sich in der Beschreibung von
#KontoCheckRaw::bank_suche_multiple().
#
#Eine Suche ist möglich nach den Schlüsseln BIC, Bankleitzahl, Postleitzahl,
#Prüfziffer, Ort, Name oder Kurzname oder Volltext. Bei den alphanumerischen
#Feldern (BIC, Ort, Name, Kurzname) ist der Suchschlüssel der Wortanfang des zu
#suchenden Feldes (ohne Unterscheidung zwischen Groß- und Kleinschreibung); bei
#den numerischen Feldern (BLZ, PLZ, Prüfziffer) ist die Suche nach einem
#bestimmten Wert oder nach einem Wertebereich möglich; dieser wird dann
#angegeben als Array mit zwei Elementen. Der Rückgabewert ist jeweils ein Array
#mit den Bankleitzahlen, oder nil falls die Suche fehlschlug. Die Ursache für
#eine fehlgeschlagene Suche läßt sich nur mit den Funktionen der KontoCheckRaw
#Bibliothek näher lokalisieren.
#
#Die Funktion KontoCheck::search() ist ein Alias für die Funktion
#KontoCheck::suche().
#
#Die möglichen Suchschlüssel sind in den Variablen KontoCheck::SEARCH_KEYS
#definiert; in der Variablen KontoCheck::SEARCH_KEY_MAPPINGS finden sich noch
#einige Aliasdefinitionen zu den Suchschlüsseln.
#
#Für das Suchkommando von KontoCheckRaw::bank_suche_multiple() gibt es die Alias-
#Varianten cmd, such_cmd und search_cmd.
#
#Bei allen Suchfeldern wird noch die Option :uniq=>[01] unterstützt. Bei uniq==0
#werden alle gefundenen Zweigstellen ausgegeben, bei uniq==1 nur jeweils die
#erste gefundene Zweigstelle. Das Schlüsselwort ist in allen Suchfunktionen
#vorhanden; in der C-Bibliothek ist es nur für lut_suche_multiple() implementiert.
#
#Hier einige Beispiele möglicher Suchaufrufe:
#
#   s=KontoCheck::suche( :blz => [13051172,13070172] )        BLZ-Bereich
#   s=KontoCheck::suche( :blz => [13051172,13070172,333] )    überzählige Array-Elemente werden ignoriert
#   s=KontoCheck::suche( :bic => 'genodef1wi' )   BIC Teilstring
#   s=KontoCheck::suche( :plz => [68100,68200] )  PLZ-Bereich
#   s=KontoCheck::suche( :pz => 90 )              Prüfziffer numerisch
#   s=KontoCheck::suche( :pz => '90' )            Prüfziffer als String
#   s=KontoCheck::suche( :pz => ['95',98] )       Prüfzifferbereich gemischt String/numerisch auch möglich
#   s=KontoCheck::suche( :regel => [20,25] )      IBAN-Regeln
#   s=KontoCheck::suche( :name => 'postbank' ) 
#   s=KontoCheck::suche( :ort => 'lingenfeld' )
#   r=KontoCheck::suche( :volltext=>'südwest',:uniq=>1)      Volltextsuche mit uniq
#   s=KontoCheck::suche( :multiple=>'deutsche bank mannheim y:sparda x:südwest',:uniq=>1, :cmd=>'ac+xy')
#        Suche nach mehreren Kriterien: Deutsche Bank in Mannheim oder Sparda Südwest
#   r=KontoCheck::suche( :multiple=>'deutsche bank mannheim sparda mainz', :cmd=>'abc+de')
#        nochmal dasselbe, nur Sparda in Mainz


    def suche(options={})
      search_cmd=value=key=""
      sort=uniq=1
      options.each{ |k,v|
         uniq=v if k.to_s=="uniq"
         sort=v if k.to_s=="sort"
         search_cmd=v if k.to_s=="such_cmd" or k.to_s=="search_cmd" or k.to_s=="cmd"
         if  SEARCH_KEYS.include?(k)
            key=k
            value=options[k]
         end
         if  SEARCH_KEY_MAPPINGS.keys.include?(k)
            key=SEARCH_KEY_MAPPINGS[k]
            value=options[k]
         end
      }
      raise 'no valid search key found' if key.length==0
      uniq=2 if uniq>0              # sortieren und uniq
      uniq=1 if sort>0 && uniq==0   # nur sortieren
      raw_results = KontoCheckRaw::send("bank_suche_#{key}",value,search_cmd,uniq)
      raw_results[1]
    end
    alias_method :search, :suche

#===KontoCheck::bank_suche_bic( search_bic [,sort_uniq [,sort]])
#=====KontoCheckRaw::bank_suche_bic( search_bic [,sort_uniq [,sort]])
#=====KontoCheck::suche()
#
#Diese Funktion sucht alle Banken, deren BIC mit dem angegebenen Wert <search_bic> beginnen.
#Die Rückgabe ist ein Array mit den Bankleitzahlen, die auf das Suchmuster passen.

    def bank_suche_bic(*args)
      KontoCheckRaw::bank_suche_bic(*args)[1]
    end


#===KontoCheck::bank_suche_namen( name [,sort_uniq [,sort]])
#===KontoCheckRaw::bank_suche_namen( name [,sort_uniq [,sort]])
#=====KontoCheck::suche()
#
#Diese Funktion sucht alle Banken, deren Namen mit dem angegebenen Wert <name> beginnen.
#Die Rückgabe ist ein Array mit den Bankleitzahlen, die auf das Suchmuster passen.

    def bank_suche_namen(*args)
      KontoCheckRaw::bank_suche_namen(*args)[1]
    end


#===KontoCheck::bank_suche_namen_kurz( name [,sort_uniq [,sort]])
#===KontoCheckRaw::bank_suche_namen_kurz( name [,sort_uniq [,sort]])
#=====KontoCheck::suche()
#
#Diese Funktion sucht alle Banken, deren Kurznamen mit dem angegebenen Wert <name> beginnen.
#Die Rückgabe ist ein Array mit den Bankleitzahlen, die auf das Suchmuster passen.

    def bank_suche_namen_kurz(*args)
      KontoCheckRaw::bank_suche_namen_kurz(*args)[1]
    end


#===KontoCheck::bank_suche_ort( ort [,sort_uniq [,sort]])
#===KontoCheckRaw::bank_suche_ort( ort [,sort_uniq [,sort]])
#=====KontoCheck::suche()
#
#Diese Funktion sucht alle Banken, deren Sitz mit dem angegebenen Wert <ort> beginnen.
#Die Rückgabe ist ein Array mit den Bankleitzahlen, die auf das Suchmuster passen.

    def bank_suche_ort(*args)
      KontoCheckRaw::bank_suche_ort(*args)[1]
    end


#===KontoCheck::bank_suche_blz( blz1 [,blz2 [,sort_uniq [,sort]]])
#=====KontoCheckRaw::bank_suche_blz( blz1 [,blz2 [,sort_uniq [,sort]]])
#=====KontoCheck::suche()
#
#Diese Funktion sucht alle Banken, deren BLZ gleich <blz1> ist oder (bei
#Angabe von blz2) die im Bereich zwischen <blz1> und <blz2> liegen. Die
#Rückgabe ist ein Array mit den Bankleitzahlen, die auf das Suchmuster passen.

    def bank_suche_blz(*args)
      KontoCheckRaw::bank_suche_blz(*args)[1]
    end


#===KontoCheck::bank_suche_plz( plz1 [,plz2 [,sort_uniq [,sort]]])
#=====KontoCheckRaw::bank_suche_plz( plz1 [,plz2 [,sort_uniq [,sort]]])
#=====KontoCheck::suche()
#
#Diese Funktion sucht alle Banken, deren PLZ gleich <plz1> ist oder (bei
#Angabe von plz2) die im Bereich zwischen <plz1> und <plz2> liegen. Die
#Rückgabe ist ein Array mit den Bankleitzahlen, die auf das Suchmuster passen.

    def bank_suche_plz(*args)
      KontoCheckRaw::bank_suche_plz(*args)[1]
    end


#===KontoCheck::bank_suche_pz( pz1 [,pz2 [,sort_uniq [,sort]]])
#=====KontoCheckRaw::bank_suche_pz( pz1 [,pz2 [,sort_uniq [,sort]]])
#=====KontoCheck::suche()
#
#Diese Funktion sucht alle Banken, deren Prüfziffer gleich <pz1> ist oder (bei
#Angabe von pz2) die im Bereich zwischen <pz1> und <pz2> liegen. Die Rückgabe
#ist ein Array mit den Bankleitzahlen, die auf das Suchmuster passen.

    def bank_suche_pz(*args)
      KontoCheckRaw::bank_suche_pl(*args)[1]
    end


#===KontoCheck::bank_suche_regel( regel1 [,regel2 [,sort_uniq [,sort]]])
#=====KontoCheckRaw::bank_suche_regel( regel1 [,regel2 [,sort_uniq [,sort]]])
#=====KontoCheck::suche()
#
#Diese Funktion sucht alle Banken, deren IBAN-Regel gleich <regel1> ist oder (bei
#Angabe von regel2) die im Bereich zwischen <regel1> und <regel2> liegen. Die Rückgabe
#ist ein Array mit den Bankleitzahlen, die auf das Suchmuster passen.

    def bank_suche_regel(*args)
      KontoCheckRaw::bank_suche_regel(*args)[1]
    end


#===KontoCheck::bank_suche_volltext( suchwort [,sort_uniq [,sort]])
#=====KontoCheckRaw::bank_suche_volltext( suchwort [,sort_uniq [,sort]])
#=====KontoCheck::suche()
#
#Diese Funktion sucht alle Banken, bei denen in Name, Kurzname oder Ort das
#angegebenen Wort <suchwort> vorkommt. Dabei wird immer nur ein einziges Wort
#gesucht; mehrere Worte führen zu einer Fehlermeldung in der KontoCheckRaw-
#Bibliothek. Eine solche Suche läßt sich durch die Funktion
#KontoCheck::bank_suche_multiple( ) bewerkstelligen. Die Rückgabe ist ein Array
#mit den Bankleitzahlen, die auf das Suchmuster passen.

    def bank_suche_volltext(*args)
      KontoCheckRaw::bank_suche_volltext(*args)[1]
    end


#===KontoCheck::bank_suche_multiple( suchtext [,such_cmd] [,uniq])
#===KontoCheckRaw::bank_suche_multiple( suchtext [,such_cmd] [,uniq])
#=====KontoCheck::suche()
#
#Diese Funktion sucht alle Banken, die mehreren Kriterien entsprechen. Dabei
#können bis zu 26 Teilsuchen definiert werden, die beliebig miteinander
#verknüpft werden können (additiv, subtraktiv und multiplikativ). Eine nähere
#Beschreibung der Funktion und der Parameter findet sich unter
#KontoCheckRaw::bank_suche_multiple( ). Die Rückgabe ist ein Array
#mit den Bankleitzahlen, die auf das Suchmuster passen.

#
#====Aufruf:
#result=bank_suche_multiple(such_string [,such_cmd] [,uniq])

    def bank_suche_multiple(*args)
      KontoCheckRaw::bank_suche_multiple(*args)[1]
    end



#===KontoCheck::version( [mode] )
#=====KontoCheckRaw::version( [mode] )
#Diese Funktion gibt die Versions-Infos der C-Bibliothek zurück.
#
#====Mögliche Werte für mode:
#* 0 bzw. ohne Parameter: Versionsstring der C-Bibliothek
#* 1: Versionsnummer
#* 2: Versionsdatum
#* 3: Compilerdatum und -zeit
#* 4: Datum der Prüfziffermethoden
#* 5: Datum der IBAN-Regeln
#* 6: Klartext-Datum der Bibliotheksversion
#* 7: Versionstyp (devel, beta, final)

    def version(*args)
      KontoCheckRaw::version(*args)
    end

  end

end
