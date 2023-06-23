drop table if exists results;

create table results (
    id int,
    response varchar(255)
);

--1.
insert into results
select 	1 id,(select max(br) mbr from (select b.book_ref, count(passenger_id) br from bookings a join tickets b on a.book_ref = b.book_ref group by b.book_ref) f)  res;

--2.
insert into results
select 2 id, (	select sum(brc) brc
				from (
					select br,count(book_ref) brc, e.abr
					from (
							select 	a.book_ref,count(passenger_id)  br
							from bookings a
							join tickets b on a.book_ref = b.book_ref
							group by a.book_ref
						) f ,
							(
							select avg(br) abr
							from (
								select 	a.book_ref,count(passenger_id)  br
								from bookings a
								join tickets b on a.book_ref = b.book_ref
								group by a.book_ref
							) a
							) e
					group by br, e.abr
					) t
				where br>abr);


--3.
insert into results
select 3 id,(with tt as (
				select distinct book_ref
				from (
						select 	a.book_ref,
								count(passenger_id)  cb
						from bookings a
						join tickets b on a.book_ref = b.book_ref
						group by a.book_ref
					) f
				where cb = (select max(cb) mb from (select a.book_ref, count(passenger_id) cb from bookings a join tickets b on a.book_ref = b.book_ref group by a.book_ref) f)
				)
				,rt as (
						select 	a.book_ref,
								passenger_id
						from bookings a
						join tickets b on a.book_ref = b.book_ref
						join tt c on a.book_ref = c.book_ref
						order by 2
					)

				select count(distinct book_ref) rep
				from (
				select a.book_ref ,count(a.book_ref)
				from rt a
				join rt b on a.passenger_id = b.passenger_id
				group by a.book_ref
				having count(a.book_ref) > (select max(cb) mb from (select a.book_ref, count(passenger_id) cb from bookings a join tickets b on a.book_ref = b.book_ref group by a.book_ref) f)) f);

--4.
insert into results
select 4 id, book_ref||'|'||passenger_id||'|'||passenger_name||'|'||contact_data res
from (select 	a.book_ref,
			passenger_id,
			passenger_name,
			contact_data,
			count(*) over (partition by a.book_ref) cp
	from bookings a
	join tickets b on a.book_ref = b.book_ref
	) w
where cp = 3;

--5.
insert into results
select 5 id, (select max(fl)
				from (
					select a.book_ref ,count(*) fl
					from bookings a
					join tickets b on a.book_ref = b.book_ref
					join ticket_flights c on b.ticket_no = c.ticket_no
					join flights d on c.flight_id = d.flight_id
					group by a.book_ref
				) f);

--6.
insert into results
select 6 id, (select max(fl)
from (
	select a.book_ref,b.passenger_id,count(*) fl
	from bookings a
	join tickets b on a.book_ref = b.book_ref
	join ticket_flights c on b.ticket_no = c.ticket_no
	join flights d on c.flight_id = d.flight_id
	group by a.book_ref,b.passenger_id
) f);

--7.
insert into results
select 7 id, (select max(fl)
from (
	select b.passenger_id,count(c.flight_id) fl
	from bookings a
	join tickets b on a.book_ref = b.book_ref
	join ticket_flights c on b.ticket_no = c.ticket_no
	join flights d on c.flight_id = d.flight_id
	group by b.passenger_id
) f);

--8.
insert into results
select * from (
with am as (
select b.passenger_id, b.passenger_name, b.contact_data,sum(amount) amt
		from bookings a
		join tickets b on a.book_ref = b.book_ref
		join ticket_flights c on b.ticket_no = c.ticket_no
		join flights d on c.flight_id = d.flight_id
		group by b.passenger_id, b.passenger_name, b.contact_data
		)

	select 8 id, passenger_id||'|'||passenger_name||'|'||contact_data||'|'||f.amt
	from am f
	where f.amt = (select min(amt) amt from am)
	) a;

--9.
insert into results
select * from (
with du as (
	select  d.passenger_id, d.passenger_name, d.contact_data,sum(duration) dur
		from routes a
		join flights b on a.flight_no = b.flight_no
		join ticket_flights c  on b.flight_id = c.flight_id
		join tickets d on c.ticket_no = d.ticket_no
		group by d.passenger_id, d.passenger_name, d.contact_data
		)

	select 9 id, passenger_id||'|'||passenger_name||'|'||contact_data||'|'||f.dur
	from du f
	where f.dur = (select max(dur) dur from du)
	) a;

--10.
insert into results
select 10 id,  city
from (
	select city,count(1)
	from airports ad
	group by 1
	having count(1)>1
) f;

--11.
insert into results
select * from (
with tt as (
select departure_city city, count( distinct arrival_city) count_city_out
from routes r
group by departure_city)
select 11 id, city
from tt
where count_city_out = (select min(count_city_out) from tt)
order by 2
) a;

--12.
insert into results
select * from (
with tt as (
select 	a.city city1,a.rn rn1, b.city city2,b.rn rn2
from 	(select city, row_number() over (order by city) rn from airports) a,
		(select city, row_number() over (order by city) rn from airports) b
where a.city!= b.city
	)
select distinct 12 id,case when rn1<rn2 then city1||'|'||city2 else city2||'|'||city1 end res
from (
select tt.*
from tt
left join (select distinct departure_city, arrival_city from routes r) f
	on tt.city1 = f.departure_city and tt.city2 = f.arrival_city
left join (select distinct departure_city, arrival_city from routes r) r
	on tt.city2 = r.departure_city and tt.city1 = r.arrival_city
where r.departure_city is null and f.departure_city is null
) d
order by 2
) a;

--13.
insert into results
select distinct 13 id, a.arrival_city
from routes a
left join (select arrival_city from routes where departure_city = 'Москва') b on a.arrival_city = b.arrival_city
where b.arrival_city is null and a.arrival_city != 'Москва'
order by 2;

--14.
insert into results
select * from (
with tt as (
select model, count(1) cnt
from flights_v fv
join aircrafts a on fv.aircraft_code = a.aircraft_code
where status = 'Arrived'
group by model)
select 14 id, model
from tt
where cnt = (select max(cnt) from tt)
) a;

--15.
insert into results
select * from (
with tt as (
select a.model, count(passenger_id) cnt
from flights_v fv
join aircrafts a on fv.aircraft_code = a.aircraft_code
join ticket_flights b on fv.flight_id = b.flight_id
join tickets c on b.ticket_no = c.ticket_no
where status = 'Arrived'
group by a.model)
select 15 id, model
from tt
where cnt = (select max(cnt) from tt)
) a;

--16.
insert into results
select 16 id,
		round((sum(extract(epoch from actual_duration)) -
		sum(extract(epoch from (fv.scheduled_arrival -fv.scheduled_departure))))/60)
from flights_v fv
where status = 'Arrived';

--17.
insert into results
select distinct 17 id,arrival_city
from flights_v fv
where actual_departure>= '2016-09-13' and actual_departure < '2016-09-14'
    and departure_city ='Санкт-Петербург'
    and status = 'Arrived'
order by 2;

--18.
insert into results
select * from (
with tt as (
select fv.flight_id, sum(amount) amt
from flights_v fv
join ticket_flights b on fv.flight_id = b.flight_id
group by fv.flight_id)

select 18 id, flight_id res
from tt
where amt = (select max(amt) from tt)
) a;

--19.
insert into results
select * from (
with tt as (
select cast(actual_departure as date) dd, count(1) cnt
from flights_v fv
where actual_departure is not null and status = 'Arrived'
group by cast(actual_departure as date)
)

select 19 id, dd res
from tt
where cnt = (select min(cnt) from tt)
) a;

--20.
insert into results
select * from (
with tt as (
select cast(actual_departure as date) dd, count(1) cnt
from flights_v fv
where extract(year from fv.actual_departure) = 2016
    and extract(month from fv.actual_departure) = 9
	and status in('Arrived','Departed')
	and departure_city = 'Москва'
group by cast(actual_departure as date)
)
select 20 id, avg(cnt) res
from tt ) a;

--21.
insert into results
select * from (
with tt as (
select departure_city , avg(extract(epoch from actual_duration)/60/60) hh
from flights_v a
where status ='Arrived'
group by departure_city)
,rt as (
select 21 id, departure_city res
from tt
where hh>3
order by hh desc
limit  5)
select *
from rt
order by 2) a;