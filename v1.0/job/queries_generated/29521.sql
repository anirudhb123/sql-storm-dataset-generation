WITH MovieDetails AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        a.name AS director_name,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
        STRING_AGG(DISTINCT c.kind, ', ') AS company_types
    FROM 
        aka_title t
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id AND ci.person_role_id = (SELECT id FROM role_type WHERE role = 'Director') 
    JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        movie_companies mc ON t.id = mc.movie_id
    JOIN 
        company_type c ON mc.company_type_id = c.id
    GROUP BY 
        t.title, t.production_year, a.name
),
FilteredMovies AS (
    SELECT 
        movie_title,
        production_year,
        director_name,
        keywords,
        company_types
    FROM 
        MovieDetails
    WHERE 
        production_year >= 2000 
        AND 
        keywords LIKE '%Action%'
)
SELECT 
    movie_title,
    production_year,
    director_name,
    keywords,
    company_types
FROM 
    FilteredMovies
ORDER BY 
    production_year DESC;
