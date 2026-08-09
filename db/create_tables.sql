-- Postgres schema generated from C# models
-- Creates tables matching Backend/Models/*.cs

BEGIN;

CREATE TABLE IF NOT EXISTS "row" (
  "id" SERIAL PRIMARY KEY,
  "description" TEXT NOT NULL,
  "control_methods" TEXT
);

CREATE TABLE IF NOT EXISTS "header" (
  "id" SERIAL PRIMARY KEY,
  "text" TEXT NOT NULL,
  "row_id" INTEGER NOT NULL,
  CONSTRAINT fk_header_row FOREIGN KEY ("row_id") REFERENCES "row"("id") ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS "column_template" (
  "id" SERIAL PRIMARY KEY,
  "description" TEXT NOT NULL,
  "row_id" INTEGER NOT NULL,
  "order" INTEGER NOT NULL,
  "header_id" INTEGER,
  "is_array" BOOLEAN NOT NULL DEFAULT FALSE,
  "array_length" INTEGER NOT NULL DEFAULT 0,
  CONSTRAINT fk_coltemp_row FOREIGN KEY ("row_id") REFERENCES "row"("id") ON DELETE CASCADE,
  CONSTRAINT fk_coltemp_header FOREIGN KEY ("header_id") REFERENCES "header"("id") ON DELETE SET NULL
);

CREATE TABLE IF NOT EXISTS "fat" (
  "id" SERIAL PRIMARY KEY,
  "title" TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS "fat_row" (
  "fatid" INTEGER NOT NULL,
  "rowid" INTEGER NOT NULL,
  "order" INTEGER NOT NULL,
  PRIMARY KEY ("fatid", "rowid"),
  CONSTRAINT fk_fatrow_fat FOREIGN KEY ("fatid") REFERENCES "fat"("id") ON DELETE CASCADE,
  CONSTRAINT fk_fatrow_row FOREIGN KEY ("rowid") REFERENCES "row"("id") ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS "fatreport" (
  "id" SERIAL PRIMARY KEY,
  "text" TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS "report_template" (
  "id" SERIAL PRIMARY KEY,
  "text" TEXT NOT NULL,
  "fatreport_id" INTEGER NOT NULL,
  "order" INTEGER NOT NULL,
  CONSTRAINT fk_reporttemplate_fatreport FOREIGN KEY ("fatreport_id") REFERENCES "fatreport"("id") ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS "fatreport_irasas" (
  "id" SERIAL PRIMARY KEY,
  "fatreport_id" INTEGER,
  "irasasid" INTEGER,
  "order" INTEGER,
  CONSTRAINT fk_fatreportirasas_fatreport FOREIGN KEY ("fatreport_id") REFERENCES "fatreport"("id") ON DELETE CASCADE,
  CONSTRAINT fk_fatreportirasas_irasas FOREIGN KEY ("irasasid") REFERENCES "irasas"("id") ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS "report_value" (
  "id" SERIAL PRIMARY KEY,
  "value" TEXT NOT NULL,
  "fatreport_irasasid" INTEGER NOT NULL,
  "report_template_id" INTEGER NOT NULL,
  CONSTRAINT fk_reportvalue_fatreportirasas FOREIGN KEY ("fatreport_irasasid") REFERENCES "fatreport_irasas"("id") ON DELETE CASCADE,
  CONSTRAINT fk_reportvalue_reporttemplate FOREIGN KEY ("report_template_id") REFERENCES "report_template"("id") ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS "row_irasas" (
  "id" SERIAL PRIMARY KEY,
  "row_id" INTEGER NOT NULL,
  "irasas_id" INTEGER NOT NULL,
  "order" INTEGER NOT NULL,
  CONSTRAINT fk_rowirasas_row FOREIGN KEY ("row_id") REFERENCES "row"("id") ON DELETE CASCADE,
  CONSTRAINT fk_rowirasas_irasas FOREIGN KEY ("irasas_id") REFERENCES "irasas"("id") ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS "row_value" (
  "id" SERIAL PRIMARY KEY,
  "value" TEXT,
  "completed_at" TIMESTAMPTZ,
  "completed_by_user_id" UUID,
  "row_id" INTEGER NOT NULL,
  "row_irasas_id" INTEGER NOT NULL,
  CONSTRAINT fk_rowvalue_row FOREIGN KEY ("row_id") REFERENCES "row"("id") ON DELETE CASCADE,
  CONSTRAINT fk_rowvalue_rowirasas FOREIGN KEY ("row_irasas_id") REFERENCES "row_irasas"("id") ON DELETE CASCADE,
  CONSTRAINT fk_rowvalue_user FOREIGN KEY ("completed_by_user_id") REFERENCES "naudotojas"("id")
);

CREATE TABLE IF NOT EXISTS "column_value" (
  "id" SERIAL PRIMARY KEY,
  "single_value" NUMERIC,
  "array_value" NUMERIC[],
  "completed_at" TIMESTAMPTZ,
  "row_irasas_id" INTEGER NOT NULL,
  "column_template_id" INTEGER NOT NULL,
  "completed_by_user_id" UUID,
  CONSTRAINT fk_colvalue_rowirasas FOREIGN KEY ("row_irasas_id") REFERENCES "row_irasas"("id") ON DELETE CASCADE,
  CONSTRAINT fk_colvalue_coltemplate FOREIGN KEY ("column_template_id") REFERENCES "column_template"("id") ON DELETE CASCADE,
  CONSTRAINT fk_colvalue_user FOREIGN KEY ("completed_by_user_id") REFERENCES "naudotojas"("id")
);

COMMIT;
