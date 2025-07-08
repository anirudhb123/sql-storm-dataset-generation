
WITH actor_movies AS (
    SELECT a.name AS actor_name, t.title AS movie_title, t.production_year,
           ROW_NUMBER() OVER (PARTITION BY a.person_id ORDER BY t.production_year DESC) AS rn,
           COUNT(*) OVER (PARTITION BY a.person_id) AS total_movies
    FROM aka_name a
    JOIN cast_info c ON a.person_id = c.person_id
    JOIN aka_title t ON c.movie_id = t.movie_id
    WHERE a.name IS NOT NULL AND t.production_year IS NOT NULL
),
high_rated_movies AS (
    SELECT mk.movie_id, COUNT(*) AS keyword_count
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
    WHERE k.keyword LIKE '%Oscar%'
    GROUP BY mk.movie_id
    HAVING COUNT(*) > 5
),
movie_overview AS (
    SELECT t.title, t.production_year, COUNT(DISTINCT c.person_id) AS num_cast_members
    FROM aka_title t
    LEFT JOIN cast_info c ON t.id = c.movie_id
    GROUP BY t.title, t.production_year
    HAVING COUNT(DISTINCT c.person_id) > 1
)
SELECT DISTINCT am.actor_name, am.movie_title, am.production_year, 
       mh.keyword_count, mo.num_cast_members
FROM actor_movies am
LEFT JOIN high_rated_movies mh ON am.movie_title = (SELECT title FROM aka_title WHERE id = mh.movie_id LIMIT 1)
LEFT JOIN movie_overview mo ON am.movie_title = mo.title
WHERE am.total_movies > 3 AND am.rn <= 5
AND (mh.keyword_count IS NOT NULL OR mo.num_cast_members IS NOT NULL)
ORDER BY am.production_year DESC, am.actor_name;
