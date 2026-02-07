--
-- PostgreSQL database dump
--

\restrict aaQbY1eNe8IThppFNpOCsYbDkstx6xKrLFF0GqrUCZwII0KWVix9cVlu5VHDqFE

-- Dumped from database version 18.1
-- Dumped by pg_dump version 18.1

-- Started on 2026-02-05 17:36:16 EET

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- TOC entry 5 (class 2615 OID 2200)
-- Name: public; Type: SCHEMA; Schema: -; Owner: pg_database_owner
--

CREATE SCHEMA public;


ALTER SCHEMA public OWNER TO pg_database_owner;

--
-- TOC entry 3548 (class 0 OID 0)
-- Dependencies: 5
-- Name: SCHEMA public; Type: COMMENT; Schema: -; Owner: pg_database_owner
--

COMMENT ON SCHEMA public IS 'standard public schema';


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 222 (class 1259 OID 16441)
-- Name: irasas; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.irasas (
    id integer NOT NULL,
    id_dokumento text NOT NULL,
    pavadinimas text NOT NULL,
    pradzia date NOT NULL,
    pabaiga date NOT NULL
);


ALTER TABLE public.irasas OWNER TO postgres;

--
-- TOC entry 221 (class 1259 OID 16440)
-- Name: irasas_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.irasas ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.irasas_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 220 (class 1259 OID 16427)
-- Name: naudotojas; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.naudotojas (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    vardas character varying(30) NOT NULL,
    pavarde character varying(30) NOT NULL,
    gimimo_data date NOT NULL,
    adminas boolean DEFAULT false NOT NULL,
    password_hash character varying(200) NOT NULL
);


ALTER TABLE public.naudotojas OWNER TO postgres;

--
-- TOC entry 224 (class 1259 OID 16454)
-- Name: testas; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.testas (
    id integer NOT NULL,
    testotekstas text NOT NULL,
    atliktas boolean DEFAULT false NOT NULL
);


ALTER TABLE public.testas OWNER TO postgres;

--
-- TOC entry 223 (class 1259 OID 16453)
-- Name: testas_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.testas ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.testas_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 225 (class 1259 OID 16470)
-- Name: testasirasas; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.testasirasas (
    testasid integer NOT NULL,
    irasasid integer NOT NULL
);


ALTER TABLE public.testasirasas OWNER TO postgres;

--
-- TOC entry 3539 (class 0 OID 16441)
-- Dependencies: 222
-- Data for Name: irasas; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.irasas (id, id_dokumento, pavadinimas, pradzia, pabaiga) FROM stdin;
\.


--
-- TOC entry 3537 (class 0 OID 16427)
-- Dependencies: 220
-- Data for Name: naudotojas; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.naudotojas (id, vardas, pavarde, gimimo_data, adminas, password_hash) FROM stdin;
\.


--
-- TOC entry 3541 (class 0 OID 16454)
-- Dependencies: 224
-- Data for Name: testas; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.testas (id, testotekstas, atliktas) FROM stdin;
\.


--
-- TOC entry 3542 (class 0 OID 16470)
-- Dependencies: 225
-- Data for Name: testasirasas; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.testasirasas (testasid, irasasid) FROM stdin;
\.


--
-- TOC entry 3549 (class 0 OID 0)
-- Dependencies: 221
-- Name: irasas_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.irasas_id_seq', 1, false);


--
-- TOC entry 3550 (class 0 OID 0)
-- Dependencies: 223
-- Name: testas_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.testas_id_seq', 1, false);


--
-- TOC entry 3383 (class 2606 OID 16452)
-- Name: irasas irasas_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.irasas
    ADD CONSTRAINT irasas_pkey PRIMARY KEY (id);


--
-- TOC entry 3381 (class 2606 OID 16439)
-- Name: naudotojas naudotojas_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.naudotojas
    ADD CONSTRAINT naudotojas_pkey PRIMARY KEY (id);


--
-- TOC entry 3385 (class 2606 OID 16464)
-- Name: testas testas_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.testas
    ADD CONSTRAINT testas_pkey PRIMARY KEY (id);


--
-- TOC entry 3387 (class 2606 OID 16476)
-- Name: testasirasas testasirasas_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.testasirasas
    ADD CONSTRAINT testasirasas_pkey PRIMARY KEY (testasid, irasasid);


--
-- TOC entry 3388 (class 2606 OID 16482)
-- Name: testasirasas testasirasas_irasasid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.testasirasas
    ADD CONSTRAINT testasirasas_irasasid_fkey FOREIGN KEY (irasasid) REFERENCES public.irasas(id) ON DELETE CASCADE;


--
-- TOC entry 3389 (class 2606 OID 16477)
-- Name: testasirasas testasirasas_testasid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.testasirasas
    ADD CONSTRAINT testasirasas_testasid_fkey FOREIGN KEY (testasid) REFERENCES public.testas(id) ON DELETE CASCADE;


-- Completed on 2026-02-05 17:36:16 EET

--
-- PostgreSQL database dump complete
--

\unrestrict aaQbY1eNe8IThppFNpOCsYbDkstx6xKrLFF0GqrUCZwII0KWVix9cVlu5VHDqFE

