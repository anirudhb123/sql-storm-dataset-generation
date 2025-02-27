WITH RankedMovies AS (
    SELECT 
        t.title,
        t.production_year,
        a.name AS actor_name,
        COUNT(ci.person_id) AS cast_count,
        STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY t.production_year DESC) AS rank
    FROM 
        aka_title t
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword kw ON mk.keyword_id = kw.id
    GROUP BY 
        t.id, t.title, t.production_year, a.name
), FilteredMovies AS (
    SELECT 
        title, 
        production_year, 
        actor_name, 
        cast_count, 
        keywords
    FROM 
        RankedMovies
    WHERE 
        rank = 1 AND cast_count > 5
)
SELECT 
    ROW_NUMBER() OVER (ORDER BY production_year DESC) AS ranking,
    title,
    production_year,
    actor_name,
    cast_count,
    keywords
FROM 
    FilteredMovies
ORDER BY 
    production_year DESC, 
    cast_count DESC;