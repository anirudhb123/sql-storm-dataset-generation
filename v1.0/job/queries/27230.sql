
WITH RankedMovies AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        ARRAY_AGG(DISTINCT a.name) AS actor_names,
        COUNT(DISTINCT k.keyword) AS keyword_count
    FROM 
        aka_title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    GROUP BY 
        t.title, t.production_year
),
MovieMetrics AS (
    SELECT 
        movie_title,
        production_year,
        actor_names,
        keyword_count,
        ROW_NUMBER() OVER (ORDER BY keyword_count DESC, production_year DESC) AS rank
    FROM 
        RankedMovies
)
SELECT 
    movie_title,
    production_year,
    actor_names,
    keyword_count,
    rank,
    CASE 
        WHEN keyword_count > 10 THEN 'High'
        WHEN keyword_count BETWEEN 5 AND 10 THEN 'Medium'
        ELSE 'Low'
    END AS keyword_density
FROM 
    MovieMetrics
WHERE 
    production_year >= 2010 
ORDER BY 
    rank
LIMIT 50;
