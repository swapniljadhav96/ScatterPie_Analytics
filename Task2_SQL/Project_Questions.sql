-- Part 1

/* 1. We will need a list of all staff members, including their first and last names, email addresses, and the store 
  identification number where they work. */

select * from staff;

-- 2. We will need separate counts of inventory items held at each of your two stores. 

select store_id , count(inventory_id) as inventory_items
from inventory
group by store_id;


-- 3. We will need a count of active customers for each of your stores. Separately, please. 

select store_id,
sum(case when active = 1 then 1 else 0 end) as active,
sum(case when active = 0 then 1 else 0 end) as inactive
from customer
group by store_id;


-- 4. In order to assess the liability of a data breach, we will need you to provide a count of all customer email 
-- addresses stored in the database. 

select count(email) from customer; 

/* 5.  We are interested in how diverse your film offering is as a means of understanding how likely you are to 
keep customers engaged in the future. Please provide a count of unique film titles you have in inventory at 
each store and then provide a count of the unique categories of films you provide. */

select store_id, count(distinct film_id) as unique_films
from inventory
group by store_id;


select count(distinct category_id) as unique_categories from film_category;



/* 6. We would like to understand the replacement cost of your films. Please provide the replacement cost for the 
film that is least expensive to replace, the most expensive to replace, and the average of all films you carry.  */


select min(replacement_cost), max(replacement_cost), avg(replacement_cost)
from film;



/* 7. We are interested in having you put payment monitoring systems and maximum payment processing 
restrictions in place in order to minimize the future risk of fraud by your staff. Please provide the average 
payment you process, as well as the maximum payment you have processed.  */

select avg(amount) as avg_pay, max(amount) as max_pay
from payment;


/* 8. We would like to better understand what your customer base looks like. Please provide a list of all customer 
identification values, with a count of rentals they have made all-time, with your highest volume customers at 
the top of the list. */

select customer_id, count(rental_id) as rentals_count
from rental 
group by customer_id
order by count(rental_id) DESC;


-- --------------------------------------------------------------------------------------
-- part 2

/* 1. My partner and I want to come by each of the stores in person and meet the managers. Please send over 
the managers’ names at each store, with the full address of each property (street address, district, city, and 
country please). */


select store.store_id, store.manager_staff_id, address.address, address.district, city.city, country.country
from store inner join address on store.address_id = address.address_id 
inner join city on address.city_id = city.city_id
inner join country on city.country_id = country.country_id;



/* 2.  I would like to get a better understanding of all of the inventory that would come along with the business. 
Please pull together a list of each inventory item you have stocked, including the store_id number, the 
inventory_id, the name of the film, the film’s rating, its rental rate and replacement cost. */

select inventory.inventory_id, inventory.store_id, film.title, film.rating, film.rental_rate, film.replacement_cost
from inventory inner join film on inventory.film_id = film.film_id;

/* 3. From the same list of films you just pulled, please roll that data up and provide a summary level overview of 
your inventory. We would like to know how many inventory items you have with each rating at each store.  */

select store_id, count(inventory_id), film.rating
from film inner join inventory on film.film_id = inventory.film_id
group by store_id, film.rating;


/* 4. Similarly, we want to understand how diversified the inventory is in terms of replacement cost. We want to 
see how big of a hit it would be if a certain category of film became unpopular at a certain store.
 We would like to see the number of films, as well as the average replacement cost, and total replacement 
cost, sliced by store and film category. */

select store_id, film_category.category_id, count(film.film_id) as nu_of_film, avg(film.replacement_cost) as repla_cost,
sum(film.replacement_cost) as total_replace
from film inner join inventory on film.film_id = inventory.film_id
inner join film_category on film_category.film_id = inventory.film_id
group by store_id, film_category.category_id;


/* 5. We want to make sure you folks have a good handle on who your customers are. Please provide a list 
of all customer names, which store they go to, whether or not they are currently active,  and their full 
addresses – street address, city, and country. */

select customer.first_name, customer.last_name, customer.store_id, customer.active, address.address, city.city, country.country
from customer inner join address on customer.address_id = address.address_id
inner join city on address.city_id = city.city_id
inner join country on city.country_id = country.country_id;



/* 6. We would like to understand how much your customers are spending with you, and also to know who your 
most valuable customers are. Please pull together a list of customer names, their total lifetime rentals, and the 
sum of all payments you have collected from them. It would be great to see this ordered on total lifetime value, 
with the most valuable customers at the top of the list.  */


select customer.first_name, customer.last_name, count(distinct rental.rental_id) as lifetime_rentals, sum(payment.amount) as total_lifetime_value
from customer left join payment on  customer.customer_id = payment.customer_id
left join rental on customer.customer_id = rental.customer_id
group by customer.customer_id
order by total_lifetime_value DESC;




/* 7. My partner and I would like to get to know your board of advisors and any current investors. Could you 
please provide a list of advisor and investor names in one table? Could you please note whether they are an 
investor or an advisor, and for the investors, it would be good to include which company they work with.  */

select 'advisor' as _type, first_name, last_name, NULL AS company_name from advisor
union
select 'investor' as _type, first_name, last_name,  company_name from investor;


/* 8. We're interested in how well you have covered the most-awarded actors. Of all the actors with three types of 
awards, for what % of them do we carry a film? And how about for actors with two types of awards? Same 
questions. Finally, how about actors with just one award?  */

SELECT 
    actor_id,
    LENGTH(awards) - LENGTH(REPLACE(awards, ',', '')) + 1 AS award_count
FROM actor_award
WHERE actor_id IS NOT NULL;



WITH actor_award_counts AS (
    SELECT 
        actor_id,
        LENGTH(awards) - LENGTH(REPLACE(awards, ',', '')) + 1 AS award_count
    FROM actor_award
    WHERE actor_id IS NOT NULL
),
award_groups AS (
    SELECT
        award_count,
        COUNT(DISTINCT actor_id) AS total_actors
    FROM actor_award_counts
    GROUP BY award_count
),
actors_in_films AS (
    SELECT DISTINCT actor_id
    FROM film_actor
),
matched_actors AS (
    SELECT 
        aac.award_count,
        COUNT(DISTINCT aac.actor_id) AS matched_actors
    FROM actor_award_counts aac
    JOIN actors_in_films fif ON aac.actor_id = fif.actor_id
    GROUP BY aac.award_count
)
SELECT 
    ag.award_count,
    ag.total_actors,
    COALESCE(ma.matched_actors, 0) AS matched_actors,
    ROUND(COALESCE(ma.matched_actors, 0) * 100.0 / ag.total_actors, 2) AS percentage_in_films
FROM award_groups ag
LEFT JOIN matched_actors ma ON ag.award_count = ma.award_count
ORDER BY ag.award_count DESC;







