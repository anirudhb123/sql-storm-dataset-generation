WITH recursive movie_actor AS (
    SELECT ca.movie_id, ka.person_id, ka.name, 
           ROW_NUMBER() OVER (PARTITION BY ca.movie_id ORDER BY ka.name) AS actor_order
    FROM cast_info ca
    JOIN aka_name ka ON ca.person_id = ka.person_id
    WHERE ka.name IS NOT NULL
),
filtered_movies AS (
    SELECT m.id AS movie_id, m.title, m.production_year, COUNT(DISTINCT c.person_id) AS actor_count
    FROM aka_title m
    LEFT JOIN cast_info c ON m.id = c.movie_id
    GROUP BY m.id, m.title, m.production_year
    HAVING COUNT(DISTINCT c.person_id) >= 2
),
actor_movie_info AS (
    SELECT ma.movie_id, ma.name AS actor_name, f.title, f.production_year, 
           COALESCE(mi.info, 'No Info') AS movie_info
    FROM movie_actor ma
    JOIN filtered_movies f ON ma.movie_id = f.movie_id
    LEFT JOIN movie_info mi ON ma.movie_id = mi.movie_id AND mi.info_type_id = 1
),
ranked_movies AS (
    SELECT actor_name, title, production_year, movie_info,
           DENSE_RANK() OVER (PARTITION BY actor_name ORDER BY production_year DESC) AS year_rank
    FROM actor_movie_info
)
SELECT actor_name, title, production_year, movie_info,
       CASE 
           WHEN year_rank = 1 THEN 'Latest Movie'
           ELSE CONCAT('Rank ', year_rank)
       END AS movie_rank
FROM ranked_movies
WHERE production_year IS NOT NULL
OR movie_info IS NOT NULL
ORDER BY actor_name, production_year DESC;