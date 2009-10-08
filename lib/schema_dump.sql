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
-- Name: article; Type: TABLE; Schema: public; Owner: cuba; Tablespace: 
--

CREATE TABLE article (
    article_id integer NOT NULL,
    content_id integer NOT NULL,
    template_id integer DEFAULT 0 NOT NULL,
    title character varying(100),
    view_count integer DEFAULT 0 NOT NULL,
    published boolean DEFAULT false NOT NULL
);


ALTER TABLE public.article OWNER TO cuba;

--
-- Name: article_access; Type: TABLE; Schema: public; Owner: cuba; Tablespace: 
--

CREATE TABLE article_access (
    article_id integer NOT NULL,
    user_group_id integer NOT NULL,
    changed timestamp without time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.article_access OWNER TO cuba;

--
-- Name: article_id_seq; Type: SEQUENCE; Schema: public; Owner: cuba
--

CREATE SEQUENCE article_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    MINVALUE 1000
    CACHE 1;


ALTER TABLE public.article_id_seq OWNER TO cuba;

--
-- Name: article_version; Type: TABLE; Schema: public; Owner: paracelsus; Tablespace: 
--

CREATE TABLE article_version (
    article_version_id integer NOT NULL,
    article_id integer NOT NULL,
    version integer NOT NULL,
    user_group_id integer DEFAULT 0 NOT NULL,
    timestamp_created timestamp without time zone DEFAULT now() NOT NULL,
    dump text,
    action_type character varying(20)
);


ALTER TABLE public.article_version OWNER TO paracelsus;

--
-- Name: article_version_id_seq; Type: SEQUENCE; Schema: public; Owner: paracelsus
--

CREATE SEQUENCE article_version_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.article_version_id_seq OWNER TO paracelsus;

--
-- Name: asset; Type: TABLE; Schema: public; Owner: cuba; Tablespace: 
--

CREATE TABLE asset (
    asset_id integer NOT NULL,
    content_id integer NOT NULL,
    deleted boolean DEFAULT false NOT NULL,
    version integer DEFAULT 0 NOT NULL
);


ALTER TABLE public.asset OWNER TO cuba;

--
-- Name: asset_id_seq; Type: SEQUENCE; Schema: public; Owner: cuba
--

CREATE SEQUENCE asset_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    MINVALUE 1000
    CACHE 1;


ALTER TABLE public.asset_id_seq OWNER TO cuba;

--
-- Name: container; Type: TABLE; Schema: public; Owner: cuba; Tablespace: 
--

CREATE TABLE container (
    content_id_parent integer NOT NULL,
    content_id_child integer NOT NULL,
    sortpos smallint DEFAULT 0 NOT NULL,
    content_type character varying(50) DEFAULT 'content'::text NOT NULL
);


ALTER TABLE public.container OWNER TO cuba;

--
-- Name: media_asset; Type: TABLE; Schema: public; Owner: cuba; Tablespace: 
--

CREATE TABLE media_asset (
    media_asset_id integer NOT NULL,
    asset_id integer NOT NULL,
    mime character varying(100) NOT NULL,
    media_folder_id integer DEFAULT 0 NOT NULL,
    description text,
    user_submitted boolean DEFAULT false NOT NULL,
    filesize integer DEFAULT 0 NOT NULL,
    title character varying(300),
    extension character varying(8),
    original_filename character varying(255)
);


ALTER TABLE public.media_asset OWNER TO cuba;

--
-- Name: media_asset_download; Type: TABLE; Schema: public; Owner: paracelsus; Tablespace: 
--

CREATE TABLE media_asset_download (
    media_asset_download_id integer NOT NULL,
    user_group_id integer NOT NULL,
    "time" timestamp without time zone DEFAULT now() NOT NULL,
    media_asset_id integer
);


ALTER TABLE public.media_asset_download OWNER TO paracelsus;

--
-- Name: media_asset_download_id_seq; Type: SEQUENCE; Schema: public; Owner: paracelsus
--

CREATE SEQUENCE media_asset_download_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.media_asset_download_id_seq OWNER TO paracelsus;

--
-- Name: media_asset_folder; Type: TABLE; Schema: public; Owner: cuba; Tablespace: 
--

CREATE TABLE media_asset_folder (
    media_asset_folder_id integer NOT NULL,
    physical_path character varying(255) NOT NULL,
    media_folder_id__parent integer DEFAULT 0 NOT NULL,
    user_group_id integer DEFAULT 301 NOT NULL,
    access access_restriction DEFAULT ('PUBLIC'::character varying)::access_restriction NOT NULL,
    trashbin boolean DEFAULT false NOT NULL
);


ALTER TABLE public.media_asset_folder OWNER TO cuba;

--
-- Name: media_asset_folder_category; Type: TABLE; Schema: public; Owner: paracelsus; Tablespace: 
--

CREATE TABLE media_asset_folder_category (
    folder_category_id integer NOT NULL,
    media_asset_folder_id integer NOT NULL,
    category_id integer NOT NULL
);


ALTER TABLE public.media_asset_folder_category OWNER TO paracelsus;

--
-- Name: media_asset_folder_category_id_seq; Type: SEQUENCE; Schema: public; Owner: paracelsus
--

CREATE SEQUENCE media_asset_folder_category_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.media_asset_folder_category_id_seq OWNER TO paracelsus;

--
-- Name: media_asset_folder_id_seq; Type: SEQUENCE; Schema: public; Owner: cuba
--

CREATE SEQUENCE media_asset_folder_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    MINVALUE 300
    CACHE 1;


ALTER TABLE public.media_asset_folder_id_seq OWNER TO cuba;

--
-- Name: media_asset_id_seq; Type: SEQUENCE; Schema: public; Owner: cuba
--

CREATE SEQUENCE media_asset_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    MINVALUE 1000
    CACHE 1;


ALTER TABLE public.media_asset_id_seq OWNER TO cuba;

--
-- Name: media_asset_version; Type: TABLE; Schema: public; Owner: paracelsus; Tablespace: 
--

CREATE TABLE media_asset_version (
    media_asset_version_id integer NOT NULL,
    media_asset_id integer NOT NULL,
    version integer NOT NULL,
    timestamp_created timestamp without time zone DEFAULT now() NOT NULL,
    user_group_id integer DEFAULT 0 NOT NULL
);


ALTER TABLE public.media_asset_version OWNER TO paracelsus;

--
-- Name: media_asset_version_id_seq; Type: SEQUENCE; Schema: public; Owner: paracelsus
--

CREATE SEQUENCE media_asset_version_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


ALTER TABLE public.media_asset_version_id_seq OWNER TO paracelsus;

--
-- Name: text_asset; Type: TABLE; Schema: public; Owner: cuba; Tablespace: 
--

CREATE TABLE text_asset (
    text_asset_id integer NOT NULL,
    asset_id integer NOT NULL,
    text text,
    display_text text DEFAULT ''::text NOT NULL
);


ALTER TABLE public.text_asset OWNER TO cuba;

--
-- Name: text_asset_id_seq; Type: SEQUENCE; Schema: public; Owner: cuba
--

CREATE SEQUENCE text_asset_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    MINVALUE 1000
    CACHE 1;


ALTER TABLE public.text_asset_id_seq OWNER TO cuba;

--
-- Name: article_id; Type: CONSTRAINT; Schema: public; Owner: cuba; Tablespace: 
--

ALTER TABLE ONLY article
    ADD CONSTRAINT article_id PRIMARY KEY (article_id);


--
-- Name: asset_id; Type: CONSTRAINT; Schema: public; Owner: cuba; Tablespace: 
--

ALTER TABLE ONLY asset
    ADD CONSTRAINT asset_id PRIMARY KEY (asset_id);


--
-- Name: container_id; Type: CONSTRAINT; Schema: public; Owner: cuba; Tablespace: 
--

ALTER TABLE ONLY container
    ADD CONSTRAINT container_id PRIMARY KEY (content_id_parent, content_id_child);


--
-- Name: media_asset_folder_id; Type: CONSTRAINT; Schema: public; Owner: cuba; Tablespace: 
--

ALTER TABLE ONLY media_asset_folder
    ADD CONSTRAINT media_asset_folder_id PRIMARY KEY (media_asset_folder_id);


--
-- Name: text_asset_id; Type: CONSTRAINT; Schema: public; Owner: cuba; Tablespace: 
--

ALTER TABLE ONLY text_asset
    ADD CONSTRAINT text_asset_id PRIMARY KEY (text_asset_id);


--
-- Name: article_content_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: cuba
--

ALTER TABLE ONLY article
    ADD CONSTRAINT article_content_id_fkey FOREIGN KEY (content_id) REFERENCES content(content_id);


--
-- Name: asset_fk; Type: FK CONSTRAINT; Schema: public; Owner: cuba
--

ALTER TABLE ONLY media_asset
    ADD CONSTRAINT asset_fk FOREIGN KEY (asset_id) REFERENCES asset(asset_id);


--
-- Name: asset_id; Type: FK CONSTRAINT; Schema: public; Owner: cuba
--

ALTER TABLE ONLY media_asset
    ADD CONSTRAINT asset_id FOREIGN KEY (asset_id) REFERENCES asset(asset_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: asset_id; Type: FK CONSTRAINT; Schema: public; Owner: cuba
--

ALTER TABLE ONLY text_asset
    ADD CONSTRAINT asset_id FOREIGN KEY (asset_id) REFERENCES asset(asset_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: content_fk; Type: FK CONSTRAINT; Schema: public; Owner: cuba
--

ALTER TABLE ONLY asset
    ADD CONSTRAINT content_fk FOREIGN KEY (content_id) REFERENCES content(content_id);


--
-- Name: content_fk; Type: FK CONSTRAINT; Schema: public; Owner: cuba
--

ALTER TABLE ONLY article
    ADD CONSTRAINT content_fk FOREIGN KEY (content_id) REFERENCES content(content_id);


--
-- Name: content_id_child; Type: FK CONSTRAINT; Schema: public; Owner: cuba
--

ALTER TABLE ONLY container
    ADD CONSTRAINT content_id_child FOREIGN KEY (content_id_child) REFERENCES content(content_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: content_id_parent; Type: FK CONSTRAINT; Schema: public; Owner: cuba
--

ALTER TABLE ONLY container
    ADD CONSTRAINT content_id_parent FOREIGN KEY (content_id_parent) REFERENCES content(content_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: media_asset_asset_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: cuba
--

ALTER TABLE ONLY media_asset
    ADD CONSTRAINT media_asset_asset_id_fkey FOREIGN KEY (asset_id) REFERENCES asset(asset_id);


--
-- Name: text_asset_asset_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: cuba
--

ALTER TABLE ONLY text_asset
    ADD CONSTRAINT text_asset_asset_id_fkey FOREIGN KEY (asset_id) REFERENCES asset(asset_id);


--
-- Name: article_version; Type: ACL; Schema: public; Owner: paracelsus
--

REVOKE ALL ON TABLE article_version FROM PUBLIC;
REVOKE ALL ON TABLE article_version FROM paracelsus;
GRANT ALL ON TABLE article_version TO paracelsus;
GRANT ALL ON TABLE article_version TO cuba;


--
-- Name: article_version_id_seq; Type: ACL; Schema: public; Owner: paracelsus
--

REVOKE ALL ON SEQUENCE article_version_id_seq FROM PUBLIC;
REVOKE ALL ON SEQUENCE article_version_id_seq FROM paracelsus;
GRANT ALL ON SEQUENCE article_version_id_seq TO paracelsus;
GRANT ALL ON SEQUENCE article_version_id_seq TO cuba;


--
-- Name: media_asset_download; Type: ACL; Schema: public; Owner: paracelsus
--

REVOKE ALL ON TABLE media_asset_download FROM PUBLIC;
REVOKE ALL ON TABLE media_asset_download FROM paracelsus;
GRANT ALL ON TABLE media_asset_download TO paracelsus;
GRANT ALL ON TABLE media_asset_download TO cuba;


--
-- Name: media_asset_download_id_seq; Type: ACL; Schema: public; Owner: paracelsus
--

REVOKE ALL ON SEQUENCE media_asset_download_id_seq FROM PUBLIC;
REVOKE ALL ON SEQUENCE media_asset_download_id_seq FROM paracelsus;
GRANT ALL ON SEQUENCE media_asset_download_id_seq TO paracelsus;
GRANT ALL ON SEQUENCE media_asset_download_id_seq TO cuba;


--
-- Name: media_asset_folder; Type: ACL; Schema: public; Owner: cuba
--

REVOKE ALL ON TABLE media_asset_folder FROM PUBLIC;
REVOKE ALL ON TABLE media_asset_folder FROM cuba;
GRANT ALL ON TABLE media_asset_folder TO cuba;
GRANT ALL ON TABLE media_asset_folder TO PUBLIC;


--
-- Name: media_asset_folder_category; Type: ACL; Schema: public; Owner: paracelsus
--

REVOKE ALL ON TABLE media_asset_folder_category FROM PUBLIC;
REVOKE ALL ON TABLE media_asset_folder_category FROM paracelsus;
GRANT ALL ON TABLE media_asset_folder_category TO paracelsus;
GRANT ALL ON TABLE media_asset_folder_category TO cuba;


--
-- Name: media_asset_folder_category_id_seq; Type: ACL; Schema: public; Owner: paracelsus
--

REVOKE ALL ON SEQUENCE media_asset_folder_category_id_seq FROM PUBLIC;
REVOKE ALL ON SEQUENCE media_asset_folder_category_id_seq FROM paracelsus;
GRANT ALL ON SEQUENCE media_asset_folder_category_id_seq TO paracelsus;
GRANT ALL ON SEQUENCE media_asset_folder_category_id_seq TO cuba;


--
-- Name: media_asset_version; Type: ACL; Schema: public; Owner: paracelsus
--

REVOKE ALL ON TABLE media_asset_version FROM PUBLIC;
REVOKE ALL ON TABLE media_asset_version FROM paracelsus;
GRANT ALL ON TABLE media_asset_version TO paracelsus;
GRANT ALL ON TABLE media_asset_version TO cuba;


--
-- Name: media_asset_version_id_seq; Type: ACL; Schema: public; Owner: paracelsus
--

REVOKE ALL ON SEQUENCE media_asset_version_id_seq FROM PUBLIC;
REVOKE ALL ON SEQUENCE media_asset_version_id_seq FROM paracelsus;
GRANT ALL ON SEQUENCE media_asset_version_id_seq TO paracelsus;
GRANT ALL ON SEQUENCE media_asset_version_id_seq TO cuba;


--
-- PostgreSQL database dump complete
--

