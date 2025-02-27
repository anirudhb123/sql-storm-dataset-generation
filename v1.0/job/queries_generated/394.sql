WITH MovieDetails AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        a.name AS actor_name,
        COUNT(DISTINCT cc.subject_id) OVER (PARTITION BY t.id) AS cast_count,
        STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords,
        ROW_NUMBER() OVER (PARTITION BY t.id ORDER BY a.name) AS actor_rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    LEFT JOIN 
        aka_name a ON c.person_id = a.person_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword kw ON mk.keyword_id = kw.id
    WHERE 
        t.production_year BETWEEN 2000 AND 2023
        AND a.name IS NOT NULL
),
FilteredMovies AS (
    SELECT 
        movie_title,
        production_year,
        actor_name,
        cast_count,
        keywords
    FROM 
        MovieDetails
    WHERE 
        actor_rank <= 3
)
SELECT 
    fm.movie_title,
    fm.production_year,
    fm.actor_name,
    fm.cast_count,
    COALESCE(fm.keywords, 'No keywords') AS keywords
FROM 
    FilteredMovies fm
ORDER BY 
    fm.production_year DESC, 
    fm.movie_title;
