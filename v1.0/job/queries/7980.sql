WITH RecursiveMovieData AS (
    SELECT
        t.id AS movie_id,
        t.title,
        t.production_year,
        c.name AS company_name,
        k.keyword AS keywords,
        a.name AS actor_name,
        r.role AS actor_role
    FROM title t
    JOIN movie_companies mc ON t.id = mc.movie_id
    JOIN company_name c ON mc.company_id = c.id
    JOIN movie_keyword mk ON t.id = mk.movie_id
    JOIN keyword k ON mk.keyword_id = k.id
    JOIN complete_cast cc ON t.id = cc.movie_id
    JOIN cast_info ci ON cc.subject_id = ci.id
    JOIN aka_name a ON ci.person_id = a.person_id
    JOIN role_type r ON ci.role_id = r.id
    WHERE t.production_year BETWEEN 1990 AND 2023
),
AggregationData AS (
    SELECT
        movie_id,
        title,
        production_year,
        STRING_AGG(DISTINCT company_name, ', ') AS companies,
        STRING_AGG(DISTINCT keywords, ', ') AS all_keywords,
        STRING_AGG(DISTINCT actor_name || ' (' || actor_role || ')', ', ') AS actors
    FROM RecursiveMovieData
    GROUP BY movie_id, title, production_year
)
SELECT
    movie_id,
    title,
    production_year,
    companies,
    all_keywords,
    actors
FROM AggregationData
ORDER BY production_year DESC, title;
