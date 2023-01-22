select sub.id, sub.code, sub.name, sub.unit, sub.moment, sub.value, min(m.value), avg(m.value), max(m.value), sum(m.value)
from
  (select distinct on (s.id, s.code, s.name, s.unit) s.id, s.code, s.name, s.unit, m.moment, m.value
   from sensor s, measurement m
   where m.sensor_id=s.id
   and m.moment>=current_date
   and code='PSI'
   order by s.id, s.code, s.name, s.unit, m.moment desc) sub, measurement m
where m.sensor_id=sub.id
and m.moment>=current_date
group by sub.id, sub.code, sub.name, sub.unit, sub.moment, sub.value

--Hmmm for precipitation and sunshine we need the sum rather than the maximum
