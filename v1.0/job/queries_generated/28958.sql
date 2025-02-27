WITH MovieDetails AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        k.keyword,
        c.name AS company_name,
        rt.role AS cast_role
    FROM title t
    JOIN movie_keyword mk ON t.id = mk.movie_id
    JOIN keyword k ON mk.keyword_id = k.id
    LEFT JOIN movie_companies mc ON t.id = mc.movie_id
    LEFT JOIN company_name c ON mc.company_id = c.id
    LEFT JOIN complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN cast_info ci ON cc.subject_id = ci.person_id
    LEFT JOIN role_type rt ON ci.role_id = rt.id
)

SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    STRING_AGG(DISTINCT md.keyword, ', ') AS keywords,
    STRING_AGG(DISTINCT md.company_name, ', ') AS companies,
    STRING_AGG(DISTINCT md.cast_role, ', ') AS cast_roles
FROM MovieDetails md
GROUP BY md.movie_id, md.title, md.production_year
ORDER BY md.production_year DESC, md.movie_id;
