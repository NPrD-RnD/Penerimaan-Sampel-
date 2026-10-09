-- Jalankan sekali di SQL Editor proyek Supabase BARU.
-- Anggota lab hanya dapat ditambah/dihapus oleh pemilik proyek melalui dashboard/SQL.
begin;
create table public.lab_members (
  user_id uuid primary key references auth.users(id) on delete cascade,
  added_at timestamptz not null default now()
);
alter table public.lab_members enable row level security;
revoke all on public.lab_members from anon, authenticated;
create function public.is_lab_member() returns boolean
language sql stable security definer set search_path = ''
as $$ select exists(select 1 from public.lab_members where user_id = auth.uid()); $$;
revoke all on function public.is_lab_member() from public, anon;
grant execute on function public.is_lab_member() to authenticated;

create table public.lab_samples (
  id text primary key check (id ~ '^s[a-z0-9]+$'),
  data jsonb not null check (jsonb_typeof(data) = 'object'),
  revision bigint not null default 1,
  updated_at timestamptz not null default now()
);
alter table public.lab_samples enable row level security;
revoke all on public.lab_samples from anon, authenticated;
grant select on public.lab_samples to authenticated;
create policy "Only authorized lab members read samples" on public.lab_samples
for select to authenticated using (public.is_lab_member());

create table public.lab_audit (
  event_id bigint generated always as identity primary key,
  sample_id text not null,
  action text not null,
  actor_id uuid not null,
  occurred_at timestamptz not null default now()
);
alter table public.lab_audit enable row level security;
revoke all on public.lab_audit from anon,authenticated;
grant select on public.lab_audit to authenticated;
create policy "Lab members read audit" on public.lab_audit for select to authenticated
using (public.is_lab_member());

-- Transactional save with revision check: concurrent edits do not silently overwrite each other.
create function public.save_lab_samples(p_records jsonb) returns void
language plpgsql security definer set search_path = ''
as $$
declare item jsonb; payload jsonb; sample_id text; expected bigint; current_revision bigint;
  current_data jsonb; stamp text; last_note text;
begin
  if not public.is_lab_member() then raise exception 'LAB_ACCESS_DENIED'; end if;
  if jsonb_typeof(p_records) is distinct from 'array' or jsonb_array_length(p_records)>100 then
    raise exception 'LAB_INVALID_BATCH'; end if;
  for item in select value from jsonb_array_elements(p_records) loop
    payload := item->'data'; sample_id := payload->>'id'; expected := (item->>'revision')::bigint;
    if expected is null or expected < 0 then raise exception 'LAB_INVALID_RECORD'; end if;
    if exists(select 1 from unnest(array['receiver','material','received','location','notes','usedBy','useNote','disposedDate','created','updated']) k
      where jsonb_typeof(payload->k) is distinct from 'string') then raise exception 'LAB_INVALID_RECORD'; end if;
    if sample_id is null or sample_id !~ '^s[a-z0-9]+$' or jsonb_typeof(payload) is distinct from 'object'
      or payload->>'status' is null or payload->>'status' not in ('pending','used','kept','disposed')
      or nullif(trim(payload->>'material'),'') is null or length(payload->>'material')>250
      or nullif(trim(payload->>'receiver'),'') is null or length(payload->>'receiver')>150
      or length(payload->>'notes')>5000 or length(payload->>'useNote')>5000
      or length(payload->>'location')>250 or length(payload->>'usedBy')>150
      or payload->>'received' is null or payload->>'received' !~ '^\d{4}-\d{2}-\d{2}$'
      or jsonb_typeof(payload->'photos') is distinct from 'array' or jsonb_array_length(payload->'photos')>8
      or jsonb_typeof(payload->'history') is distinct from 'array' or jsonb_array_length(payload->'history')<1
      or pg_column_size(payload)>300000 then raise exception 'LAB_INVALID_RECORD'; end if;
    perform (payload->>'received')::date;
    if payload->>'status'='used' and nullif(trim(payload->>'usedBy'),'') is null then raise exception 'LAB_INVALID_RECORD'; end if;
    if payload->>'status'='disposed' and ((payload->>'disposedDate') is null or (payload->>'disposedDate')::date < (payload->>'received')::date) then raise exception 'LAB_INVALID_RECORD'; end if;
    if exists(select 1 from jsonb_array_elements(payload->'photos') p
      where p->>'kind' is null or p->>'kind' not in ('receipt','storage') or p->>'path' is null
        or p->>'path' !~ ('^samples/' || sample_id || '/[a-z0-9-]+\.jpg$') or p ? 'data') then raise exception 'LAB_INVALID_PHOTO'; end if;
    select revision, data into current_revision,current_data from public.lab_samples where id=sample_id for update;
    if found then
      if current_revision <> expected then raise exception 'LAB_CONFLICT'; end if;
    else
      if expected <> 0 then raise exception 'LAB_CONFLICT'; end if;
      current_data:=null;
    end if;
    stamp := to_char(clock_timestamp() at time zone 'UTC','YYYY-MM-DD"T"HH24:MI:SS.MS"Z"');
    payload := jsonb_set(payload,'{updated}',to_jsonb(stamp));
    payload := jsonb_set(payload,'{created}',coalesce(current_data->'created',to_jsonb(stamp)));
    -- Last history item records authenticated actor and server time.
    payload := jsonb_set(payload, array['history',(jsonb_array_length(payload->'history')-1)::text,'at'],to_jsonb(stamp));
    payload := jsonb_set(payload, array['history',(jsonb_array_length(payload->'history')-1)::text,'actorId'],to_jsonb(auth.uid()::text));
    last_note := payload->'history'->(-1)->>'note';
    if payload->>'status'='used' and (current_data is null or current_data->>'status' is distinct from 'used' or last_note='Penggunaan bahan dicatat') then
      payload := jsonb_set(payload,'{usedAt}',to_jsonb(stamp));
    end if;
    if current_revision is null then
      insert into public.lab_samples(id,data) values(sample_id,payload);
    else
      update public.lab_samples set data=payload,revision=revision+1,updated_at=clock_timestamp() where id=sample_id;
    end if;
    insert into public.lab_audit(sample_id,action,actor_id) values(sample_id,'save',auth.uid());
    current_revision:=null;
  end loop;
end; $$;
revoke all on function public.save_lab_samples(jsonb) from public,anon;
grant execute on function public.save_lab_samples(jsonb) to authenticated;

create function public.delete_lab_sample(p_id text,p_revision bigint) returns void
language plpgsql security definer set search_path = ''
as $$ begin
  if not public.is_lab_member() then raise exception 'LAB_ACCESS_DENIED'; end if;
  delete from public.lab_samples where id=p_id and revision=p_revision;
  if not found then raise exception 'LAB_CONFLICT'; end if;
  insert into public.lab_audit(sample_id,action,actor_id) values(p_id,'delete',auth.uid());
end; $$;
revoke all on function public.delete_lab_sample(text,bigint) from public,anon;
grant execute on function public.delete_lab_sample(text,bigint) to authenticated;

insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types)
values('lab-photos','lab-photos',false,524288,array['image/jpeg']);
create policy "Lab members read private photos" on storage.objects for select to authenticated
using (bucket_id='lab-photos' and public.is_lab_member());
create policy "Lab members upload photos" on storage.objects for insert to authenticated
with check (bucket_id='lab-photos' and public.is_lab_member() and name ~ '^samples/s[a-z0-9]+/[a-z0-9-]+\.jpg$');
create policy "Lab members remove photos" on storage.objects for delete to authenticated
using (bucket_id='lab-photos' and public.is_lab_member());
-- No anonymous access; no public signup is needed; no direct table writes from the browser.
commit;

-- Setelah membuat akun di Authentication > Users > Add user > Create new user:
-- Ganti email berikut lalu jalankan query ini secara terpisah:
-- insert into public.lab_members(user_id)
-- select id from auth.users where email in ('anda@example.com','rekan@example.com')
-- on conflict (user_id) do nothing;
