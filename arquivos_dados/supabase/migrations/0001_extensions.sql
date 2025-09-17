-- 0001_extensions.sql
create extension if not exists pgcrypto;
create extension if not exists vector; -- pgvector
create extension if not exists pg_trgm;