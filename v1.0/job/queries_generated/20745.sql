WITH recursive actor_movies AS (
    SELECT ak.person_id, ak.name AS actor_name, at.title AS movie_title, 
           at.production_year, ROW_NUMBER() OVER (PARTITION BY ak.person_id ORDER BY at.production_year) AS movie_rank
    FROM aka_name ak
    JOIN cast_info ci ON ak.person_id = ci.person_id
    JOIN aka_title at ON ci.movie_id = at.movie_id
    WHERE ak.name IS NOT NULL
),
filtered_actors AS (
    SELECT actor_name, COUNT(*) AS movies_count
    FROM actor_movies
    WHERE movie_rank <= 3 -- Only consider the first three movies for each actor
    GROUP BY actor_name
    HAVING COUNT(*) > 2 -- Consider only actors with more than 2 movies
),
unique_movies AS (
    SELECT DISTINCT am.movie_title, am.production_year, 
           COALESCE(CAST(SUBSTRING(am.movie_title FROM '[A-Z]') AS text), 'Unknown') AS title_substring
    FROM actor_movies am
    WHERE EXISTS (
        SELECT 1 
        FROM cast_info ci 
        WHERE ci.movie_id IN (SELECT movie_id FROM aka_title WHERE title = am.movie_title)
        AND ci.note IS NOT NULL
    )
),
keyword_summary AS (
    SELECT mk.keyword, COUNT(*) AS keyword_appearances
    FROM movie_keyword mk
    JOIN aka_title at ON mk.movie_id = at.movie_id
    WHERE at.production_year > 2000
    GROUP BY mk.keyword
    HAVING COUNT(*) > 1
)
SELECT 
    fa.actor_name,
    um.movie_title, 
    um.production_year,
    ks.keyword,
    fa.movies_count,
    COALESCE(NULLIF(ks.keyword, ''), 'N/A') AS keyword_info
FROM filtered_actors fa
LEFT JOIN unique_movies um ON fa.movies_count = (
      SELECT MAX(movies_count)
      FROM filtered_actors
      WHERE actor_name = fa.actor_name
)
LEFT JOIN keyword_summary ks ON um.movie_title = ks.keyword
ORDER BY fa.actor_name, um.production_year DESC;

