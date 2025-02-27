WITH ranked_actors AS (
    SELECT a.id AS actor_id, a.name, COUNT(ci.movie_id) AS movie_count
    FROM aka_name a
    JOIN cast_info ci ON a.person_id = ci.person_id
    GROUP BY a.id, a.name
),
top_movies AS (
    SELECT t.title, t.production_year, COUNT(DISTINCT ci.person_id) AS actor_count
    FROM aka_title t
    JOIN cast_info ci ON t.id = ci.movie_id
    GROUP BY t.id, t.title, t.production_year
    ORDER BY actor_count DESC
    LIMIT 10
),
detailed_info AS (
    SELECT tm.title, tm.production_year, ra.name AS actor_name, ra.movie_count
    FROM top_movies tm
    JOIN ranked_actors ra ON ra.movie_count > 2
)
SELECT di.title, di.production_year, di.actor_name, di.movie_count
FROM detailed_info di
ORDER BY di.production_year DESC, di.actor_name;
