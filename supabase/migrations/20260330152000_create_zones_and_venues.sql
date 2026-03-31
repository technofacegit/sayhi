-- Base schema for venues + zones
-- Requested shape:
-- create table public.venues (...)
-- create table public.zones (...)

create extension if not exists pgcrypto;

create table if not exists public.venues (
  id uuid not null default gen_random_uuid (),
  name text null,
  city text null,
  created_at timestamp without time zone null default now(),
  constraint venues_pkey primary key (id)
) tablespace pg_default;

create table if not exists public.zones (
  id uuid not null default gen_random_uuid (),
  venue_id uuid null,
  code text null,
  is_active boolean null default true,
  created_at timestamp without time zone null default now(),
  constraint zones_pkey primary key (id),
  constraint zones_code_key unique (code),
  constraint zones_venue_id_fkey foreign key (venue_id) references venues (id) on delete cascade
) tablespace pg_default;

