WITH MovieDetails AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        k.keyword AS movie_keyword,
        a.name AS actor_name,
        r.role AS actor_role
    FROM 
        title t
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        role_type r ON ci.role_id = r.id
    WHERE 
        t.production_year >= 2000
    AND 
        k.keyword IN ('Action', 'Adventure', 'Comedy')
),
AggregatedData AS (
    SELECT 
        movie_title,
        production_year,
        STRING_AGG(DISTINCT movie_keyword, ', ') AS keywords,
        STRING_AGG(DISTINCT actor_name || ' (' || actor_role || ')', ', ') AS cast
    FROM 
        MovieDetails
    GROUP BY 
        movie_title, production_year
)
SELECT 
    movie_title,
    production_year,
    keywords,
    cast
FROM 
    AggregatedData
ORDER BY 
    production_year DESC, movie_title;
