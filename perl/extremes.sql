-- Lists all different types of measurements with their extremes (minimum and maximum) and station.
-- One can vary the time range with the interval.

select a.unit, a.code, a.name, a.moment as minmoment, a.value as minvalue, b.code, b.name, b.moment as maxmoment, b.value as maxvalue
from 
(select distinct on (s.unit) s.unit, s.code, s.name, m.moment, m.value
from sensor s, measurement m
where m.sensor_id=s.id
and m.moment>=current_date
--and m.moment>=current_timestamp - interval '24 hours'
order by s.unit, m.value asc
) a,
(
select distinct on (s.unit) s.unit, s.code, s.name, m.moment, m.value
from sensor s, measurement m
where m.sensor_id=s.id
and m.moment>=current_date
--and m.moment>=current_timestamp - interval '24 hours'
order by s.unit, m.value desc ) b
where a.unit=b.unit
order by a.unit

