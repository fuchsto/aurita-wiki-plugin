--
-- PostgreSQL database dump
--

SET statement_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = off;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET escape_string_warning = off;

SET search_path = public, pg_catalog;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: media_asset_request; Type: TABLE; Schema: public; Owner: fuchsto; Tablespace: 
--

CREATE TABLE media_asset_request (
    media_asset_request_id integer NOT NULL,
    media_asset_id integer NOT NULL,
    user_group_id integer NOT NULL,
    time_requested timestamp without time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.media_asset_request OWNER TO fuchsto;

--
-- Name: media_asset_request_media_asset_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: fuchsto
--

ALTER TABLE ONLY media_asset_request
    ADD CONSTRAINT media_asset_request_media_asset_id_fkey FOREIGN KEY (media_asset_id) REFERENCES media_asset(media_asset_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: media_asset_request_user_group_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: fuchsto
--

ALTER TABLE ONLY media_asset_request
    ADD CONSTRAINT media_asset_request_user_group_id_fkey FOREIGN KEY (user_group_id) REFERENCES internal.user_group(user_group_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: media_asset_request; Type: ACL; Schema: public; Owner: fuchsto
--

REVOKE ALL ON TABLE media_asset_request FROM PUBLIC;
REVOKE ALL ON TABLE media_asset_request FROM fuchsto;
GRANT ALL ON TABLE media_asset_request TO fuchsto;
GRANT ALL ON TABLE media_asset_request TO aurita;


--
-- PostgreSQL database dump complete
--

