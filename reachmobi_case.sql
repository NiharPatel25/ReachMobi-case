drop table np_reachmobi_perf ;
CREATE TABLE np_reachmobi_perf (
"date" text,
date_installed text,
date_from_install integer,
color text,
impressions float,
clicks float, 
revenue float
);


drop table np_reachmobi_user;
CREATE TABLE np_reachmobi_user (
date_installed text,
color text,
users integer 
);

select count(1) from np_reachmobi_perf nrp ;
select * from np_reachmobi_user;


select 
  date_installed,
  color,
  sum(users) total_users
from np_reachmobi_user nru
group by 1,2;

--------Only users that are eligible should be considered


select max("date"), min("date") from np_reachmobi_perf nrp;
select max(date_installed), min(date_installed) from np_reachmobi_user nru;

---restrict before max and eligible

with num_cross as 
(select 
   nru.date_installed, 
   nru.color, 
   nru.users, 
   n.numbers days, 
   DATE(nru.date_installed, cast(n.numbers as text) ||' days') days_since
from 
   np_reachmobi_user nru
   left join (select * from numbers where numbers < 366) n on 1 = 1
), 
agg as (select 
    a.*, 
    coalesce(b.impressions, 0) total_imps, 
    coalesce(b.clicks, 0) total_clicks, 
    coalesce(b.revenue, 0) total_rev, 
    first_imps
from num_cross as a 
left join 
   (select 
      "date", 
       date_installed, 
       JULIANDAY("date") - JULIANDAY(date_installed) date_diff, 
       color, 
       impressions, 
       clicks, 
       revenue, 
       ROW_NUMBER() over (partition by date_installed, color order by "date") first_imps
    from np_reachmobi_perf
    where date_installed <= "date"
    ) as b on a.date_installed = b.date_installed and a.days = b.date_diff and a.color = b.color
where days_since <= '2015-01-28' 
order by date_installed)
select 
   a.date_installed,
   a.color, 
   a.users, 
   case when b.days_first_imps is null then 'no imps' else b.days_first_imps end days_first_imps, 
   count(distinct a.first_imps) days_with_imps
from agg as a 
left join 
	(select 
		date_installed, 
		color, 
		min(days) days_first_imps
		from agg 
		where first_imps = 1
		group by 1,2) as b on a.date_installed = b.date_installed and a.color = b.color
group by 1,2,3,4
order by 1,2
;

How many users have no impressions
how many users have average impressions far off
average number of active days?
average number of active users?

with num_cross as 
(select 
   nru.date_installed, 
   nru.color, 
   nru.users, 
   n.numbers days, 
   DATE(nru.date_installed, cast(n.numbers as text) ||' days') days_since
from 
   np_reachmobi_user nru
   left join (select * from numbers where numbers < 366) n on 1 = 1
), 
agg as (select 
    a.*, 
    coalesce(b.impressions, 0) total_imps, 
    coalesce(b.clicks, 0) total_clicks, 
    coalesce(b.revenue, 0) total_rev, 
    first_imps
from num_cross as a 
left join 
   (select 
      "date", 
       date_installed, 
       JULIANDAY("date") - JULIANDAY(date_installed) date_diff, 
       color, 
       impressions, 
       clicks, 
       revenue, 
       ROW_NUMBER() over (partition by date_installed, color order by "date") first_imps
    from np_reachmobi_perf
    where date_installed <= "date"
    ) as b on a.date_installed = b.date_installed and a.days = b.date_diff and a.color = b.color
where days_since <= '2015-01-28'
order by date_installed)
select 
   *
   from agg
;

