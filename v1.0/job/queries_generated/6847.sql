WITH movie_details AS (
    SELECT t.id AS movie_id, t.title, t.production_year, k.keyword
    FROM title t
    JOIN movie_keyword mk ON t.id = mk.movie_id
    JOIN keyword k ON mk.keyword_id = k.id
    WHERE t.production_year BETWEEN 2000 AND 2020
),
actor_details AS (
    SELECT a.id AS person_id, a.name, c.movie_id
    FROM aka_name a
    JOIN cast_info c ON a.person_id = c.person_id
    WHERE a.name IS NOT NULL
),
info_summary AS (
    SELECT md.movie_id, COUNT(DISTINCT ad.person_id) AS actor_count, STRING_AGG(DISTINCT ad.name, ', ') AS actors
    FROM movie_details md
    LEFT JOIN actor_details ad ON md.movie_id = ad.movie_id
    GROUP BY md.movie_id
)
SELECT md.title, md.production_year, is.actor_count, is.actors
FROM movie_details md
JOIN info_summary is ON md.movie_id = is.movie_id
ORDER BY md.production_year DESC, is.actor_count DESC;
