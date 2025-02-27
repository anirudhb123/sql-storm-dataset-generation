WITH RecursiveMovieData AS (
    SELECT 
        a.title AS movie_title,
        a.production_year,
        ak.name AS actor_name,
        CT.kind AS cast_type,
        ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY ak.name) AS actor_order,
        COALESCE(ci.note, 'No Note') AS cast_note
    FROM 
        aka_title a
    LEFT JOIN 
        cast_info ci ON a.id = ci.movie_id
    LEFT JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    LEFT JOIN 
        comp_cast_type CT ON ci.person_role_id = CT.id
    WHERE 
        a.production_year BETWEEN 1990 AND 2020
),

FilteredMovies AS (
    SELECT 
        movie_title,
        production_year,
        actor_name,
        cast_type,
        actor_order,
        cast_note,
        COUNT(*) OVER (PARTITION BY production_year) AS movie_count_per_year
    FROM 
        RecursiveMovieData
    WHERE 
        actor_order < 5 -- Limiting to top 4 actors per movie
)

SELECT 
    fm.production_year,
    STRING_AGG(fm.actor_name, ', ') AS top_actors,
    MAX(fm.movie_count_per_year) AS total_movies,
    SUM(CASE 
            WHEN fm.cast_type IS NULL THEN 1 
            ELSE 0 
        END) AS unknown_roles,
    COUNT(DISTINCT fm.movie_title) AS unique_movies_count
FROM 
    FilteredMovies fm
GROUP BY 
    fm.production_year
ORDER BY 
    fm.production_year ASC;

-- Additional complexity: handling NULL logic and obscure edge cases
SELECT 
    fm.production_year,
    COUNT(DISTINCT COALESCE(fm.actor_name, 'Unknown Actor')) AS distinct_actor_count,
    SUM(CASE
            WHEN fm.cast_note LIKE '%featured%' THEN 1
            ELSE 0
        END) AS featured_appearances,
    COALESCE(MAX(fm.total_movies), 0) AS valid_movie_count
FROM 
    FilteredMovies fm
LEFT JOIN 
    FilteredMovies f2 ON fm.production_year = f2.production_year AND fm.actor_name = f2.actor_name
WHERE 
    fm.actor_order <= 3
GROUP BY 
    fm.production_year
HAVING 
    COUNT(*) > 1; -- Ensuring there's at least one movie with multiple actors
