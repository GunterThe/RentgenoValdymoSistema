--
-- PostgreSQL database dump
--

\restrict 5Wu1ZhaA9knqFx4ZegfH5vsT9GqatysxJgZeihEagXoMdiAihn2f9vf7gtloaK9

-- Dumped from database version 18.2
-- Dumped by pg_dump version 18.2

-- Started on 2026-02-24 17:11:45 EET

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
-- TOC entry 2 (class 3079 OID 16570)
-- Name: pgcrypto; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA public;


--
-- TOC entry 3576 (class 0 OID 0)
-- Dependencies: 2
-- Name: EXTENSION pgcrypto; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION pgcrypto IS 'cryptographic functions';


--
-- TOC entry 916 (class 1247 OID 16694)
-- Name: testotipas; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.testotipas AS ENUM (
    'testas',
    'isvezimas',
    'pakavimas'
);


ALTER TYPE public.testotipas OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 220 (class 1259 OID 16608)
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
-- TOC entry 221 (class 1259 OID 16618)
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
-- TOC entry 222 (class 1259 OID 16619)
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
-- TOC entry 223 (class 1259 OID 16632)
-- Name: prisegtasfailas; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.prisegtasfailas (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    failopav text,
    dydis bigint,
    nuoroda text,
    sukurimolaikas date,
    zingsnis_id integer
);


ALTER TABLE public.prisegtasfailas OWNER TO postgres;

--
-- TOC entry 224 (class 1259 OID 16639)
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
-- TOC entry 225 (class 1259 OID 16648)
-- Name: testas; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.testas (
    id integer NOT NULL,
    testotekstas text NOT NULL,
    tipas public.testotipas
);


ALTER TABLE public.testas OWNER TO postgres;

--
-- TOC entry 226 (class 1259 OID 16655)
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
-- TOC entry 227 (class 1259 OID 16656)
-- Name: testasirasas; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.testasirasas (
    testasid integer NOT NULL,
    irasasid integer NOT NULL
);


ALTER TABLE public.testasirasas OWNER TO postgres;

--
-- TOC entry 228 (class 1259 OID 16712)
-- Name: zingsnis; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.zingsnis (
    id integer NOT NULL,
    tekstas text NOT NULL,
    komentaras text NOT NULL,
    pabaigtas boolean NOT NULL,
    testas_id integer
);


ALTER TABLE public.zingsnis OWNER TO postgres;

--
-- TOC entry 3562 (class 0 OID 16608)
-- Dependencies: 220
-- Data for Name: irasas; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.irasas (id, id_dokumento, pavadinimas, pradzia, pabaiga) FROM stdin;
3	jo	jo	2026-02-21	2026-02-21
1	buh	buh	2026-02-09	2026-02-09
\.


--
-- TOC entry 3564 (class 0 OID 16619)
-- Dependencies: 222
-- Data for Name: naudotojas; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.naudotojas (id, vardas, pavarde, gimimo_data, adminas, password_hash, prisijungimoid) FROM stdin;
3fa85f64-5717-4562-b3fc-2c963f66afa6	Jonas	Jonaitis	2026-02-21	t	$2a$11$MirpBys88FNoulE9ZNSB7OCLe7090D7JGj3hNsrNf9Y0sXVXl0Iu2	jonas.jonaitis.3f25d9
811e41c3-49b7-4496-8f72-a4bcdb53d405	Petras	Petraitis	2026-02-21	f	$2a$11$IXFRcEd.VMKt2TmHkWMjbuLxxCgI3GOGmHhhXi..d/wUHVmKctQWC	petras.petraitis.8a192e
\.


--
-- TOC entry 3565 (class 0 OID 16632)
-- Dependencies: 223
-- Data for Name: prisegtasfailas; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.prisegtasfailas (id, failopav, dydis, nuoroda, sukurimolaikas, zingsnis_id) FROM stdin;
0695d72a-e7fe-4380-906e-156162ead170	agemasen (1).png	26567	uploads/57b62e5e-ce1d-43f5-a446-2b17c973e24f.png	2026-02-21	\N
\.


--
-- TOC entry 3566 (class 0 OID 16639)
-- Dependencies: 224
-- Data for Name: refreshtoken; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.refreshtoken (id, token, expires, revoked, naudotojasid) FROM stdin;
\.


--
-- TOC entry 3567 (class 0 OID 16648)
-- Dependencies: 225
-- Data for Name: testas; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.testas (id, testotekstas, tipas) FROM stdin;
2	Jo	testas
3	labas	testas
1	Cum	isvezimas
\.


--
-- TOC entry 3569 (class 0 OID 16656)
-- Dependencies: 227
-- Data for Name: testasirasas; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.testasirasas (testasid, irasasid) FROM stdin;
2	1
3	1
1	1
\.


--
-- TOC entry 3570 (class 0 OID 16712)
-- Dependencies: 228
-- Data for Name: zingsnis; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.zingsnis (id, tekstas, komentaras, pabaigtas, testas_id) FROM stdin;
\.


--
-- TOC entry 3577 (class 0 OID 0)
-- Dependencies: 221
-- Name: irasas_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.irasas_id_seq', 3, true);


--
-- TOC entry 3578 (class 0 OID 0)
-- Dependencies: 226
-- Name: testas_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.testas_id_seq', 3, true);


--
-- TOC entry 3397 (class 2606 OID 16662)
-- Name: irasas irasas_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.irasas
    ADD CONSTRAINT irasas_pkey PRIMARY KEY (id);


--
-- TOC entry 3399 (class 2606 OID 16664)
-- Name: naudotojas naudotojas_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.naudotojas
    ADD CONSTRAINT naudotojas_pkey PRIMARY KEY (id);


--
-- TOC entry 3401 (class 2606 OID 16666)
-- Name: prisegtasfailas prisegtasfailas_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.prisegtasfailas
    ADD CONSTRAINT prisegtasfailas_pkey PRIMARY KEY (id);


--
-- TOC entry 3403 (class 2606 OID 16668)
-- Name: refreshtoken refreshtoken_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.refreshtoken
    ADD CONSTRAINT refreshtoken_pkey PRIMARY KEY (id);


--
-- TOC entry 3405 (class 2606 OID 16670)
-- Name: testas testas_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.testas
    ADD CONSTRAINT testas_pkey PRIMARY KEY (id);


--
-- TOC entry 3407 (class 2606 OID 16672)
-- Name: testasirasas testasirasas_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.testasirasas
    ADD CONSTRAINT testasirasas_pkey PRIMARY KEY (testasid, irasasid);


--
-- TOC entry 3409 (class 2606 OID 16722)
-- Name: zingsnis zingsnis_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.zingsnis
    ADD CONSTRAINT zingsnis_pkey PRIMARY KEY (id);


--
-- TOC entry 3410 (class 2606 OID 16728)
-- Name: prisegtasfailas fk_prisegtas_zingsnis; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.prisegtasfailas
    ADD CONSTRAINT fk_prisegtas_zingsnis FOREIGN KEY (zingsnis_id) REFERENCES public.zingsnis(id) ON DELETE CASCADE;


--
-- TOC entry 3414 (class 2606 OID 16723)
-- Name: zingsnis fk_zingsnis_testas; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.zingsnis
    ADD CONSTRAINT fk_zingsnis_testas FOREIGN KEY (testas_id) REFERENCES public.testas(id) ON DELETE CASCADE;


--
-- TOC entry 3411 (class 2606 OID 16678)
-- Name: refreshtoken refreshtoken_naudotojasid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.refreshtoken
    ADD CONSTRAINT refreshtoken_naudotojasid_fkey FOREIGN KEY (naudotojasid) REFERENCES public.naudotojas(id) ON DELETE CASCADE;


--
-- TOC entry 3412 (class 2606 OID 16683)
-- Name: testasirasas testasirasas_irasasid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.testasirasas
    ADD CONSTRAINT testasirasas_irasasid_fkey FOREIGN KEY (irasasid) REFERENCES public.irasas(id) ON DELETE CASCADE;


--
-- TOC entry 3413 (class 2606 OID 16688)
-- Name: testasirasas testasirasas_testasid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.testasirasas
    ADD CONSTRAINT testasirasas_testasid_fkey FOREIGN KEY (testasid) REFERENCES public.testas(id) ON DELETE CASCADE;


-- Completed on 2026-02-24 17:11:45 EET

--
-- PostgreSQL database dump complete
--

\unrestrict 5Wu1ZhaA9knqFx4ZegfH5vsT9GqatysxJgZeihEagXoMdiAihn2f9vf7gtloaK9

