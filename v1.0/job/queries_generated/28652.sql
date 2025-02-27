WITH movie_keywords AS (
    SELECT mk.movie_id, k.keyword
    FROM movie_keyword mk
    JOIN keyword k ON mk.keyword_id = k.id
),
casted_movies AS (
    SELECT c.movie_id, c.person_id, a.name AS actor_name
    FROM cast_info c
    JOIN aka_name a ON c.person_id = a.person_id
),
company_movies AS (
    SELECT mc.movie_id, cn.name AS company_name, ct.kind AS company_type
    FROM movie_companies mc
    JOIN company_name cn ON mc.company_id = cn.id
    JOIN company_type ct ON mc.company_type_id = ct.id
),
movie_details AS (
    SELECT t.title, t.production_year, mk.keyword, cm.company_name, cm.company_type, cm.movie_id
    FROM title t
    JOIN movie_keywords mk ON t.id = mk.movie_id
    JOIN company_movies cm ON t.id = cm.movie_id
)
SELECT 
    md.title,
    md.production_year,
    STRING_AGG(DISTINCT md.keyword, ', ') AS keywords,
    STRING_AGG(DISTINCT md.company_name || ' (' || md.company_type || ')', '; ') AS companies,
    COUNT(DISTINCT cm.person_id) AS cast_count
FROM movie_details md
JOIN casted_movies cm ON md.movie_id = cm.movie_id
WHERE md.production_year BETWEEN 2000 AND 2020
GROUP BY md.title, md.production_year
ORDER BY md.production_year DESC, md.title;
