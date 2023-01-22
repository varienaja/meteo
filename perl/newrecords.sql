select code, name, unit, type, case when type='min' then min(recordvalue) else max(recordvalue) end as recordvalue, sum(age) as age, max(moment) as moment
from records
where moment >= current_date-1
group by code, name, unit, type
order by unit, recordvalue desc
