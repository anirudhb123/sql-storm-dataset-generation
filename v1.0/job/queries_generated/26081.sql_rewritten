WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        c.name AS company_name,
        k.keyword,
        ARRAY_AGG(DISTINCT a.name) AS actor_names
    FROM 
        aka_title t
    JOIN 
        movie_companies mc ON mc.movie_id = t.id
    JOIN 
        company_name c ON c.id = mc.company_id
    JOIN 
        movie_keyword mk ON mk.movie_id = t.id
    JOIN 
        keyword k ON k.id = mk.keyword_id
    JOIN 
        cast_info ci ON ci.movie_id = t.id
    JOIN 
        aka_name a ON a.person_id = ci.person_id
    WHERE 
        t.production_year BETWEEN 2000 AND 2023
    GROUP BY 
        t.id, t.title, t.production_year, c.name, k.keyword
),
FilteredMovies AS (
    SELECT 
        md.movie_id,
        md.title,
        md.production_year,
        md.company_name,
        md.keyword,
        md.actor_names
    FROM 
        MovieDetails md
    WHERE 
        ARRAY_LENGTH(md.actor_names, 1) > 3 
      AND 
        md.production_year = (
            SELECT MAX(production_year) FROM MovieDetails
        ) 
)
SELECT 
    fm.title,
    fm.production_year,
    fm.company_name,
    fm.keyword,
    fm.actor_names
FROM 
    FilteredMovies fm
ORDER BY 
    fm.title;