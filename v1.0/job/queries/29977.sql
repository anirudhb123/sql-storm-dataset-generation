WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        a.name AS actor_name,
        a.imdb_index AS actor_index,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies
    FROM 
        aka_title t
        JOIN cast_info ci ON t.id = ci.movie_id
        JOIN aka_name a ON ci.person_id = a.person_id
        LEFT JOIN movie_keyword mk ON t.id = mk.movie_id
        LEFT JOIN keyword k ON mk.keyword_id = k.id
        LEFT JOIN movie_companies mc ON t.id = mc.movie_id
        LEFT JOIN company_name cn ON mc.company_id = cn.id
    WHERE 
        t.production_year >= 2000
        AND t.production_year <= 2023
        AND a.name IS NOT NULL
    GROUP BY 
        t.id, t.title, t.production_year, a.name, a.imdb_index
),

TitleStats AS (
    SELECT 
        movie_id,
        COUNT(actor_name) AS actor_count,
        COUNT(DISTINCT companies) AS company_count,
        MIN(production_year) AS first_year,
        MAX(production_year) AS last_year
    FROM 
        MovieDetails
    GROUP BY 
        movie_id
)

SELECT 
    md.movie_id,
    md.movie_title,
    ts.actor_count,
    ts.company_count,
    ts.first_year,
    ts.last_year,
    md.keywords
FROM 
    MovieDetails md
JOIN 
    TitleStats ts ON md.movie_id = ts.movie_id
ORDER BY 
    ts.actor_count DESC, 
    md.movie_title ASC
LIMIT 100;
