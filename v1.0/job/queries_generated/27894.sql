WITH movie_details AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        k.keyword AS movie_keyword,
        c.name AS company_name
    FROM title m
    JOIN movie_keyword mk ON m.id = mk.movie_id
    JOIN keyword k ON mk.keyword_id = k.id
    JOIN movie_companies mc ON m.id = mc.movie_id
    JOIN company_name c ON mc.company_id = c.id
    WHERE m.production_year BETWEEN 2000 AND 2020
),
cast_details AS (
    SELECT 
        ci.movie_id,
        a.name AS actor_name,
        r.role AS actor_role
    FROM cast_info ci
    JOIN aka_name a ON ci.person_id = a.person_id
    JOIN role_type r ON ci.role_id = r.id
),
benchmark_summary AS (
    SELECT 
        md.movie_title,
        md.production_year,
        STRING_AGG(DISTINCT cd.actor_name, ', ') AS actors,
        STRING_AGG(DISTINCT md.movie_keyword, ', ') AS keywords,
        STRING_AGG(DISTINCT md.company_name, ', ') AS companies
    FROM movie_details md
    LEFT JOIN cast_details cd ON md.movie_id = cd.movie_id
    GROUP BY md.movie_id, md.movie_title, md.production_year
)
SELECT 
    movie_title,
    production_year,
    actors,
    keywords,
    companies
FROM benchmark_summary
ORDER BY production_year, movie_title;
