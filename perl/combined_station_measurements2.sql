-- Original measurements plus interpolated value for 20-minute gaps
with raw as (
  select id, sensor_id, 
         moment, lag(moment) over (partition by sensor_id order by moment desc) as m2, 
         value, lag(value) over (partition by sensor_id order by moment desc) as v2 
  from measurement
  where moment>=current_date
    and sensor_id in (select id from sensor where code=?)
),
generated as (
  select 1 as id, sensor_id, moment+'10 minutes, 1 milliseconds'::interval as moment,
         (value + v2) / 2 as value
  from raw
  where m2-moment='20 minutes'::interval
),
original as (
  select id, sensor_id, moment, value from raw
),
combined as (
  select * from generated union select * from original
  order by sensor_id, moment
)
select m.moment, extract(hour from m.moment), extract(minute from m.moment), m.value, s.unit 
from combined m, sensor s 
where m.sensor_id = s.id 
order by s.unit desc, m.moment

