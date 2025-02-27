
WITH MovieDetails AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        STRING_AGG(a.name, ', ') AS actors,
        STRING_AGG(c.kind, ', ') AS company_types,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        aka_title t
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_type c ON mc.company_type_id = c.id
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        t.id, t.title, t.production_year
),
FilteredMovies AS (
    SELECT 
        movie_title,
        production_year,
        actors,
        company_types,
        keywords
    FROM 
        MovieDetails
    WHERE 
        production_year >= 2000 AND
        LOWER(actors) LIKE '%john%' 
)
SELECT 
    movie_title,
    production_year,
    actors,
    company_types,
    keywords
FROM 
    FilteredMovies
ORDER BY 
    production_year DESC;
