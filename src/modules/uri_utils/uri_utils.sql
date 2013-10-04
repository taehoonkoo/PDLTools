-- File: uri_utils.sql
-- Implementation of URI handling utility.

CREATE SCHEMA ds_tools;

DROP TYPE IF EXISTS ds_tools.uri_type CASCADE;

/**
 * @brief uri_type: Information about a URI.
 *
 * @usage
 * A URI (URL or URN) is represented by its components:
 * scheme://userInfo@hostText:portText/path?query#fragment
 *
 * If the host name is numeric in either IPv4 or IPv6 format, it is parsed and
 * represented in either the "IPv4" or "IPv6" element. "ipFuture" is meant to
 * support additional formats in the future.
 *
 * "path" is stored as an array of path components, so "/usr/local/lib" is
 * parsed as ['usr','local','lib'].
 *
 * "absolutePath" is a Boolean, indicating whether a file path is absolute
 * or relative.
 *
 * "key" and "value", if not NULL, are parsed versions of the query string.
 * key[i] and value[i] hold the information for the i'th key-value pair in
 * the query string.
 */
CREATE TYPE ds_tools.uri_type AS (
  scheme text,
  userInfo text,            
  hostText text,
  IPv4 bytea,
  IPv6 bytea,
  ipFuture text,
  portText text,
  path text[],
  query text,
  fragment text,
  absolutePath boolean,
  key text[],
  value text[]
);

DROP TYPE IF EXISTS ds_tools.uri_array_type CASCADE;

/**
 * @brief uri_array_type: Information about an ordered collection of URI.
 *
 * @usage
 * Same as uri_type, but each element is an array, holding data for the
 * entire collection.
 *
 * Additionally:
 * "path" is kept unparsed, as a single "/"-separated string, for each URI.
 * key-value pairs are not extracted from the query.
 * The original uri is kept in the variable "uri", in its original form.
 */
CREATE TYPE ds_tools.uri_array_type AS (
  scheme text[],
  userInfo text[],
  hostText text[],
  IPv4 bytea[],
  IPv6 bytea[],
  ipFuture text[],
  portText text[],
  path text[],
  query text[],
  fragment text[],
  absolutePath boolean[],
  uri text[]
);

/**
 * @brief parse_uri: Parse a URI into its components.
 *
 * @about
 * A row function, parsing URIs in text format to parsed URIs in uri_type.
 *
 * @prereq external library: uriparser.
 *
 * @usage
 * uri - original URI in text form.
 * normalize - Boolean stating whether parsed URI should be returned in
 *             normalized form (e.g. with lowercase domain name and consistent
 *             handling of special characters).
 * parse_query - Boolean stating whether query portion should be separated into
 *               key-value pairs. If not, "key" and "value are returned NULLs.
 *
 * @examp
 * SELECT ds_tools.parse_uri('http://myself:password@www.goPivotal.com:80/%7ehello/to/you/index.html?who=I&whom=me#here',true,true);
 *                                                        parse_uri                                                        
 * ------------------------------------------------------------------------------------------------------------------------
 *  (http,myself:password,www.gopivotal.com,,,,80,"{~hello,to,you,index.html}",who=I&whom=me,here,f,"{who,whom}","{I,me}")
 * (1 row)
 */
CREATE OR REPLACE FUNCTION ds_tools.parse_uri(uri text, normalize boolean,
                                   parse_query boolean)
RETURNS ds_tools.uri_type
AS '/home/gpadmin/michael/ds_tools/url/ver4/uri_utils.so','parse_uri'
LANGUAGE C IMMUTABLE STRICT;

CREATE OR REPLACE FUNCTION ds_tools.parse_uri()
RETURNS VARCHAR
IMMUTABLE
LANGUAGE SQL
AS
$$
SELECT '
parse_uri: Parse a URI into its components.

A row function, parsing URIs in text format to parsed URIs in uri_type.

For full usage instructions, run "ds_tools.parse_uri(''usage'')".
'::VARCHAR;
$$;

CREATE OR REPLACE FUNCTION ds_tools.parse_uri(option VARCHAR)
RETURNS VARCHAR
IMMUTABLE
LANGUAGE SQL
AS
$$
SELECT CASE WHEN $1!='usage' THEN ds_tools.parse_uri() ELSE '
parse_uri: Parse a URI into its components.

A row function, parsing URIs in text format to parsed URIs in uri_type.

Synposis
========
ds_tools.parse_uri(uri text, normalize boolean, parse_query boolean)
RETURNS uri_type

uri - original URI in text form.
normalize - Boolean stating whether parsed URI should be returned in
            normalized form (e.g. with lowercase domain name and consistent
            handling of special characters).
parse_query - Boolean stating whether query portion should be separated into
              key-value pairs. If not, "key" and "value are returned NULLs.

Usage
=====
Returns a uri_type. Note that the fields "key" and "value" include the actual
decoded content of the key-value parameters. As such, they are not affected by
the questio of whether "normalize" is true or false.

Example
=======
SELECT ds_tools.parse_uri('http://myself:password@www.goPivotal.com:80/%7ehello/to/you/index.html?who=I&whom=me#here',true,true);
                                                       parse_uri                                                        
------------------------------------------------------------------------------------------------------------------------
 (http,myself:password,www.gopivotal.com,,,,80,"{~hello,to,you,index.html}",who=I&whom=me,here,f,"{who,whom}","{I,me}")
(1 row)
' END;
$$;

/**
 * @brief extract_uri: Extract all URIs embedded in text input.
 *
 * @about
 * A row function, extracting uri_array_type from a text field.
 *
 * @prereq external library: uriparser.
 *
 * @usage
 * txt - Text from which URIs are to be extracted.
 * normalize - Boolean stating whether parsed URIs should be returned in
 *             normalized form (e.g. with lowercase domain names and consistent
 *             handling of special characters).
 *
 * @examp
 * SELECT ds_tools.extract_uri('First go to http://[0123:4567:89ab:cdef:0123:4567:89ab:cdef]/ then go to https://192.165.0.1/ and repeat.',true);
 *                                                                                                                                                            extract_uri                                                                                                                                                           
 * ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 *  ("{http,https}","{"""",""""}","{0123:4567:89ab:cdef:0123:4567:89ab:cdef,192.165.0.1}","{"""",300245000001}","{001043105147211253315357001043105147211253315357,""""}","{"""",""""}","{"""",""""}","{"""",""""}","{"""",""""}","{"""",""""}","{f,f}","{http://[0123:4567:89ab:cdef:0123:4567:89ab:cdef]/,https://192.165.0.1/}")
 * (1 row)
 */
CREATE OR REPLACE FUNCTION ds_tools.extract_uri(txt text, normalize boolean)
RETURNS ds_tools.uri_array_type
AS '/home/gpadmin/michael/ds_tools/url/ver4/uri_utils.so','extract_uri'
LANGUAGE C IMMUTABLE STRICT;

CREATE OR REPLACE FUNCTION ds_tools.extract_uri()
RETURNS VARCHAR
IMMUTABLE
LANGUAGE SQL
AS
$$
SELECT '
extract_uri: Extract all URIs embedded in text input.

A row function, extracting uri_array_type from a text field.

For full usage instructions, run "ds_tools.extract_uri(''usage'')".
'::VARCHAR;
$$;

CREATE OR REPLACE FUNCTION ds_tools.extract_uri(option VARCHAR)
RETURNS VARCHAR
IMMUTABLE
LANGUAGE SQL
AS
$$
SELECT CASE WHEN $1!='usage' THEN ds_tools.extract_uri() ELSE '
extract_uri: Extract all URIs embedded in text input.

A row function, extracting uri_array_type from a text field.

Synposis
========
ds_tools.extract_uri(txt text, normalize boolean)
RETURNS uri_array_type

txt - Text from which URIs are to be extracted.
normalize - Boolean stating whether parsed URIs should be returned in
            normalized form (e.g. with lowercase domain names and consistent
            handling of special characters).

Usage
=====
Returns a uri_array_type. Note that the "uri" field keeps the original URI
exactly in the form that it was in the original text, regardless of whether
"normalize" is "true" or "false".

Example
=======
SELECT ds_tools.extract_uri('First go to http://[0123:4567:89ab:cdef:0123:4567:89ab:cdef]/ then go to https://192.165.0.1/ and repeat.',true);
                                                                                                                                                           extract_uri                                                                                                                                                           
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 ("{http,https}","{"""",""""}","{0123:4567:89ab:cdef:0123:4567:89ab:cdef,192.165.0.1}","{"""",300245000001}","{001043105147211253315357001043105147211253315357,""""}","{"""",""""}","{"""",""""}","{"""",""""}","{"""",""""}","{"""",""""}","{f,f}","{http://[0123:4567:89ab:cdef:0123:4567:89ab:cdef]/,https://192.165.0.1/}")
(1 row)
' END;
$$;


/**
 * @brief parse_domain: Parse a URI domain name into its components.
 *
 * @about
 * A row function, parsing a textual hierarchical domain name into components.
 *
 * @usage
 * domainname - Domain name to be parsed.
 *
 * @examp
 * SELECT ds_tools.parse_domain('www.gopivotal.com');
 *     parse_domain     
 * ---------------------
 *  {www,gopivotal,com}
 * (1 row)
 */
CREATE OR REPLACE FUNCTION ds_tools.parse_domain(domainname text)
RETURNS text[]
IMMUTABLE
STRICT
LANGUAGE SQL
AS
$$
SELECT CASE WHEN $1!='usage' THEN regexp_split_to_array($1,E'\\.') ELSE
array['
parse_domain: Parse a URI domain into its components.

A row function, parsing a textual hierarchical domain name into components.

Synposis
========
ds_tools.parse_domain(domainname text)
RETURNS text[]

domainname - Domain name to be parsed.

Example
=======
SELECT ds_tools.parse_domain('www.gopivotal.com');
    parse_domain     
---------------------
 {www,gopivotal,com}
(1 row)
'] END;
$$;

CREATE OR REPLACE FUNCTION ds_tools.parse_domain()
RETURNS VARCHAR
IMMUTABLE
LANGUAGE SQL
AS
$$
SELECT '
parse_domain: Parse a URI domain into its components.

A row function, parsing a textual hierarchical domain name into components.

For full usage instructions, run "ds_tools.parse_domain(''usage'')".
'::VARCHAR;
$$;

