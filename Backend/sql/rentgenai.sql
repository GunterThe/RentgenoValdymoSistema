--
-- PostgreSQL database dump
--

\restrict kJDWffnXuWPuK0eHCOony1b49ZpLHSVyLwaAPUNx5FivKrAjC2W3fGtDvSKP3IG

-- Dumped from database version 18.1
-- Dumped by pg_dump version 18.1

-- Started on 2026-02-16 16:30:41 EET

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
-- TOC entry 2 (class 3079 OID 16389)
-- Name: pgcrypto; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA public;


--
-- TOC entry 3565 (class 0 OID 0)
-- Dependencies: 2
-- Name: EXTENSION pgcrypto; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION pgcrypto IS 'cryptographic functions';


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
    password_hash character varying(200) NOT NULL,
    prisijungimoid text
);


ALTER TABLE public.naudotojas OWNER TO postgres;

--
-- TOC entry 226 (class 1259 OID 16487)
-- Name: prisegtasfailas; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.prisegtasfailas (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    irasasid integer,
    failopav text,
    dydis bigint,
    nuoroda text,
    sukurimolaikas date
);


ALTER TABLE public.prisegtasfailas OWNER TO postgres;

--
-- TOC entry 227 (class 1259 OID 16523)
-- Name: refreshtoken; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.refreshtoken (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    token text NOT NULL,
    expires date NOT NULL,
    revoked date,
    naudotojasid uuid
);


ALTER TABLE public.refreshtoken OWNER TO postgres;

--
-- TOC entry 224 (class 1259 OID 16454)
-- Name: testas; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.testas (
    id integer NOT NULL,
    testotekstas text NOT NULL
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
    irasasid integer NOT NULL,
    atliktas boolean
);


ALTER TABLE public.testasirasas OWNER TO postgres;

--
-- TOC entry 3554 (class 0 OID 16441)
-- Dependencies: 222
-- Data for Name: irasas; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.irasas (id, id_dokumento, pavadinimas, pradzia, pabaiga) FROM stdin;
1	buh	buh	2026-02-09	2026-02-09
\.


--
-- TOC entry 3552 (class 0 OID 16427)
-- Dependencies: 220
-- Data for Name: naudotojas; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.naudotojas (id, vardas, pavarde, gimimo_data, adminas, password_hash, prisijungimoid) FROM stdin;
\.


--
-- TOC entry 3558 (class 0 OID 16487)
-- Dependencies: 226
-- Data for Name: prisegtasfailas; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.prisegtasfailas (id, irasasid, failopav, dydis, nuoroda, sukurimolaikas) FROM stdin;
\.


--
-- TOC entry 3559 (class 0 OID 16523)
-- Dependencies: 227
-- Data for Name: refreshtoken; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.refreshtoken (id, token, expires, revoked, naudotojasid) FROM stdin;
\.


--
-- TOC entry 3556 (class 0 OID 16454)
-- Dependencies: 224
-- Data for Name: testas; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.testas (id, testotekstas) FROM stdin;
1	Cum
2	Jo
3	labas
\.


--
-- TOC entry 3557 (class 0 OID 16470)
-- Dependencies: 225
-- Data for Name: testasirasas; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.testasirasas (testasid, irasasid, atliktas) FROM stdin;
2	1	t
3	1	f
1	1	t
\.


--
-- TOC entry 3566 (class 0 OID 0)
-- Dependencies: 221
-- Name: irasas_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.irasas_id_seq', 1, true);


--
-- TOC entry 3567 (class 0 OID 0)
-- Dependencies: 223
-- Name: testas_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.testas_id_seq', 3, true);


--
-- TOC entry 3392 (class 2606 OID 16452)
-- Name: irasas irasas_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.irasas
    ADD CONSTRAINT irasas_pkey PRIMARY KEY (id);


--
-- TOC entry 3390 (class 2606 OID 16439)
-- Name: naudotojas naudotojas_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.naudotojas
    ADD CONSTRAINT naudotojas_pkey PRIMARY KEY (id);


--
-- TOC entry 3398 (class 2606 OID 16495)
-- Name: prisegtasfailas prisegtasfailas_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.prisegtasfailas
    ADD CONSTRAINT prisegtasfailas_pkey PRIMARY KEY (id);


--
-- TOC entry 3400 (class 2606 OID 16533)
-- Name: refreshtoken refreshtoken_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.refreshtoken
    ADD CONSTRAINT refreshtoken_pkey PRIMARY KEY (id);


--
-- TOC entry 3394 (class 2606 OID 16464)
-- Name: testas testas_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.testas
    ADD CONSTRAINT testas_pkey PRIMARY KEY (id);


--
-- TOC entry 3396 (class 2606 OID 16476)
-- Name: testasirasas testasirasas_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.testasirasas
    ADD CONSTRAINT testasirasas_pkey PRIMARY KEY (testasid, irasasid);


--
-- TOC entry 3403 (class 2606 OID 16496)
-- Name: prisegtasfailas prisegtasfailas_irasasid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.prisegtasfailas
    ADD CONSTRAINT prisegtasfailas_irasasid_fkey FOREIGN KEY (irasasid) REFERENCES public.irasas(id) ON DELETE CASCADE;


--
-- TOC entry 3404 (class 2606 OID 16534)
-- Name: refreshtoken refreshtoken_naudotojasid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.refreshtoken
    ADD CONSTRAINT refreshtoken_naudotojasid_fkey FOREIGN KEY (naudotojasid) REFERENCES public.naudotojas(id) ON DELETE CASCADE;


--
-- TOC entry 3401 (class 2606 OID 16482)
-- Name: testasirasas testasirasas_irasasid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.testasirasas
    ADD CONSTRAINT testasirasas_irasasid_fkey FOREIGN KEY (irasasid) REFERENCES public.irasas(id) ON DELETE CASCADE;


--
-- TOC entry 3402 (class 2606 OID 16477)
-- Name: testasirasas testasirasas_testasid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.testasirasas
    ADD CONSTRAINT testasirasas_testasid_fkey FOREIGN KEY (testasid) REFERENCES public.testas(id) ON DELETE CASCADE;


-- Completed on 2026-02-16 16:30:41 EET

--
-- PostgreSQL database dump complete
--

\unrestrict kJDWffnXuWPuK0eHCOony1b49ZpLHSVyLwaAPUNx5FivKrAjC2W3fGtDvSKP3IG

