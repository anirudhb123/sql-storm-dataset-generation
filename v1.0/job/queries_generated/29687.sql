WITH movie_details AS (
    SELECT 
        t.id AS title_id, 
        t.title, 
        t.production_year, 
        t.kind_id, 
        k.keyword, 
        g.kind AS genre, 
        c.name AS company_name,
        a.name AS actor_name
    FROM title t
    JOIN movie_keyword mk ON t.id = mk.movie_id
    JOIN keyword k ON mk.keyword_id = k.id
    JOIN movie_companies mc ON t.id = mc.movie_id
    JOIN company_name c ON mc.company_id = c.id
    JOIN kind_type g ON t.kind_id = g.id
    JOIN cast_info ci ON t.id = ci.movie_id
    JOIN aka_name a ON ci.person_id = a.person_id
    GROUP BY t.id, t.title, t.production_year, t.kind_id, k.keyword, g.kind, c.name, a.name
),
aggregated_data AS (
    SELECT 
        title_id,
        title,
        production_year,
        ARRAY_AGG(DISTINCT keyword) AS keywords,
        ARRAY_AGG(DISTINCT genre) AS genres,
        STRING_AGG(DISTINCT company_name, ', ') AS companies,
        STRING_AGG(DISTINCT actor_name, ', ') AS actors
    FROM movie_details
    GROUP BY title_id, title, production_year
)
SELECT 
    title_id,
    title,
    production_year,
    keywords,
    genres,
    companies,
    actors,
    (SELECT COUNT(*) FROM movie_companies mc WHERE mc.movie_id = aggregated_data.title_id) AS total_companies,
    (SELECT COUNT(*) FROM cast_info ci WHERE ci.movie_id = aggregated_data.title_id) AS total_actors
FROM aggregated_data
ORDER BY production_year DESC, title;
