WITH actor_movies AS (
    SELECT ca.movie_id, a.name AS actor_name
    FROM cast_info ca
    JOIN aka_name a ON ca.person_id = a.person_id
    WHERE a.name IS NOT NULL
),
movie_details AS (
    SELECT t.title AS movie_title, t.production_year, t.kind_id, k.keyword AS movie_keyword
    FROM aka_title t
    JOIN movie_keyword mk ON t.id = mk.movie_id
    JOIN keyword k ON mk.keyword_id = k.id
),
company_info AS (
    SELECT mc.movie_id, c.name AS company_name, ct.kind AS company_type
    FROM movie_companies mc
    JOIN company_name c ON mc.company_id = c.id
    JOIN company_type ct ON mc.company_type_id = ct.id
)
SELECT am.actor_name, md.movie_title, md.production_year, md.movie_keyword, ci.company_name, ci.company_type
FROM actor_movies am
JOIN movie_details md ON am.movie_id = md.movie_id
JOIN company_info ci ON am.movie_id = ci.movie_id
WHERE md.production_year BETWEEN 2000 AND 2020 
ORDER BY md.production_year DESC, am.actor_name ASC
LIMIT 100;
