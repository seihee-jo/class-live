-- 실시간 익명 설문 스키마 (Supabase)
-- 학생(anon): 현재 질문 읽기 + 현재 질문에 답변 쓰기만 가능. 답변 읽기는 불가.
-- 발표자: host_secret 의 키를 아는 사람만 질문 넘기기 · 답변 읽기 · 초기화 가능.

create table if not exists public.live_state (
  id int primary key default 1 check (id = 1),
  q text not null default 'wait',
  updated_at timestamptz not null default now()
);
insert into public.live_state (id, q) values (1, 'wait') on conflict (id) do nothing;

create table if not exists public.answers (
  id bigint generated always as identity primary key,
  q text not null check (char_length(q) <= 20),
  body text not null check (char_length(btrim(body)) between 1 and 200),
  created_at timestamptz not null default now()
);

create table if not exists public.host_secret (k text primary key);

alter table public.live_state enable row level security;
alter table public.answers enable row level security;
alter table public.host_secret enable row level security;

drop policy if exists "state readable" on public.live_state;
create policy "state readable" on public.live_state for select to anon, authenticated using (true);

-- 지금 열린 질문에만 쓸 수 있다 (안내 화면 단계에서는 쓰기 불가)
drop policy if exists "answer current question" on public.answers;
create policy "answer current question" on public.answers for insert to anon, authenticated
  with check (q = (select s.q from public.live_state s where s.id = 1)
              and q not in ('wait', 'pause', 'end'));

create or replace function public._host_ok(p_key text) returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.host_secret where k = p_key)
$$;
revoke all on function public._host_ok(text) from public, anon, authenticated;

create or replace function public.host_set(p_key text, p_q text) returns void
language plpgsql security definer set search_path = public as $$
begin
  if not public._host_ok(p_key) then raise exception 'denied'; end if;
  update public.live_state set q = p_q, updated_at = now() where id = 1;
end $$;

create or replace function public.host_answers(p_key text, p_q text)
returns table (id bigint, body text, created_at timestamptz)
language plpgsql stable security definer set search_path = public as $$
begin
  if not public._host_ok(p_key) then raise exception 'denied'; end if;
  return query select a.id, a.body, a.created_at from public.answers a where a.q = p_q order by a.id;
end $$;

create or replace function public.host_clear(p_key text) returns void
language plpgsql security definer set search_path = public as $$
begin
  if not public._host_ok(p_key) then raise exception 'denied'; end if;
  delete from public.answers where true;
  update public.live_state set q = 'wait', updated_at = now() where id = 1;
end $$;

revoke all on function public.host_set(text, text) from public;
revoke all on function public.host_answers(text, text) from public;
revoke all on function public.host_clear(text) from public;
grant execute on function public.host_set(text, text) to anon, authenticated;
grant execute on function public.host_answers(text, text) to anon, authenticated;
grant execute on function public.host_clear(text) to anon, authenticated;

-- 학생 화면이 질문 전환을 실시간으로 받는다
do $$ begin
  alter publication supabase_realtime add table public.live_state;
exception when duplicate_object then null; end $$;

-- 발표자 키는 레포에 남기지 않는다. 적용 시 별도로 insert:
-- insert into public.host_secret (k) values ('<랜덤 키>');

-- ───────── 2026-10-15 추가: 커피챗 신청(비공개) + 결과 보기 ─────────
-- 커피챗 신청은 연락처가 들어가므로 answers와 분리한다. 학생은 쓰기만, 읽기는 발표자 키로만.
-- 발표 화면(host.html)은 개수만(host_coffee_count), 내용은 결과 페이지(results.html)에서만(host_coffee).
-- host_clear(리허설 초기화)는 커피챗 신청을 지우지 않는다.
create table if not exists public.coffee_chats (
  id bigint generated always as identity primary key,
  name text not null check (char_length(btrim(name)) between 1 and 30),
  contact text not null check (char_length(btrim(contact)) between 3 and 100),
  questions text not null check (char_length(btrim(questions)) between 1 and 500),
  job_status text not null check (char_length(job_status) between 1 and 40),
  consent boolean not null check (consent),
  created_at timestamptz not null default now()
);
alter table public.coffee_chats enable row level security;
drop policy if exists "coffee when open" on public.coffee_chats;
create policy "coffee when open" on public.coffee_chats for insert to anon, authenticated
  with check ((select s.q from public.live_state s where s.id = 1) = 'coffee');

create or replace function public.host_coffee_count(p_key text) returns bigint
language plpgsql stable security definer set search_path = public as $$
begin
  if not public._host_ok(p_key) then raise exception 'denied'; end if;
  return (select count(*) from public.coffee_chats);
end $$;

create or replace function public.host_coffee(p_key text)
returns table (id bigint, name text, contact text, questions text, job_status text, created_at timestamptz)
language plpgsql stable security definer set search_path = public as $$
begin
  if not public._host_ok(p_key) then raise exception 'denied'; end if;
  return query select c.id, c.name, c.contact, c.questions, c.job_status, c.created_at from public.coffee_chats c order by c.id;
end $$;

create or replace function public.host_all_answers(p_key text)
returns table (id bigint, q text, body text, created_at timestamptz)
language plpgsql stable security definer set search_path = public as $$
begin
  if not public._host_ok(p_key) then raise exception 'denied'; end if;
  return query select a.id, a.q, a.body, a.created_at from public.answers a order by a.id;
end $$;

revoke all on function public.host_coffee_count(text) from public;
revoke all on function public.host_coffee(text) from public;
revoke all on function public.host_all_answers(text) from public;
grant execute on function public.host_coffee_count(text) to anon, authenticated;
grant execute on function public.host_coffee(text) to anon, authenticated;
grant execute on function public.host_all_answers(text) to anon, authenticated;

drop policy if exists "answer current question" on public.answers;
create policy "answer current question" on public.answers for insert to anon, authenticated
  with check (q = (select s.q from public.live_state s where s.id = 1)
              and q not in ('wait', 'pause', 'end', 'coffee'));

-- ───────── 2026-10-16 추가: 세션 중 실시간 질문(ask) '답변 완료' 표시 ─────────
alter table public.answers add column if not exists done boolean not null default false;
-- host_answers / host_all_answers 는 done 을 함께 돌려준다. host_mark(p_key, p_id, p_done)로 표시를 바꾼다.
