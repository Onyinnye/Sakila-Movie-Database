/* Query for first Insight */
WITH t1 AS (
  SELECT
    f.title AS film_name,
    c.name AS category,
    COUNT(rental_id) AS rental_count
  FROM
    category c
    JOIN film_category fc ON c.category_id = fc.category_id
    JOIN film f ON f.film_id = fc.film_id
    JOIN inventory i ON i.film_id = f.film_id
    JOIN rental r ON i.inventory_id = r.inventory_id
    JOIN film_actor fa ON f.film_id = fa.film_id
    JOIN actor a ON a.actor_id = fa.actor_id
  GROUP BY
    film_name,
    category
),
t2 AS (
  SELECT
    category,
    MAX(rental_count) AS max_rental_count
  FROM
    (
      select
        f.title as film_title,
        c.name as category,
        COUNT(r.rental_id) rental_count
      from
        category c
        join film_category fc on c.category_id = fc.category_id
        join film f on f.film_id = fc.film_id
        join inventory i on i.film_id = f.film_id
        join rental r on i.inventory_id = r.inventory_id
        join film_actor fa on f.film_id = fa.film_id
        join actor a on a.actor_id = fa.actor_id
      GROUP BY
        film_title,
        category
      ORDER BY
        rental_count DESC
    ) t1
  GROUP BY
    category
)
SELECT
  film_name,
  t1.category,
  max_rental_count
FROM
  t1
  JOIN t2 ON t1.category = t2.category
  AND t1.rental_count = t2.max_rental_count
ORDER BY
  max_rental_count  DESC;

/* Query for second insight*/
SELECT
  payment_month,
  customer_name,
  COUNT(payment_id),
  sum(amount)
FROM
  (
    SELECT
      first_name || ' ' || last_name as customer_name,
      date_trunc('month', payment_date) as payment_month,
      p.payment_id,
      p.amount
    FROM
      rental r
      JOIN payment p ON p.rental_id = r.rental_id
      JOIN customer c ON p.customer_id = c.customer_id
    WHERE
      payment_date between '2007-01-01'
      and '2007-12-31'
  ) t3
WHERE
  customer_name IN (
    SELECT
      customer_name
    FROM
      (
        SELECT
          c.first_name || ' ' || c.last_name as customer_name,
          SUM(amount) as total_amount
        FROM
          rental r
          JOIN payment p ON p.rental_id = r.rental_id
          JOIN customer c ON p.customer_id = c.customer_id
        WHERE
          payment_date BETWEEN '2007-01-01'
          and '2007-12-31'
        GROUP BY
          customer_name
        ORDER BY
          total_amount desc
        LIMIT
          10
      ) t1
  )
GROUP BY
  payment_month,
  customer_name
ORDER BY
  customer_name,
  payment_month;

/* Query for third insight */
SELECT
  district,
  country,
  COUNT(country) AS country_count,
  sum(amount) AS total_amount
FROM
  payment p
  JOIN customer c ON p.customer_id = c.customer_id
  JOIN address a ON a.address_id = c.address_id
  JOIN city ci ON ci.city_id = a.city_id
  JOIN country co ON co.country_id = ci.country_id
WHERE
  country IN (
    SELECT
      country
    FROM
      (
        SELECT
          country,
          COUNT(country) AS country_count,
          sum(amount) AS total_amount
        FROM
          payment p
          JOIN customer c ON p.customer_id = c.customer_id
          JOIN address a ON a.address_id = c.address_id
          JOIN city ci ON ci.city_id = a.city_id
          JOIN country co ON co.country_id = ci.country_id
        GROUP BY
          country
        ORDER BY
          country_count DESC,
          total_amount DESC
      ) t1
  )
GROUP BY
  district,
  country
ORDER BY
  country_count DESC,
  total_amount DESC;

    /* Query for fourth insight */
    SELECT
      film_category,
      duration_standard_quartile,
      COUNT(*) AS movie_count
    FROM
      (
        SELECT
          c.name AS film_category,
          NTILE (4) OVER (
            ORDER BY
              f.rental_duration
          ) AS duration_standard_quartile,
          COUNT (f.title) OVER (PARTITION BY c.name) AS counts
        FROM
          category c
          JOIN film_category fc ON c.category_id = fc.category_id
          JOIN film f ON f.film_id = fc.film_id
        WHERE
          category.name = 'Animation'
          OR category.name = 'Children'
          OR category.name = 'Classics'
          OR category.name = 'Comedy'
          OR category.name = 'Family'
          OR category.name = 'Music'
      ) t1
    ) t2
    GROUP BY
      film_category,
      duration_standard_quartile
    ORDER BY
      film_category,
      duration_standard_quartile;
