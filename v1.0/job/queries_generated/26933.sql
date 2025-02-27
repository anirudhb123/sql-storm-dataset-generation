WITH movie_keywords AS (
    SELECT m.id AS movie_id, m.title, k.keyword
    FROM aka_title m
    JOIN movie_keyword mk ON m.id = mk.movie_id
    JOIN keyword k ON mk.keyword_id = k.id
    WHERE m.production_year BETWEEN 2000 AND 2020
),
actor_movie_info AS (
    SELECT a.id AS actor_id, a.name AS actor_name, c.movie_id, t.title, t.production_year
    FROM aka_name a
    JOIN cast_info c ON a.person_id = c.person_id
    JOIN aka_title t ON c.movie_id = t.id
    WHERE a.name ILIKE '%John%'
),
company_info AS (
    SELECT c.id AS company_id, c.name AS company_name, ct.kind AS company_type, mc.movie_id
    FROM company_name c
    JOIN movie_companies mc ON c.id = mc.company_id
    JOIN company_type ct ON mc.company_type_id = ct.id
),
cast_summary AS (
    SELECT am.actor_id, am.actor_name, COUNT(ci.movie_id) AS total_movies
    FROM actor_movie_info am
    JOIN cast_info ci ON am.movie_id = ci.movie_id
    GROUP BY am.actor_id, am.actor_name
)
SELECT 
    a.actor_id, 
    a.actor_name, 
    COUNT(DISTINCT mk.keyword) AS keyword_count, 
    MAX(csi.total_movies) AS max_movies,
    STRING_AGG(DISTINCT mk.keyword, ', ') AS keywords,
    STRING_AGG(DISTINCT ci.company_name, ', ') AS companies
FROM actor_movie_info a
LEFT JOIN movie_keywords mk ON a.movie_id = mk.movie_id
LEFT JOIN company_info ci ON a.movie_id = ci.movie_id
LEFT JOIN cast_summary csi ON a.actor_id = csi.actor_id
GROUP BY a.actor_id, a.actor_name
HAVING COUNT(DISTINCT mk.keyword) > 1
ORDER BY max_movies DESC;
