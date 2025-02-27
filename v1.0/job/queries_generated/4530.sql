WITH ranked_movies AS (
    SELECT 
        a.title,
        a.production_year,
        COUNT(DISTINCT ca.person_id) AS actor_count,
        COUNT(DISTINCT kc.keyword) AS keyword_count,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY COUNT(DISTINCT ca.person_id) DESC) AS year_rank
    FROM aka_title a
    LEFT JOIN cast_info ca ON a.id = ca.movie_id
    LEFT JOIN movie_keyword mk ON a.id = mk.movie_id
    LEFT JOIN keyword kc ON mk.keyword_id = kc.id
    GROUP BY a.id, a.title, a.production_year
),
top_movies AS (
    SELECT title, production_year, actor_count, keyword_count
    FROM ranked_movies
    WHERE year_rank <= 5
),
actor_info AS (
    SELECT 
        ak.name AS actor_name,
        ca.movie_id,
        COUNT(DISTINCT ci.id) AS roles_count
    FROM aka_name ak
    JOIN cast_info ci ON ak.person_id = ci.person_id
    JOIN top_movies tm ON ci.movie_id IN (
        SELECT m.id FROM aka_title m WHERE m.production_year = tm.production_year
    )
    GROUP BY ak.name, ci.movie_id
)
SELECT 
    tm.title,
    tm.production_year,
    ARRAY_AGG(DISTINCT akt.actor_name) AS top_actors,
    tm.actor_count,
    tm.keyword_count,
    (SELECT COUNT(*) FROM title t WHERE t.production_year = tm.production_year) AS total_movies_per_year
FROM top_movies tm
LEFT JOIN actor_info akt ON tm.title = (SELECT title FROM aka_title WHERE id = akt.movie_id)
GROUP BY tm.title, tm.production_year, tm.actor_count, tm.keyword_count
ORDER BY tm.production_year DESC, tm.actor_count DESC;
