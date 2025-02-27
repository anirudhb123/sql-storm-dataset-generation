
WITH movie_details AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        a.name AS actor_name,
        r.role AS actor_role,
        ct.kind AS company_type,
        mi.info AS movie_info
    FROM title t
    JOIN cast_info ci ON t.id = ci.movie_id
    JOIN aka_name a ON ci.person_id = a.person_id
    JOIN role_type r ON ci.role_id = r.id
    JOIN movie_companies mc ON t.id = mc.movie_id
    JOIN company_name cn ON mc.company_id = cn.id
    JOIN company_type ct ON mc.company_type_id = ct.id
    LEFT JOIN movie_info mi ON t.id = mi.movie_id
    LEFT JOIN info_type it ON mi.info_type_id = it.id
    WHERE t.production_year BETWEEN 2000 AND 2020
    AND ct.kind = 'Production'
),
aggregated_data AS (
    SELECT 
        movie_title,
        production_year,
        STRING_AGG(DISTINCT actor_name, ', ') AS actors,
        STRING_AGG(DISTINCT actor_role, ', ') AS roles,
        STRING_AGG(DISTINCT company_type, ', ') AS companies,
        STRING_AGG(DISTINCT movie_info, '; ') AS additional_info
    FROM movie_details
    GROUP BY movie_title, production_year
)
SELECT 
    movie_title,
    production_year,
    actors,
    roles,
    companies,
    additional_info
FROM aggregated_data
ORDER BY production_year DESC, movie_title;
