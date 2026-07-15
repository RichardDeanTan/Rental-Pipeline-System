SELECT
    rental_id,
    COUNT(*) AS payment_count
FROM payment
GROUP BY rental_id
HAVING COUNT(*) > 1;


select * 
from payment p
left join rental r on p.rental_id = r.rental_id
left join inventory i on r.inventory_id = i.inventory_id
left join film f on i.film_id = f.film_id
where p.rental_id = 4591


select f.title, count(*) as count1
from payment p
join rental r on p.rental_id = r.rental_id
join inventory i on r.inventory_id = i.inventory_id
join film f on i.film_id = f.film_id
group by f.title
order by count1 desc


select *
from payment p
left join rental r on p.rental_id = r.rental_id
left join inventory i on r.inventory_id = i.inventory_id
left join film f on i.film_id = f.film_id
where f.title = 'Scalawag Duck'