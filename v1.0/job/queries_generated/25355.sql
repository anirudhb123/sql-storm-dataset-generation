WITH relevant_movies AS (
    SELECT t.id AS movie_id, t.title, t.production_year, k.keyword
    FROM title t
    JOIN movie_keyword mk ON t.id = mk.movie_id
    JOIN keyword k ON mk.keyword_id = k.id
    WHERE t.production_year >= 2000
      AND k.keyword LIKE '%Action%'
),
cast_roles AS (
    SELECT ci.movie_id, ci.note AS cast_note, rt.role
    FROM cast_info ci
    JOIN role_type rt ON ci.role_id = rt.id
),
actor_aka_names AS (
    SELECT ak.person_id, ak.name AS aka_name
    FROM aka_name ak
    JOIN cast_info ci ON ak.person_id = ci.person_id
),
complete_cast_info AS (
    SELECT r.movie_id, r.cast_note, ak.aka_name, c.company_name
    FROM cast_roles r
    LEFT JOIN actor_aka_names ak ON r.movie_id = ak.person_id
    LEFT JOIN movie_companies mc ON r.movie_id = mc.movie_id
    LEFT JOIN company_name c ON mc.company_id = c.id
    WHERE c.country_code = 'USA'
)
SELECT 
    cm.movie_id,
    cm.title,
    cm.production_year,
    cci.cast_note,
    cci.aka_name,
    COUNT(DISTINCT cci.company_name) AS company_count
FROM relevant_movies cm
LEFT JOIN complete_cast_info cci ON cm.movie_id = cci.movie_id
GROUP BY cm.movie_id, cm.title, cm.production_year, cci.cast_note, cci.aka_name
ORDER BY cm.production_year DESC, cm.title;
