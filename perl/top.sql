-- Select highest and lowest temperatures for today
select a.code, a.name, a.moment as minmoment, a.mintemp, b.moment as maxmoment, b.maxtemp, b.maxtemp-a.mintemp as delta, b.moment-a.moment as timedelta from
(select distinct on (s.code, s.name) s.code, s.name, m.moment, m.value as mintemp
from measurement m, sensor s
where m.sensor_id=s.id
  and m.moment>=current_date
  and s.network='messwerte-lufttemperatur-10min'
  and length(s.code)=3
order by s.name, s.code, m.value) a,
(select distinct on (s.code) s.code, m.moment, m.value as maxtemp
from measurement m, sensor s
where m.sensor_id=s.id
  and m.moment>=current_date
  and s.network='messwerte-lufttemperatur-10min'
  and length(s.code)=3
order by s.code, m.value desc) b
where a.code=b.code
order by a.name;
