-- Lists all different types of measurements with their extremes (minimum and maximum) and station.
-- One can vary the time range with the interval.

select a.unit, a.code, a.name, a.moment as minmoment, a.value as minvalue, b.code, b.name, b.moment as maxmoment, b.value as maxvalue
from 
(

(select distinct on (s.unit) s.unit, s.code, s.name, m.moment, m.value
from sensor s, measurement m
where m.sensor_id=s.id
and m.moment>=current_date
and s.unit not in ('mm', 'min')
order by s.unit, m.value asc)

union

(select distinct on (s.unit) s.unit, s.code, s.name, max(m.moment), sum(m.value) as value
from sensor s, measurement m
where m.sensor_id=s.id
and m.moment>=current_date
and s.unit in ('mm', 'min')
group by s.unit, s.code, s.name
order by s.unit, sum(value))

) a,
(
(select distinct on (s.unit) s.unit, s.code, s.name, m.moment, m.value
from sensor s, measurement m
where m.sensor_id=s.id
and m.moment>=current_date
and s.unit not in ('mm', 'min')
order by s.unit, m.value desc)

union

(select distinct on (s.unit) s.unit, s.code, s.name, max(m.moment), sum(m.value)
from sensor s, measurement m
where m.sensor_id=s.id
and m.moment>=current_date
and s.unit in ('mm', 'min')
group by s.unit, s.code, s.name
order by s.unit, sum(value) desc)

) b
where a.unit=b.unit
order by a.unit
