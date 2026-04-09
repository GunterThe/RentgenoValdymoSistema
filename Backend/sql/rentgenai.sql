--
-- PostgreSQL database dump
--

\restrict GT9z8HDXOi7iO6R4CSt3fXgCojlUMAXqfsGmecQnaCIZPO7yCgkmdue8RPJ5Fun

-- Dumped from database version 18.3
-- Dumped by pg_dump version 18.3

-- Started on 2026-04-09 13:48:14 EEST

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
-- TOC entry 3625 (class 0 OID 0)
-- Dependencies: 2
-- Name: EXTENSION pgcrypto; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION pgcrypto IS 'cryptographic functions';


--
-- TOC entry 925 (class 1247 OID 16694)
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
    pradzia date,
    pabaiga date,
    statusas text,
    lokacija_id integer
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
-- TOC entry 234 (class 1259 OID 16774)
-- Name: lokacija; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.lokacija (
    id integer NOT NULL,
    pavadinimas text NOT NULL
);


ALTER TABLE public.lokacija OWNER TO postgres;

--
-- TOC entry 233 (class 1259 OID 16773)
-- Name: lokacija_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.lokacija_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.lokacija_id_seq OWNER TO postgres;

--
-- TOC entry 3626 (class 0 OID 0)
-- Dependencies: 233
-- Name: lokacija_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.lokacija_id_seq OWNED BY public.lokacija.id;


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
    prisijungimoid text,
    super_adminas boolean
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
    zingsnis_id integer,
    zingsnis_template_id integer
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
-- TOC entry 236 (class 1259 OID 16790)
-- Name: sablonas; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.sablonas (
    id integer NOT NULL,
    pavadinimas text NOT NULL
);


ALTER TABLE public.sablonas OWNER TO postgres;

--
-- TOC entry 235 (class 1259 OID 16789)
-- Name: sablonas_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.sablonas_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.sablonas_id_seq OWNER TO postgres;

--
-- TOC entry 3627 (class 0 OID 0)
-- Dependencies: 235
-- Name: sablonas_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.sablonas_id_seq OWNED BY public.sablonas.id;


--
-- TOC entry 237 (class 1259 OID 16801)
-- Name: sablonas_testas; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.sablonas_testas (
    testasid integer NOT NULL,
    sablonasid integer NOT NULL
);


ALTER TABLE public.sablonas_testas OWNER TO postgres;

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
    irasasid integer NOT NULL,
    id integer NOT NULL,
    eile integer
);


ALTER TABLE public.testasirasas OWNER TO postgres;

--
-- TOC entry 230 (class 1259 OID 16751)
-- Name: testasirasas_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.testasirasas ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.testasirasas_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 228 (class 1259 OID 16712)
-- Name: zingsnis; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.zingsnis (
    id integer NOT NULL,
    komentaras text NOT NULL,
    irasas_testas_id integer,
    zingsnis_template_id integer,
    completed_by_user_id uuid,
    completed_at timestamp without time zone
);


ALTER TABLE public.zingsnis OWNER TO postgres;

--
-- TOC entry 232 (class 1259 OID 16772)
-- Name: zingsnis_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.zingsnis ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.zingsnis_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 229 (class 1259 OID 16733)
-- Name: zingsnis_template; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.zingsnis_template (
    id integer NOT NULL,
    testas_id integer,
    pavadinimas text,
    aprasymas text,
    eile integer,
    nuotrauka_privaloma boolean,
    komentaras_privalomas boolean
);


ALTER TABLE public.zingsnis_template OWNER TO postgres;

--
-- TOC entry 231 (class 1259 OID 16771)
-- Name: zingsnis_template_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.zingsnis_template ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.zingsnis_template_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 3417 (class 2604 OID 16777)
-- Name: lokacija id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.lokacija ALTER COLUMN id SET DEFAULT nextval('public.lokacija_id_seq'::regclass);


--
-- TOC entry 3418 (class 2604 OID 16793)
-- Name: sablonas id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sablonas ALTER COLUMN id SET DEFAULT nextval('public.sablonas_id_seq'::regclass);


--
-- TOC entry 3602 (class 0 OID 16608)
-- Dependencies: 220
-- Data for Name: irasas; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.irasas (id, id_dokumento, pavadinimas, pradzia, pabaiga, statusas, lokacija_id) FROM stdin;
10	dsadasd	dsadsa	2026-04-08	\N	Ant xddd testo 4 žingsnio	1
\.


--
-- TOC entry 3616 (class 0 OID 16774)
-- Dependencies: 234
-- Data for Name: lokacija; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.lokacija (id, pavadinimas) FROM stdin;
1	lokacija1
2	lokacija2
\.


--
-- TOC entry 3604 (class 0 OID 16619)
-- Dependencies: 222
-- Data for Name: naudotojas; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.naudotojas (id, vardas, pavarde, gimimo_data, adminas, password_hash, prisijungimoid, super_adminas) FROM stdin;
a88fdd28-7be1-4c55-9b76-cf8f6d14410d	Gitanas	Nauseda	2026-04-08	f	$2a$11$hn2iio2OWlaVrBWiQUUrE.1oD5OKSZtrWk2Q5TH8yJHsxOu8FCYdW	gitanas.nauseda.e92	f
3fa85f64-5717-4562-b3fc-2c963f66afa6	Jonas	Jonaitis	2026-02-21	t	$2a$11$XOluA5qHy5wV7Y.twmVgLOjO3EvrsWAfk2ypmioAk1D0T.SWoEJjS	jonas.jonaitis.3f25d9	t
b9d2cadb-89a2-47f2-9a4a-cc87d1e850a5	jo	jo	2008-04-01	t	$2a$11$DowJr28AAMD75jQbmqgdy.ptJJorPzod5dMk.th37crlk.jwkkuie	jo.jo.33b	f
811e41c3-49b7-4496-8f72-a4bcdb53d405	Petras	Petraitis	2026-02-21	f	$2a$11$VfBvXJOKJSMvJ0rIpBLWleootCif2MfvYgVgQoZnceHcd3d/s0STm	petras.petraitis.8a192e	f
\.


--
-- TOC entry 3605 (class 0 OID 16632)
-- Dependencies: 223
-- Data for Name: prisegtasfailas; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.prisegtasfailas (id, failopav, dydis, nuoroda, sukurimolaikas, zingsnis_id, zingsnis_template_id) FROM stdin;
0695d72a-e7fe-4380-906e-156162ead170	agemasen (1).png	26567	uploads/57b62e5e-ce1d-43f5-a446-2b17c973e24f.png	2026-02-21	\N	\N
a84018ad-0b7a-4f9f-baba-e3bcead71a8a	buh2.png	2756095	uploads/17f54280-abf1-4b9c-beef-61efa6a90917.png	2026-04-08	15	\N
13998cd4-6106-4065-9e88-f342f9ff7118	buh2.png	2756095	uploads/02675a60-f0c3-4004-9c2a-185107304a7e.png	2026-04-08	17	\N
108a3542-6468-4260-af36-185c4dc38a30	WHAT.png	585004	uploads/templates/3e2e4ee9-e7b9-4c2b-a438-97fba9c9138b.png	2026-04-08	\N	21
\.


--
-- TOC entry 3606 (class 0 OID 16639)
-- Dependencies: 224
-- Data for Name: refreshtoken; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.refreshtoken (id, token, expires, revoked, naudotojasid) FROM stdin;
\.


--
-- TOC entry 3618 (class 0 OID 16790)
-- Dependencies: 236
-- Data for Name: sablonas; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.sablonas (id, pavadinimas) FROM stdin;
\.


--
-- TOC entry 3619 (class 0 OID 16801)
-- Dependencies: 237
-- Data for Name: sablonas_testas; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.sablonas_testas (testasid, sablonasid) FROM stdin;
\.


--
-- TOC entry 3607 (class 0 OID 16648)
-- Dependencies: 225
-- Data for Name: testas; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.testas (id, testotekstas, tipas) FROM stdin;
10	xddd	testas
\.


--
-- TOC entry 3609 (class 0 OID 16656)
-- Dependencies: 227
-- Data for Name: testasirasas; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.testasirasas (testasid, irasasid, id, eile) FROM stdin;
10	10	13	1
\.


--
-- TOC entry 3610 (class 0 OID 16712)
-- Dependencies: 228
-- Data for Name: zingsnis; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.zingsnis (id, komentaras, irasas_testas_id, zingsnis_template_id, completed_by_user_id, completed_at) FROM stdin;
15	-	13	21	811e41c3-49b7-4496-8f72-a4bcdb53d405	2026-04-08 13:02:34.091
16	-	13	22	811e41c3-49b7-4496-8f72-a4bcdb53d405	2026-04-08 13:02:42.409
17	d	13	23	811e41c3-49b7-4496-8f72-a4bcdb53d405	2026-04-08 13:02:59.378
\.


--
-- TOC entry 3611 (class 0 OID 16733)
-- Dependencies: 229
-- Data for Name: zingsnis_template; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.zingsnis_template (id, testas_id, pavadinimas, aprasymas, eile, nuotrauka_privaloma, komentaras_privalomas) FROM stdin;
21	10	buh123	buh123	1	t	f
22	10	1	1	2	f	f
23	10	2	2	3	f	t
24	10	3	3	4	t	t
\.


--
-- TOC entry 3628 (class 0 OID 0)
-- Dependencies: 221
-- Name: irasas_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.irasas_id_seq', 10, true);


--
-- TOC entry 3629 (class 0 OID 0)
-- Dependencies: 233
-- Name: lokacija_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.lokacija_id_seq', 1, true);


--
-- TOC entry 3630 (class 0 OID 0)
-- Dependencies: 235
-- Name: sablonas_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.sablonas_id_seq', 1, true);


--
-- TOC entry 3631 (class 0 OID 0)
-- Dependencies: 226
-- Name: testas_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.testas_id_seq', 10, true);


--
-- TOC entry 3632 (class 0 OID 0)
-- Dependencies: 230
-- Name: testasirasas_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.testasirasas_id_seq', 13, true);


--
-- TOC entry 3633 (class 0 OID 0)
-- Dependencies: 232
-- Name: zingsnis_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.zingsnis_id_seq', 17, true);


--
-- TOC entry 3634 (class 0 OID 0)
-- Dependencies: 231
-- Name: zingsnis_template_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.zingsnis_template_id_seq', 24, true);


--
-- TOC entry 3420 (class 2606 OID 16662)
-- Name: irasas irasas_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.irasas
    ADD CONSTRAINT irasas_pkey PRIMARY KEY (id);


--
-- TOC entry 3438 (class 2606 OID 16783)
-- Name: lokacija lokacija_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.lokacija
    ADD CONSTRAINT lokacija_pkey PRIMARY KEY (id);


--
-- TOC entry 3422 (class 2606 OID 16664)
-- Name: naudotojas naudotojas_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.naudotojas
    ADD CONSTRAINT naudotojas_pkey PRIMARY KEY (id);


--
-- TOC entry 3424 (class 2606 OID 16666)
-- Name: prisegtasfailas prisegtasfailas_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.prisegtasfailas
    ADD CONSTRAINT prisegtasfailas_pkey PRIMARY KEY (id);


--
-- TOC entry 3426 (class 2606 OID 16668)
-- Name: refreshtoken refreshtoken_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.refreshtoken
    ADD CONSTRAINT refreshtoken_pkey PRIMARY KEY (id);


--
-- TOC entry 3440 (class 2606 OID 16799)
-- Name: sablonas sablonas_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sablonas
    ADD CONSTRAINT sablonas_pkey PRIMARY KEY (id);


--
-- TOC entry 3442 (class 2606 OID 16807)
-- Name: sablonas_testas sablonas_testas_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sablonas_testas
    ADD CONSTRAINT sablonas_testas_pkey PRIMARY KEY (testasid, sablonasid);


--
-- TOC entry 3428 (class 2606 OID 16670)
-- Name: testas testas_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.testas
    ADD CONSTRAINT testas_pkey PRIMARY KEY (id);


--
-- TOC entry 3430 (class 2606 OID 16758)
-- Name: testasirasas testasirasas_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.testasirasas
    ADD CONSTRAINT testasirasas_pkey PRIMARY KEY (id);


--
-- TOC entry 3432 (class 2606 OID 16760)
-- Name: testasirasas testasirasas_testasid_irasasid_unique; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.testasirasas
    ADD CONSTRAINT testasirasas_testasid_irasasid_unique UNIQUE (testasid, irasasid);


--
-- TOC entry 3434 (class 2606 OID 16722)
-- Name: zingsnis zingsnis_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.zingsnis
    ADD CONSTRAINT zingsnis_pkey PRIMARY KEY (id);


--
-- TOC entry 3436 (class 2606 OID 16740)
-- Name: zingsnis_template zingsnis_template_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.zingsnis_template
    ADD CONSTRAINT zingsnis_template_pkey PRIMARY KEY (id);


--
-- TOC entry 3449 (class 2606 OID 16761)
-- Name: zingsnis fk_irasastekstas_zingsnis; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.zingsnis
    ADD CONSTRAINT fk_irasastekstas_zingsnis FOREIGN KEY (irasas_testas_id) REFERENCES public.testasirasas(id) ON DELETE CASCADE;


--
-- TOC entry 3443 (class 2606 OID 16784)
-- Name: irasas fk_lokacija; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.irasas
    ADD CONSTRAINT fk_lokacija FOREIGN KEY (lokacija_id) REFERENCES public.lokacija(id);


--
-- TOC entry 3450 (class 2606 OID 16766)
-- Name: zingsnis fk_naudotojas_zingsnis; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.zingsnis
    ADD CONSTRAINT fk_naudotojas_zingsnis FOREIGN KEY (completed_by_user_id) REFERENCES public.naudotojas(id) ON DELETE CASCADE;


--
-- TOC entry 3444 (class 2606 OID 16728)
-- Name: prisegtasfailas fk_prisegtas_zingsnis; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.prisegtasfailas
    ADD CONSTRAINT fk_prisegtas_zingsnis FOREIGN KEY (zingsnis_id) REFERENCES public.zingsnis(id) ON DELETE CASCADE;


--
-- TOC entry 3452 (class 2606 OID 16741)
-- Name: zingsnis_template fk_template_testas; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.zingsnis_template
    ADD CONSTRAINT fk_template_testas FOREIGN KEY (testas_id) REFERENCES public.testas(id) ON DELETE CASCADE;


--
-- TOC entry 3451 (class 2606 OID 16746)
-- Name: zingsnis fk_template_zingsnis; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.zingsnis
    ADD CONSTRAINT fk_template_zingsnis FOREIGN KEY (zingsnis_template_id) REFERENCES public.zingsnis_template(id) ON DELETE CASCADE;


--
-- TOC entry 3445 (class 2606 OID 16823)
-- Name: prisegtasfailas prisegtasfailas_zingsnis_template_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.prisegtasfailas
    ADD CONSTRAINT prisegtasfailas_zingsnis_template_id_fkey FOREIGN KEY (zingsnis_template_id) REFERENCES public.zingsnis_template(id) ON DELETE CASCADE;


--
-- TOC entry 3446 (class 2606 OID 16678)
-- Name: refreshtoken refreshtoken_naudotojasid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.refreshtoken
    ADD CONSTRAINT refreshtoken_naudotojasid_fkey FOREIGN KEY (naudotojasid) REFERENCES public.naudotojas(id) ON DELETE CASCADE;


--
-- TOC entry 3453 (class 2606 OID 16818)
-- Name: sablonas_testas sablonas_testas_sablonasid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sablonas_testas
    ADD CONSTRAINT sablonas_testas_sablonasid_fkey FOREIGN KEY (sablonasid) REFERENCES public.sablonas(id) ON DELETE CASCADE;


--
-- TOC entry 3454 (class 2606 OID 16808)
-- Name: sablonas_testas sablonas_testas_testasid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sablonas_testas
    ADD CONSTRAINT sablonas_testas_testasid_fkey FOREIGN KEY (testasid) REFERENCES public.testas(id);


--
-- TOC entry 3447 (class 2606 OID 16683)
-- Name: testasirasas testasirasas_irasasid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.testasirasas
    ADD CONSTRAINT testasirasas_irasasid_fkey FOREIGN KEY (irasasid) REFERENCES public.irasas(id) ON DELETE CASCADE;


--
-- TOC entry 3448 (class 2606 OID 16688)
-- Name: testasirasas testasirasas_testasid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.testasirasas
    ADD CONSTRAINT testasirasas_testasid_fkey FOREIGN KEY (testasid) REFERENCES public.testas(id) ON DELETE CASCADE;


-- Completed on 2026-04-09 13:48:14 EEST

--
-- PostgreSQL database dump complete
--

\unrestrict GT9z8HDXOi7iO6R4CSt3fXgCojlUMAXqfsGmecQnaCIZPO7yCgkmdue8RPJ5Fun

