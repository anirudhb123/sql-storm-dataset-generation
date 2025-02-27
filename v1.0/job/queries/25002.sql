WITH RankedMovies AS (
    SELECT 
        at.title AS movie_title,
        at.production_year,
        ak.name AS actor_name,
        COUNT(ci.id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY at.id ORDER BY COUNT(ci.id) DESC) AS rank
    FROM 
        aka_title at
    JOIN 
        cast_info ci ON at.id = ci.movie_id
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    WHERE 
        at.production_year BETWEEN 2000 AND 2023
        AND ak.name IS NOT NULL
    GROUP BY 
        at.id, at.title, at.production_year, ak.name
),
FilteredMovies AS (
    SELECT 
        movie_title,
        production_year,
        actor_name,
        cast_count
    FROM 
        RankedMovies
    WHERE 
        rank <= 5
)
SELECT 
    fm.movie_title,
    fm.production_year,
    STRING_AGG(fm.actor_name, ', ') AS top_actors,
    fm.cast_count
FROM 
    FilteredMovies fm
GROUP BY 
    fm.movie_title, fm.production_year, fm.cast_count
ORDER BY 
    fm.production_year DESC, fm.cast_count DESC;