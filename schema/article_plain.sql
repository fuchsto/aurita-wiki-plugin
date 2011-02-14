--
-- PostgreSQL database dump
--

SET client_encoding = 'UTF8';
SET standard_conforming_strings = off;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET escape_string_warning = off;

SET search_path = public, pg_catalog;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: article_plain; Type: TABLE; Schema: public; Owner: fuchsto; Tablespace: 
--

CREATE TABLE article_plain (
    article_plain_id integer NOT NULL,
    article_id integer NOT NULL,
    content text DEFAULT ''::text NOT NULL
);


ALTER TABLE public.article_plain OWNER TO fuchsto;

--
-- Name: article_plain_id_seq; Type: SEQUENCE; Schema: public; Owner: fuchsto
--

CREATE SEQUENCE article_plain_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.article_plain_id_seq OWNER TO fuchsto;

--
-- Name: article_plain_pkey; Type: CONSTRAINT; Schema: public; Owner: fuchsto; Tablespace: 
--

ALTER TABLE ONLY article_plain
    ADD CONSTRAINT article_plain_pkey PRIMARY KEY (article_plain_id);


--
-- Name: article_plain_article_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: fuchsto
--

ALTER TABLE ONLY article_plain
    ADD CONSTRAINT article_plain_article_id_fkey FOREIGN KEY (article_id) REFERENCES article(article_id);


--
-- Name: article_plain; Type: ACL; Schema: public; Owner: fuchsto
--

REVOKE ALL ON TABLE article_plain FROM PUBLIC;
REVOKE ALL ON TABLE article_plain FROM fuchsto;
GRANT ALL ON TABLE article_plain TO fuchsto;
GRANT ALL ON TABLE article_plain TO aurita;


--
-- Name: article_plain_id_seq; Type: ACL; Schema: public; Owner: fuchsto
--

REVOKE ALL ON SEQUENCE article_plain_id_seq FROM PUBLIC;
REVOKE ALL ON SEQUENCE article_plain_id_seq FROM fuchsto;
GRANT ALL ON SEQUENCE article_plain_id_seq TO fuchsto;
GRANT ALL ON SEQUENCE article_plain_id_seq TO aurita;


--
-- PostgreSQL database dump complete
--

