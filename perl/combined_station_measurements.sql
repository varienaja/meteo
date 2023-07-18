-- Original measurements plus interpolated value for 20-minute gaps
with raw as (
  select id, sensor_id, 
         moment, lag(moment) over (partition by sensor_id order by moment desc) as m2, 
         value, lag(value) over (partition by sensor_id order by moment desc) as v2 
  from measurement
  where moment>=current_date
),
generated as (
  select -1 as id, sensor_id, moment+'10 minutes, 1 milliseconds'::interval as moment,
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
), final as (
  select m.id, s.id as sensor_id, s.code, m.moment, m.value, s.unit 
  from combined m, sensor s 
  where s.id=m.sensor_id and m.moment>=current_date and (m.id=-1 or m.id>?)
  order by s.unit desc, m.moment
)
select array_to_json(array_agg(json_build_object('id', id, 'sensor_id', sensor_id, 'code', code, 'value', value, 'unit', unit, 'hh', extract(hour from moment), 'mm', extract(minute from moment)))) 
from final 


-- select array_to_json(array_agg(json_build_object('id', m.id, 'sensor_id', s.id, 'code', s.code, 'value', m.value, 'unit', s.unit, 'hh', extract(hour from m.moment), 'mm', extract(minute from m.moment)))) 
-- from measurement m, sensor s
-- where s.id=m.sensor_id and m.moment>=current_date and m.id>?

