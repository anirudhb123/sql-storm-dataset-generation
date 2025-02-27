WITH MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        a.name AS actor_name,
        c.kind AS role_type,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        title t
    JOIN 
        cast_info ci ON t.id = ci.movie_id
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        role_type c ON ci.role_id = c.id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        t.production_year BETWEEN 2000 AND 2023
    GROUP BY 
        t.id, t.title, t.production_year, a.name, c.kind
), 
FilteredMovies AS (
    SELECT 
        md.movie_id,
        md.title,
        md.production_year,
        md.actor_name,
        md.role_type,
        md.keywords,
        COUNT(md.movie_id) OVER (PARTITION BY md.movie_id) AS actor_count
    FROM 
        MovieDetails md
)
SELECT 
    fm.movie_id,
    fm.title,
    fm.production_year,
    fm.actor_name,
    fm.role_type,
    fm.keywords,
    fm.actor_count
FROM 
    FilteredMovies fm
WHERE 
    fm.actor_count > 2
ORDER BY 
    fm.production_year DESC, 
    fm.title ASC;
