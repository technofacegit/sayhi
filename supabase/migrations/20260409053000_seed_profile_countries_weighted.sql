-- Seed profile countries with weighted random distribution.
-- Majority is Turkey + Russia as requested.

update public.profiles p
set country = dist.country
from (
  select
    id,
    case
      when r < 0.52 then 'Turkey'           -- 52%
      when r < 0.86 then 'Russia'           -- 34% (cumulative 86%)
      when r < 0.90 then 'Germany'          -- 4%
      when r < 0.94 then 'United Kingdom'   -- 4%
      when r < 0.97 then 'France'           -- 3%
      when r < 0.99 then 'Spain'            -- 2%
      else 'United States'                  -- 1%
    end as country
  from (
    select id, random() as r
    from public.profiles
  ) s
) dist
where p.id = dist.id;
