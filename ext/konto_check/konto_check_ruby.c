/*==================================================================
 *
 * KontoCheck Module, C Ruby Extension
 *
 * Copyright (c) 2010 Provideal Systems GmbH
 *
 * Peter Horn, peter.horn@provideal.net
 *
 * some extensions by Michael Plugge, m.plugge@hs-mannheim.de
 *
 * ------------------------------------------------------------------
 *
 * ACKNOWLEDGEMENT
 *
 * This module is entirely based on the C library konto_check
 * http://www.informatik.hs-mannheim.de/konto_check/
 * http://sourceforge.net/projects/kontocheck/
 * by Michael Plugge.
 *
 * ------------------------------------------------------------------
 *
 * LICENCE
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or (at your
 * option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

// Include the Ruby headers and goodies
#include "ruby.h"
#include <stdio.h>
#include "konto_check.h"

   /* some Ruby 1.8/1.9 compatibility definitions */
#ifndef RSTRING_PTR
#define RSTRING_LEN(x) (RSTRING(x)->len)
#define RSTRING_PTR(x) (RSTRING(x)->ptr)
#endif

#ifndef RUBY_T_STRING
#define RUBY_T_STRING T_STRING
#define RUBY_T_FLOAT  T_FLOAT
#define RUBY_T_FIXNUM T_FIXNUM
#define RUBY_T_BIGNUM T_BIGNUM
#endif

#define RUNTIME_ERROR(error) do{ \
   snprintf(error_msg,511,"init: %s %s",kto_check_retval2txt_short(error),kto_check_retval2txt(error)); \
   rb_raise(rb_eRuntimeError,error_msg); \
}while(0)

// Defining a space for information and references about the module to be stored internally
VALUE KontoCheck = Qnil;

/**
 * get_params_file()
 *
 * extract params from argc/argv (filename and sometimes optional parameters)
 */
static void get_params_file(int argc,VALUE* argv,char *arg1s,int *arg1i,int *arg2i,int opts)
{
   int len;
   VALUE v1_rb,v2_rb,v3_rb;

   switch(opts){
      case 1:  /* ein Dateiname, zwei Integer; alle optional (für lut_init) */
         rb_scan_args(argc,argv,"03",&v1_rb,&v2_rb,&v3_rb);
         if(NIL_P(v2_rb))  /* Level */
            *arg1i=DEFAULT_INIT_LEVEL;
         else
            *arg1i=NUM2INT(v2_rb);
         if(NIL_P(v3_rb))  /* Set */
            *arg2i=0;
         else
            *arg2i=NUM2INT(v3_rb);
         break;

      case 2:  /* ein Dateiname (für dump_lutfile) */
         rb_scan_args(argc,argv,"10",&v1_rb);
         break;

      case 3:  /* ein optionaler Dateiname (für lut_info) */
         rb_scan_args(argc,argv,"01",&v1_rb);
         break;

      default:
         break;
   }
   if(NIL_P(v1_rb)){    /* Leerstring zurückgeben => Defaultwerte probieren */
      *arg1s=0;
   }
   else if(TYPE(v1_rb)==RUBY_T_STRING){
      strncpy(arg1s,RSTRING_PTR(v1_rb),FILENAME_MAX);
         /* der Ruby-String ist nicht notwendig null-terminiert; manuell erledigen */
      if((len=RSTRING_LEN(v1_rb))>FILENAME_MAX)len=FILENAME_MAX;
      *(arg1s+len)=0;
   }
   else
      rb_raise(rb_eRuntimeError,"Unable to convert given filename.");
}

/**
 * get_params()
 *
 * extract params from argc/argv, convert&check results
 */
static void get_params(int argc,VALUE* argv,char *arg1s,char *arg2s,int *argi,int optargs)
{
   int len;
   VALUE arg1_rb,arg2_rb;

   switch(optargs){
      case 0:  /* ein notwendiger Parameter (für lut_filialen) */
         rb_scan_args(argc,argv,"10",&arg1_rb);
         break;

      case 1:  /* ein notwendiger, ein optionaler Parameter (für viele lut-Funktionen) */
         rb_scan_args(argc,argv,"11",&arg1_rb,&arg2_rb);
         if(NIL_P(arg2_rb))   /* Filiale; Hauptstelle ist 0 */
            *argi=0;
         else
            *argi=NUM2INT(arg2_rb);
         break;

      case 2:  /* zwei notwendige Parameter (für konto_check) */
         rb_scan_args(argc,argv,"20",&arg1_rb,&arg2_rb);
         break;

      default:
         break;
   }

   switch(TYPE(arg1_rb)){
      case RUBY_T_STRING:
         strncpy(arg1s,RSTRING_PTR(arg1_rb),15);
         if((len=RSTRING_LEN(arg1_rb))>15)len=15;
         *(arg1s+len)=0;
         break;
      case RUBY_T_FLOAT:
      case RUBY_T_FIXNUM:
      case RUBY_T_BIGNUM:
            /* Zahlwerte werden zunächst nach double umgewandelt, da der
             * Zahlenbereich von 32 Bit Integers nicht groß genug ist für
             * z.B. Kontonummern (10 Stellen). Mit snprintf wird dann eine
             * Stringversion erzeugt - nicht schnell aber einfach :-).
             */
         snprintf(arg1s,16,"%5.0f",NUM2DBL(arg1_rb));
         break;
      default:
         rb_raise(rb_eRuntimeError,"Unable to convert given blz.");
         break;
   }
   if(optargs==2)switch(TYPE(arg2_rb)){  /* für konto_check(): kto holen */
      case RUBY_T_STRING:
         strncpy(arg2s,RSTRING_PTR(arg2_rb),15);
         if((len=RSTRING_LEN(arg2_rb))>15)len=15;
         *(arg2s+len)=0;
         break;
      case RUBY_T_FLOAT:
      case RUBY_T_FIXNUM:
      case RUBY_T_BIGNUM:
         snprintf(arg2s,16,"%5.0f",NUM2DBL(arg2_rb));
         break;
      default:
         rb_raise(rb_eRuntimeError,"Unable to convert given kto.");
         break;
   }
}

/**
 * KontoCheck::konto_check(<kto>, <blz>)
 *
 * check whether the given account number kto kann possibly be
 * a valid number of the bank with the bic blz.
 *
 * possible return values (and short description):
 *
 *    LUT2_NOT_INITIALIZED    "die Programmbibliothek wurde noch nicht initialisiert"
 *    MISSING_PARAMETER       "Bei der Kontoprüfung fehlt ein notwendiger Parameter (BLZ oder Konto)"
 *    
 *    NOT_IMPLEMENTED         "die Methode wurde noch nicht implementiert"
 *    UNDEFINED_SUBMETHOD     "Die (Unter)Methode ist nicht definiert"
 *    INVALID_BLZ             "Die (Unter)Methode ist nicht definiert"
 *    INVALID_BLZ_LENGTH      "die Bankleitzahl ist nicht achtstellig"
 *    INVALID_KTO             "das Konto ist ungültig"
 *    INVALID_KTO_LENGTH      "ein Konto muß zwischen 1 und 10 Stellen haben"
 *    FALSE                   "falsch"
 *    NOT_DEFINED             "die Methode ist nicht definiert"
 *    BAV_FALSE               "BAV denkt, das Konto ist falsch (konto_check hält es für richtig)"
 *    OK                      "ok"
 *    OK_NO_CHK               "ok, ohne Prüfung"
 */

static VALUE konto_check(int argc,VALUE* argv,VALUE self)
{
   char kto[16],blz[16],error_msg[512];
   int retval;

   get_params(argc,argv,blz,kto,NULL,2);
   if((retval=kto_check_blz(blz,kto))==LUT2_NOT_INITIALIZED || retval==MISSING_PARAMETER)RUNTIME_ERROR(retval);

      /* etwas unschlüssig, welche Version man nehmen sollte */
//   return rb_ary_new3(2,retval>0?Qtrue:Qfalse,INT2FIX(retval));
   return INT2FIX(retval);
}

/**
 * KontoCheck::init([lutfile[,level[,set]]])
 *
 * initialize the underlying C library konto_check with the bank
 * information from lutfile.
 *
 * possible return values (and short description):
 *
 *    FILE_READ_ERROR         "kann Datei nicht lesen"
 *    NO_LUT_FILE             "die blz.lut Datei wurde nicht gefunden"
 *    INCREMENTAL_INIT_NEEDS_INFO            "Ein inkrementelles Initialisieren benötigt einen Info-Block in der LUT-Datei"
 *    INCREMENTAL_INIT_FROM_DIFFERENT_FILE   "Ein inkrementelles Initialisieren mit einer anderen LUT-Datei ist nicht möglich"
 *    LUT2_BLOCK_NOT_IN_FILE  "Der Block ist nicht in der LUT-Datei enthalten"
 *    INIT_FATAL_ERROR        "Initialisierung fehlgeschlagen (init_wait geblockt)"
 *    ERROR_MALLOC            "kann keinen Speicher allokieren"
 *    INVALID_LUT_FILE        "die blz.lut Datei ist inkosistent/ungültig"
 *    LUT_CRC_ERROR           "Prüfsummenfehler in der blz.lut Datei"
 *    LUT2_DECOMPRESS_ERROR   "Fehler beim Dekomprimieren eines LUT-Blocks"
 *    LUT2_FILE_CORRUPTED     "Die LUT-Datei ist korrumpiert"
 *    LUT2_Z_DATA_ERROR       "Datenfehler im komprimierten LUT-Block"
 *    LUT2_Z_MEM_ERROR        "Memory error in den ZLIB-Routinen"
 *    KTO_CHECK_UNSUPPORTED_COMPRESSION "die notwendige Kompressions-Bibliothek wurden beim Kompilieren nicht eingebunden"
 *
 *    LUT1_SET_LOADED         "Die Datei ist im alten LUT-Format (1.0/1.1)"
 *    OK                      "ok"
 */
static VALUE init(int argc,VALUE* argv,VALUE self)
{
   char lut_name[FILENAME_MAX+1],error_msg[512];
   int retval,level,set;

   get_params_file(argc,argv,lut_name,&level,&set,1);
   retval=lut_init(lut_name,level,set);
   switch(retval){
      case OK:
      case LUT1_SET_LOADED:
         break;
      default:
         RUNTIME_ERROR(retval);
   }
   return INT2FIX(retval);
}

/**
 * KontoCheck::free()
 *
 * release allocated memory of the underlying C library konto_check
 * return value is always true
 */
static VALUE free_rb(VALUE self)
{
   lut_cleanup();
   return Qtrue;
}

/**
 * KontoCheck::generate_lutfile()
 *
 * generate a new lutfile
 *
 * possible return values (and short description):
 *    ERROR_MALLOC               "kann keinen Speicher allokieren"
 *    FILE_READ_ERROR            "kann Datei nicht lesen"
 *    FILE_WRITE_ERROR           "kann Datei nicht schreiben"
 *    INVALID_BLZ_FILE           "Fehler in der blz.txt Datei (falsche Zeilenlänge)"
 *    INVALID_LUT_FILE           "die blz.lut Datei ist inkosistent/ungültig"
 *    KTO_CHECK_UNSUPPORTED_COMPRESSION "die notwendige Kompressions-Bibliothek wurden beim Kompilieren nicht eingebunden"
 *    LUT2_COMPRESS_ERROR        "Fehler beim Komprimieren eines LUT-Blocks"
 *    LUT2_FILE_CORRUPTED        "Die LUT-Datei ist korrumpiert"
 *    LUT2_GUELTIGKEIT_SWAPPED   "Im Gültigkeitsdatum sind Anfangs- und Enddatum vertauscht"
 *    LUT2_INVALID_GUELTIGKEIT   "Das angegebene Gültigkeitsdatum ist ungültig (Soll: JJJJMMTT-JJJJMMTT)"
 *    LUT2_NO_SLOT_FREE          "Im Inhaltsverzeichnis der LUT-Datei ist kein Slot mehr frei"
 *
 *    LUT1_FILE_GENERATED        "ok; es wurde allerdings eine LUT-Datei im alten Format (1.0/1.1) generiert"
 *    OK                         "ok"
 */
static VALUE generate_lutfile_rb(int argc,VALUE* argv,VALUE self)
{
   char input_name[FILENAME_MAX+1],output_name[FILENAME_MAX+1];
   char user_info[256],gueltigkeit[20],error_msg[512];
   int retval,felder,filialen,set,len;
   VALUE input_name_rb,output_name_rb,user_info_rb,
         gueltigkeit_rb,felder_rb,filialen_rb,set_rb;

   rb_scan_args(argc,argv,"25",&input_name_rb,&output_name_rb,
         &user_info_rb,&gueltigkeit_rb,&felder_rb,&filialen_rb,&set_rb);

   if(TYPE(input_name_rb)==RUBY_T_STRING){
      strncpy(input_name,RSTRING_PTR(input_name_rb),FILENAME_MAX);
      if((len=RSTRING_LEN(input_name_rb))>FILENAME_MAX)len=FILENAME_MAX;
      *(input_name+len)=0;
   }
   else
      rb_raise(rb_eRuntimeError,"Unable to convert given input filename.");

   if(TYPE(output_name_rb)==RUBY_T_STRING){
      strncpy(output_name,RSTRING_PTR(output_name_rb),FILENAME_MAX);
      if((len=RSTRING_LEN(output_name_rb))>FILENAME_MAX)len=FILENAME_MAX;
      *(output_name+len)=0;
   }
   else
      rb_raise(rb_eRuntimeError,"Unable to convert given output filename.");

   if(NIL_P(user_info_rb)){
      *user_info=0;
   }
   else if(TYPE(user_info_rb)==RUBY_T_STRING){
      strncpy(user_info,RSTRING_PTR(user_info_rb),255);
      if((len=RSTRING_LEN(user_info_rb))>255)len=255;
      *(user_info+len)=0;
   }
   else
      rb_raise(rb_eRuntimeError,"Unable to convert given user_info string.");

   if(NIL_P(gueltigkeit_rb)){
      *gueltigkeit=0;
   }
   else if(TYPE(gueltigkeit_rb)==RUBY_T_STRING){
      strncpy(gueltigkeit,RSTRING_PTR(gueltigkeit_rb),19);
      if((len=RSTRING_LEN(gueltigkeit_rb))>19)len=19;
      *(gueltigkeit+len)=0;
   }
   else
      rb_raise(rb_eRuntimeError,"Unable to convert given gueltigkeit string.");

   if(NIL_P(felder_rb))
      felder=DEFAULT_LUT_FIELDS_NUM;
   else
      felder=NUM2INT(felder_rb);

   if(NIL_P(filialen_rb))
      filialen=0;
   else
      filialen=NUM2INT(filialen_rb);

   if(NIL_P(set_rb))
      set=0;
   else
      set=NUM2INT(set_rb);

   retval=generate_lut2_p(input_name,output_name,user_info,gueltigkeit,felder,filialen,0,0,set);
   if(retval<0)RUNTIME_ERROR(retval);
   return INT2FIX(retval);
}

/**
 * KontoCheck::retval2txt(<retval>)
 *
 * convert a numeric retval to string in various encodings
 */
static VALUE retval2txt_rb(VALUE self, VALUE retval)
{
  return rb_str_new2(kto_check_retval2txt(FIX2INT(retval)));
}

static VALUE retval2dos_rb(VALUE self, VALUE retval)
{
  return rb_str_new2(kto_check_retval2dos(FIX2INT(retval)));
}

static VALUE retval2html_rb(VALUE self, VALUE retval)
{
  return rb_str_new2(kto_check_retval2html(FIX2INT(retval)));
}

static VALUE retval2utf8_rb(VALUE self, VALUE retval)
{
  return rb_str_new2(kto_check_retval2utf8(FIX2INT(retval)));
}

/**
 * KontoCheck::dump_lutfile(<lutfile>)
 *
 * get all infos about the contents of a lutfile
 */
static VALUE dump_lutfile_rb(int argc,VALUE* argv,VALUE self)
{
   char lut_name[FILENAME_MAX+1],*ptr;
   int retval;
   VALUE dump;

   get_params_file(argc,argv,lut_name,NULL,NULL,2);
   retval=lut_dir_dump_str(lut_name,&ptr);
   if(retval<=0)
      dump=Qnil;
   else
      dump=rb_str_new2(ptr);
   kc_free(ptr);  /* die C-Funktion allokiert Speicher, der muß wieder freigegeben werden */
   return rb_ary_new3(2,dump,INT2FIX(retval));
}

/**
 * KontoCheck::lut_info([lutfile])
 *
 * get infos about the contents of a lutfile or the loaded blocks (call without filename)
 *
 * possible return values (and short description):
 *
 *    ERROR_MALLOC           "kann keinen Speicher allokieren"
 *    FILE_READ_ERROR        "kann Datei nicht lesen"
 *    INVALID_LUT_FILE       "die blz.lut Datei ist inkosistent/ungültig"
 *    KTO_CHECK_UNSUPPORTED_COMPRESSION "die notwendige Kompressions-Bibliothek wurden beim Kompilieren nicht eingebunden"
 *    LUT1_FILE_USED         "Es wurde eine LUT-Datei im Format 1.0/1.1 geladen"
 *    LUT2_BLOCK_NOT_IN_FILE "Der Block ist nicht in der LUT-Datei enthalten"
 *    LUT2_FILE_CORRUPTED    "Die LUT-Datei ist korrumpiert"
 *    LUT2_NOT_INITIALIZED   "die Programmbibliothek wurde noch nicht initialisiert"
 *    LUT2_Z_BUF_ERROR       "Buffer error in den ZLIB Routinen"
 *    LUT2_Z_DATA_ERROR      "Datenfehler im komprimierten LUT-Block"
 *    LUT2_Z_MEM_ERROR       "Memory error in den ZLIB-Routinen"
 *    LUT_CRC_ERROR          "Prüfsummenfehler in der blz.lut Datei"
 *    OK                     "ok"
 *
 */
static VALUE lut_info_rb(int argc,VALUE* argv,VALUE self)
{
   char lut_name[FILENAME_MAX+1],*info1,*info2,error_msg[512];
   int retval,valid1,valid2;
   VALUE info1_rb,info2_rb;

   get_params_file(argc,argv,lut_name,NULL,NULL,3);
   retval=lut_info(lut_name,&info1,&info2,&valid1,&valid2);
   if(!info1)
      info1_rb=Qnil;
   else
      info1_rb=rb_str_new2(info1);
   if(!info2)
      info2_rb=Qnil;
   else
      info2_rb=rb_str_new2(info2);
   kc_free(info1);  /* die C-Funktion allokiert Speicher, der muß wieder freigegeben werden */
   kc_free(info2);
   if(retval<0)RUNTIME_ERROR(retval);
   return rb_ary_new3(5,INT2FIX(retval),INT2FIX(valid1),INT2FIX(valid2),info1_rb,info2_rb);
}

/**
 * KontoCheck::load_bank_data(<datafile>)
 *
 * initialize the underlying C library konto_check with the bank
 * information from datafile.
 * Internally, this file is first transformed into a LUT file and then
 * read.
 *
 * For the datafile, use the file 'blz_yyyymmdd.txt' from
 * http://www.bundesbank.de/zahlungsverkehr/zahlungsverkehr_bankleitzahlen_download.php
 * These files are updated every three months, so be sure to
 * replace them regularly.
 */

 /****************************************************************************
  ****************************************************************************
  ****                                                                    ****
  ****     WARNING - this function will be removed in near future.        ****
  ****     Use KontoCheck::init() for initialization from a lutfile,      ****
  ****     KontoCheck::generate_lutfile() to generate a new lutfile.      ****
  ****     The init() function is much faster (about 7..20 times)         ****
  ****     then this function and has some more advantages (two sets      ****
  ****     of data, flexible level of initialization, compact format).    ****
  ****                                                                    ****
  ****************************************************************************
  ****************************************************************************/

static VALUE load_bank_data(VALUE self, VALUE path_rb) {
  char *path,*tmp_lut;

  path= RSTRING_PTR(path_rb);
  tmp_lut = tmpnam(NULL);

  // convert the Bankfile to a LUT file
  int ret = generate_lut(path, tmp_lut, (char *)"Temporary LUT file", 2);
  switch (ret) {
    case LUT_V2_FILE_GENERATED:
    case LUT1_FILE_GENERATED:
    case OK:
      break;
    case FILE_READ_ERROR:
      rb_raise(rb_eRuntimeError, "[%d] KontoCheck: can not open file '%s'. Use the file 'blz_yyyymmdd.txt' from http://www.bundesbank.de/zahlungsverkehr/zahlungsverkehr_bankleitzahlen_download.php", ret, path);
    case INVALID_BLZ_FILE:
      rb_raise(rb_eRuntimeError, "[%d] KontoCheck: invalid input file '%s'. Use the file 'blz_yyyymmdd.txt' from http://www.bundesbank.de/zahlungsverkehr/zahlungsverkehr_bankleitzahlen_download.php", ret, path);
    default:
      rb_raise(rb_eRuntimeError, "[%d] KontoCheck: error reading file '%s'. Use the file 'blz_yyyymmdd.txt' from http://www.bundesbank.de/zahlungsverkehr/zahlungsverkehr_bankleitzahlen_download.php", ret, tmp_lut);
  }

  // read the LUT file
  ret = kto_check_init2(tmp_lut);
  switch (ret) {
    case LUT1_SET_LOADED:
    case LUT_V2_FILE_GENERATED:
    case LUT2_PARTIAL_OK:
      return Qtrue;
    case FILE_READ_ERROR:
      rb_raise(rb_eRuntimeError, "[%d] KontoCheck: can not open tempfile '%s'.", ret, tmp_lut);
    case INVALID_LUT_FILE:
      rb_raise(rb_eRuntimeError, "[%d] KontoCheck: invalid input tempfile '%s'.", ret, tmp_lut);
  }
  rb_raise(rb_eRuntimeError, "[%d] KontoCheck: error reading tempfile '%s'.", ret, tmp_lut);
  return Qnil;
}

/**
 * KontoCheck::bank_valid(<blz> [,filiale])
 *
 * check if a given blz is valid
 *
 * possible return values (and short description):
 *
 *    LUT2_INDEX_OUT_OF_RANGE    "Der Index für die Filiale ist ungültig"
 *    LUT2_BLZ_NOT_INITIALIZED   "Das Feld BLZ wurde nicht initialisiert"
 *    INVALID_BLZ_LENGTH         "die Bankleitzahl ist nicht achtstellig"
 *    INVALID_BLZ                "die Bankleitzahl ist ungültig"
 *    OK                         "ok"
 */
static VALUE bank_valid(int argc,VALUE* argv,VALUE self)
{
   char blz[16],error_msg[512];
   int filiale,retval;

   get_params(argc,argv,blz,NULL,&filiale,1);
   retval=lut_blz(blz,filiale);
   if(retval==LUT2_BLZ_NOT_INITIALIZED)RUNTIME_ERROR(retval);
   return rb_ary_new3(2,retval>0?Qtrue:Qfalse,INT2FIX(retval));
}

/**
 * KontoCheck::bank_filialen(<blz>)
 *
 * return the number of branch offices
 *
 * possible return values (and short description):
 *
 *    LUT2_BLZ_NOT_INITIALIZED      "Das Feld BLZ wurde nicht initialisiert"
 *    LUT2_FILIALEN_NOT_INITIALIZED "Das Feld Filialen wurde nicht initialisiert"
 *    LUT2_INDEX_OUT_OF_RANGE       "Der Index für die Filiale ist ungültig"
 *    INVALID_BLZ_LENGTH            "die Bankleitzahl ist nicht achtstellig"
 *    INVALID_BLZ                   "die Bankleitzahl ist ungültig"
 *    OK                            "ok"
 */
static VALUE bank_filialen(int argc,VALUE* argv,VALUE self)
{
   char blz[16],error_msg[512];
   int retval,cnt;

   get_params(argc,argv,blz,NULL,NULL,0);
   cnt=lut_filialen(blz,&retval);
   if(retval==LUT2_BLZ_NOT_INITIALIZED || retval==LUT2_FILIALEN_NOT_INITIALIZED)RUNTIME_ERROR(retval);
   return rb_ary_new3(2,retval<=0?Qnil:INT2FIX(cnt),INT2FIX(retval));
}

/**
 * KontoCheck::bank_name(<blz> [,filiale])
 *
 * return the name of a bank
 *
 * possible return values (and short description):
 *
 *    LUT2_BLZ_NOT_INITIALIZED      "Das Feld BLZ wurde nicht initialisiert"
 *    LUT2_NAME_NOT_INITIALIZED     "Das Feld Bankname wurde nicht initialisiert"
 *    LUT2_INDEX_OUT_OF_RANGE       "Der Index für die Filiale ist ungültig"
 *    INVALID_BLZ_LENGTH            "die Bankleitzahl ist nicht achtstellig"
 *    INVALID_BLZ                   "die Bankleitzahl ist ungültig"
 *    OK                            "ok"
 */
static VALUE bank_name(int argc,VALUE* argv,VALUE self)
{
   char blz[16],*name,error_msg[512];
   int retval,filiale;

   get_params(argc,argv,blz,NULL,&filiale,1);
   name=lut_name(blz,filiale,&retval);
   if(retval==LUT2_BLZ_NOT_INITIALIZED || retval==LUT2_NAME_NOT_INITIALIZED)RUNTIME_ERROR(retval);
   return rb_ary_new3(2,retval<=0?Qnil:rb_str_new2(name),INT2FIX(retval));
}

/**
 * KontoCheck::bank_name_kurz(<blz> [,filiale])
 *
 * return the short name of a bank
 *
 * possible return values (and short description):
 *
 *    LUT2_BLZ_NOT_INITIALIZED      "Das Feld BLZ wurde nicht initialisiert"
 *    LUT2_NAME_KURZ_NOT_INITIALIZED "Das Feld Kurzname wurde nicht initialisiert"
 *    LUT2_INDEX_OUT_OF_RANGE       "Der Index für die Filiale ist ungültig"
 *    INVALID_BLZ_LENGTH            "die Bankleitzahl ist nicht achtstellig"
 *    INVALID_BLZ                   "die Bankleitzahl ist ungültig"
 *    OK                            "ok"
 */
static VALUE bank_name_kurz(int argc,VALUE* argv,VALUE self)
{
   char blz[16],*name,error_msg[512];
   int retval,filiale;

   get_params(argc,argv,blz,NULL,&filiale,1);
   name=lut_name_kurz(blz,filiale,&retval);
   if(retval==LUT2_BLZ_NOT_INITIALIZED || retval==LUT2_NAME_KURZ_NOT_INITIALIZED)RUNTIME_ERROR(retval);
   return rb_ary_new3(2,retval<=0?Qnil:rb_str_new2(name),INT2FIX(retval));
}

/**
 * KontoCheck::bank_name_ort(<blz> [,filiale])
 *
 * return the location of a bank
 *
 * possible return values (and short description):
 *
 *    LUT2_BLZ_NOT_INITIALIZED      "Das Feld BLZ wurde nicht initialisiert"
 *    LUT2_ORT_NOT_INITIALIZED      "Das Feld Ort wurde nicht initialisiert"
 *    LUT2_INDEX_OUT_OF_RANGE       "Der Index für die Filiale ist ungültig"
 *    INVALID_BLZ_LENGTH            "die Bankleitzahl ist nicht achtstellig"
 *    INVALID_BLZ                   "die Bankleitzahl ist ungültig"
 *    OK                            "ok"
 */
static VALUE bank_ort(int argc,VALUE* argv,VALUE self)
{
   char blz[16],*ort,error_msg[512];
   int retval,filiale;

   get_params(argc,argv,blz,NULL,&filiale,1);
   ort=lut_ort(blz,filiale,&retval);
   if(retval==LUT2_BLZ_NOT_INITIALIZED || retval==LUT2_ORT_NOT_INITIALIZED)RUNTIME_ERROR(retval);
   return rb_ary_new3(2,retval<=0?Qnil:rb_str_new2(ort),INT2FIX(retval));
}

/**
 * KontoCheck::bank_plz(<blz> [,filiale])
 *
 * return the plz of a bank
 *
 * possible return values (and short description):
 *
 *    LUT2_BLZ_NOT_INITIALIZED      "Das Feld BLZ wurde nicht initialisiert"
 *    LUT2_PLZ_NOT_INITIALIZED      "Das Feld PLZ wurde nicht initialisiert"
 *    LUT2_INDEX_OUT_OF_RANGE       "Der Index für die Filiale ist ungültig"
 *    INVALID_BLZ_LENGTH            "die Bankleitzahl ist nicht achtstellig"
 *    INVALID_BLZ                   "die Bankleitzahl ist ungültig"
 *    OK                            "ok"
 */
static VALUE bank_plz(int argc,VALUE* argv,VALUE self)
{
   char blz[16],error_msg[512];
   int retval,plz,filiale;

   get_params(argc,argv,blz,NULL,&filiale,1);
   plz=lut_plz(blz,filiale,&retval);
   if(retval==LUT2_BLZ_NOT_INITIALIZED || retval==LUT2_PLZ_NOT_INITIALIZED)RUNTIME_ERROR(retval);
   return rb_ary_new3(2,retval<=0?Qnil:INT2FIX(plz),INT2FIX(retval));
}

/**
 * KontoCheck::bank_pz(<blz> [,filiale])
 *
 * return the check method of a bank
 *
 * possible return values (and short description):
 *
 *    LUT2_BLZ_NOT_INITIALIZED      "Das Feld BLZ wurde nicht initialisiert"
 *    LUT2_PZ_NOT_INITIALIZED       "Das Feld Prüfziffer wurde nicht initialisiert"
 *    LUT2_INDEX_OUT_OF_RANGE       "Der Index für die Filiale ist ungültig"
 *    INVALID_BLZ_LENGTH            "die Bankleitzahl ist nicht achtstellig"
 *    INVALID_BLZ                   "die Bankleitzahl ist ungültig"
 *    OK                            "ok"
 */
static VALUE bank_pz(int argc,VALUE* argv,VALUE self)
{
   char blz[16],error_msg[512];
   int retval,pz,filiale;

   get_params(argc,argv,blz,NULL,&filiale,1);
   pz=lut_pz(blz,filiale,&retval);
   if(retval==LUT2_BLZ_NOT_INITIALIZED || retval==LUT2_PZ_NOT_INITIALIZED)RUNTIME_ERROR(retval);
   return rb_ary_new3(2,retval<=0?Qnil:INT2FIX(pz),INT2FIX(retval));
}

/**
 * KontoCheck::bank_bic(<blz> [,filiale])
 *
 * return the BIC (Bank Identifier Code) of a bank
 *
 * possible return values (and short description):
 *
 *    LUT2_BLZ_NOT_INITIALIZED      "Das Feld BLZ wurde nicht initialisiert"
 *    LUT2_BIC_NOT_INITIALIZED      "Das Feld BIC wurde nicht initialisiert"
 *    LUT2_INDEX_OUT_OF_RANGE       "Der Index für die Filiale ist ungültig"
 *    INVALID_BLZ_LENGTH            "die Bankleitzahl ist nicht achtstellig"
 *    INVALID_BLZ                   "die Bankleitzahl ist ungültig"
 *    OK                            "ok"
 */
static VALUE bank_bic(int argc,VALUE* argv,VALUE self)
{
   char blz[16],*bic,error_msg[512];
   int retval,filiale;

   get_params(argc,argv,NULL,blz,&filiale,1);
   bic=lut_bic(blz,filiale,&retval);
   if(retval==LUT2_BLZ_NOT_INITIALIZED || retval==LUT2_BIC_NOT_INITIALIZED)RUNTIME_ERROR(retval);
   return rb_ary_new3(2,retval<=0?Qnil:rb_str_new2(bic),INT2FIX(retval));
}

/**
 * KontoCheck::bank_aenderung(<blz> [,filiale])
 *
 * return the 'Änderung' flag of a bank
 *
 * possible return values (and short description):
 *
 *    LUT2_BLZ_NOT_INITIALIZED      "Das Feld BLZ wurde nicht initialisiert"
 *    LUT2_AENDERUNG_NOT_INITIALIZED "Das Feld Änderung wurde nicht initialisiert"
 *    LUT2_INDEX_OUT_OF_RANGE       "Der Index für die Filiale ist ungültig"
 *    INVALID_BLZ_LENGTH            "die Bankleitzahl ist nicht achtstellig"
 *    INVALID_BLZ                   "die Bankleitzahl ist ungültig"
 *    OK                            "ok"
 */
static VALUE bank_aenderung(int argc,VALUE* argv,VALUE self)
{
   char blz[16],error_msg[512];
   int retval,aenderung,filiale;

   get_params(argc,argv,blz,NULL,&filiale,1);
   aenderung=lut_aenderung(blz,filiale,&retval);
   if(retval==LUT2_BLZ_NOT_INITIALIZED || retval==LUT2_AENDERUNG_NOT_INITIALIZED)RUNTIME_ERROR(retval);
   return rb_ary_new3(2,retval<=0?Qnil:INT2FIX(aenderung),INT2FIX(retval));
}

/**
 * KontoCheck::bank_loeschung(<blz> [,filiale])
 *
 * return the 'Löschung' flag of a bank
 *
 * possible return values (and short description):
 *
 *    LUT2_BLZ_NOT_INITIALIZED      "Das Feld BLZ wurde nicht initialisiert"
 *    LUT2_LOESCHUNG_NOT_INITIALIZED "Das Feld Löschung wurde nicht initialisiert"
 *    LUT2_INDEX_OUT_OF_RANGE       "Der Index für die Filiale ist ungültig"
 *    INVALID_BLZ_LENGTH            "die Bankleitzahl ist nicht achtstellig"
 *    INVALID_BLZ                   "die Bankleitzahl ist ungültig"
 *    OK                            "ok"
 */
static VALUE bank_loeschung(int argc,VALUE* argv,VALUE self)
{
   char blz[16],error_msg[512];
   int retval,loeschung,filiale;

   get_params(argc,argv,blz,NULL,&filiale,1);
   loeschung=lut_loeschung(blz,filiale,&retval);
   if(retval==LUT2_BLZ_NOT_INITIALIZED || retval==LUT2_LOESCHUNG_NOT_INITIALIZED)RUNTIME_ERROR(retval);
   return rb_ary_new3(2,retval<=0?Qnil:INT2FIX(loeschung),INT2FIX(retval));
}

/**
 * KontoCheck::bank_nachfolge_blz(<blz> [,filiale])
 *
 * return the successor of a bank which will be deleted ('Löschung' flag set)
 *
 * possible return values (and short description):
 *
 *    LUT2_BLZ_NOT_INITIALIZED      "Das Feld BLZ wurde nicht initialisiert"
 *    LUT2_NACHFOLGE_BLZ_NOT_INITIALIZED "Das Feld Nachfolge-BLZ wurde nicht initialisiert"
 *    LUT2_INDEX_OUT_OF_RANGE       "Der Index für die Filiale ist ungültig"
 *    INVALID_BLZ_LENGTH            "die Bankleitzahl ist nicht achtstellig"
 *    INVALID_BLZ                   "die Bankleitzahl ist ungültig"
 *    OK                            "ok"
 */
static VALUE bank_nachfolge_blz(int argc,VALUE* argv,VALUE self)
{
   char blz[16],error_msg[512];
   int retval,n_blz,filiale;

   get_params(argc,argv,blz,NULL,&filiale,1);
   n_blz=lut_nachfolge_blz(blz,filiale,&retval);
   if(retval==LUT2_BLZ_NOT_INITIALIZED || retval==LUT2_NACHFOLGE_BLZ_NOT_INITIALIZED)RUNTIME_ERROR(retval);
   return rb_ary_new3(2,retval<=0?Qnil:INT2FIX(n_blz),INT2FIX(retval));
}

/**
 * KontoCheck::bank_pan(<blz> [,filiale])
 *
 * return the PAN (Primary Account Number) of a bank
 *
 * possible return values (and short description):
 *
 *    LUT2_BLZ_NOT_INITIALIZED      "Das Feld BLZ wurde nicht initialisiert"
 *    LUT2_PAN_NOT_INITIALIZED      "Das Feld PAN wurde nicht initialisiert"
 *    LUT2_INDEX_OUT_OF_RANGE       "Der Index für die Filiale ist ungültig"
 *    INVALID_BLZ_LENGTH            "die Bankleitzahl ist nicht achtstellig"
 *    INVALID_BLZ                   "die Bankleitzahl ist ungültig"
 *    OK                            "ok"
 */
static VALUE bank_pan(int argc,VALUE* argv,VALUE self)
{
   char blz[16],error_msg[512];
   int retval,pan,filiale;

   get_params(argc,argv,blz,NULL,&filiale,1);
   pan=lut_pan(blz,filiale,&retval);
   if(retval==LUT2_BLZ_NOT_INITIALIZED || retval==LUT2_PAN_NOT_INITIALIZED)RUNTIME_ERROR(retval);
   return rb_ary_new3(2,retval<=0?Qnil:INT2FIX(pan),INT2FIX(retval));
}

/**
 * KontoCheck::bank_nr(<blz> [,filiale])
 *
 * return the sequence number of a bank (internal field of BLZ file)
 *
 * possible return values (and short description):
 *
 *    LUT2_BLZ_NOT_INITIALIZED      "Das Feld BLZ wurde nicht initialisiert"
 *    LUT2_NR_NOT_INITIALIZED       "Das Feld NR wurde nicht initialisiert"
 *    LUT2_INDEX_OUT_OF_RANGE       "Der Index für die Filiale ist ungültig"
 *    INVALID_BLZ_LENGTH            "die Bankleitzahl ist nicht achtstellig"
 *    INVALID_BLZ                   "die Bankleitzahl ist ungültig"
 *    OK                            "ok"
 */
static VALUE bank_nr(int argc,VALUE* argv,VALUE self)
{
   char blz[16],error_msg[512];
   int retval,nr,filiale;

   get_params(argc,argv,blz,NULL,&filiale,1);
   nr=lut_nr(blz,filiale,&retval);
   if(retval==LUT2_BLZ_NOT_INITIALIZED || retval==LUT2_NR_NOT_INITIALIZED)RUNTIME_ERROR(retval);
   return rb_ary_new3(2,retval<=0?Qnil:INT2FIX(nr),INT2FIX(retval));
}

/**
 * The initialization method for this module
 */
void Init_konto_check()
{
   KontoCheck = rb_define_module("KontoCheck");

      /* die Parameteranzahl -1 bei den folgenden Funktionen meint eine variable
       * Anzahl Parameter; die genaue Anzahl wird bei der Funktion rb_scan_args()
       * als 3. Parameter angegeben.
       *
       * Bei -1 erfolgt die Übergabe als C-Array, bei -2 ist die Übergabe als
       * Ruby-Array (s. http://karottenreibe.github.com/2009/10/28/ruby-c-extension-5/):
       *
       *    A positive number means, your function will take just that many
       *       arguments, none less, none more.
       *    -1 means the function takes a variable number of arguments, passed
       *       as a C array.
       *    -2 means the function takes a variable number of arguments, passed
       *       as a Ruby array.
       *
       * Was in ext_ruby.pdf (S.39) dazu steht, ist einfach falsch (das hat
       * mich einige Zeit gekostet):
       *
       *    In some of the function definitions that follow, the parameter argc
       *    specifies how many arguments a Ruby method takes. It may have the
       *    following values. If the value is not negative, it specifies the
       *    number of arguments the method takes. If negative, it indicates
       *    that the method takes optional arguments. In this case, the
       *    absolute value of argc minus one is the number of required
       *    arguments (so -1 means all arguments are optional, -2 means one
       *    mandatory argument followed by optional arguments, and so on).
       *
       * Es wäre zu testen, ob dieses Verhalten bei älteren Versionen noch
       * gilt; dann müßte man eine entsprechende Verzweigung einbauen. Bei den
       * aktuellen Varianten (Ruby 1.8.6 und 1.9.2) funktioniert diese
       * Variante.
       */
   rb_define_module_function(KontoCheck, "init", init,-1);
   rb_define_module_function(KontoCheck, "free", free_rb,0);
   rb_define_module_function(KontoCheck, "konto_check", konto_check,-1);
   rb_define_module_function(KontoCheck, "bank_valid", bank_valid,-1);
   rb_define_module_function(KontoCheck, "bank_filialen", bank_filialen,-1);
   rb_define_module_function(KontoCheck, "bank_name", bank_name,-1);
   rb_define_module_function(KontoCheck, "bank_name_kurz", bank_name_kurz,-1);
   rb_define_module_function(KontoCheck, "bank_plz", bank_plz,-1);
   rb_define_module_function(KontoCheck, "bank_ort", bank_ort,-1);
   rb_define_module_function(KontoCheck, "bank_pan", bank_pan,-1);
   rb_define_module_function(KontoCheck, "bank_bic", bank_bic,-1);
   rb_define_module_function(KontoCheck, "bank_nr", bank_nr,-1);
   rb_define_module_function(KontoCheck, "bank_pz", bank_pz,-1);
   rb_define_module_function(KontoCheck, "bank_aenderung", bank_aenderung,-1);
   rb_define_module_function(KontoCheck, "bank_loeschung", bank_loeschung,-1);
   rb_define_module_function(KontoCheck, "bank_nachfolge_blz", bank_nachfolge_blz,-1);
   rb_define_module_function(KontoCheck, "dump_lutfile", dump_lutfile_rb,-1);
   rb_define_module_function(KontoCheck, "lut_info",lut_info_rb,-1);
   rb_define_module_function(KontoCheck, "retval2txt", retval2txt_rb, 1);
   rb_define_module_function(KontoCheck, "retval2dos", retval2dos_rb, 1);
   rb_define_module_function(KontoCheck, "retval2html", retval2html_rb, 1);
   rb_define_module_function(KontoCheck, "retval2utf8", retval2utf8_rb, 1);
   rb_define_module_function(KontoCheck, "generate_lutfile", generate_lutfile_rb,-1);

   /* fehlende Funktionen:
    * - iban
    * - Suche
    * - lut_multiple
    */

   rb_define_module_function(KontoCheck, "load_bank_data", load_bank_data, 1);
}

