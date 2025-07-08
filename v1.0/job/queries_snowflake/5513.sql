WITH movie_details AS (
    SELECT t.id AS movie_id, t.title, t.production_year, COUNT(DISTINCT mc.company_id) AS company_count, 
           COUNT(DISTINCT mk.keyword_id) AS keyword_count
    FROM aka_title t
    JOIN movie_companies mc ON t.id = mc.movie_id
    JOIN movie_keyword mk ON t.id = mk.movie_id
    GROUP BY t.id, t.title, t.production_year
),
actor_counts AS (
    SELECT ci.movie_id, COUNT(DISTINCT a.id) AS actor_count
    FROM cast_info ci
    JOIN aka_name a ON ci.person_id = a.person_id
    GROUP BY ci.movie_id
)
SELECT md.movie_id, md.title, md.production_year, md.company_count, md.keyword_count, ac.actor_count
FROM movie_details md
JOIN actor_counts ac ON md.movie_id = ac.movie_id
WHERE md.production_year > 2000
ORDER BY md.production_year DESC, md.title;
