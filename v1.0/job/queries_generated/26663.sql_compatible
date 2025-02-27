
WITH MovieDetails AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        STRING_AGG(DISTINCT a.name, ', ') AS directors,
        STRING_AGG(DISTINCT c.name, ', ') AS cast_members,
        STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords
    FROM 
        aka_title m
    LEFT JOIN 
        movie_companies mc ON m.id = mc.movie_id
    LEFT JOIN 
        company_name c ON mc.company_id = c.id AND mc.company_type_id = (SELECT id FROM company_type WHERE kind = 'Director')
    LEFT JOIN 
        cast_info ci ON m.id = ci.movie_id
    LEFT JOIN 
        aka_name a ON ci.person_id = a.person_id
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword kw ON mk.keyword_id = kw.id
    GROUP BY 
        m.id, m.title, m.production_year
),

FilteredMovies AS (
    SELECT 
        md.movie_id,
        md.movie_title,
        md.production_year,
        md.directors,
        md.cast_members,
        md.keywords
    FROM 
        MovieDetails md
    WHERE 
        md.production_year BETWEEN 2000 AND 2023
)

SELECT 
    f.movie_title,
    f.production_year,
    f.directors,
    f.cast_members,
    f.keywords
FROM 
    FilteredMovies f
ORDER BY 
    f.production_year DESC, 
    f.movie_title ASC
LIMIT 50;
