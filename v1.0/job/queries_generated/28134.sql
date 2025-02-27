WITH RankedMovies AS (
    SELECT 
        a.id AS movie_id,
        a.title,
        a.production_year,
        k.keyword,
        r.role,
        c.nr_order,
        ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY c.nr_order ASC) AS actor_rank
    FROM 
        aka_title a
    JOIN 
        movie_keyword mk ON a.id = mk.movie_id
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        cast_info c ON a.id = c.movie_id
    JOIN 
        role_type r ON c.role_id = r.id
    WHERE 
        a.production_year IS NOT NULL
),
FilteredMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        STRING_AGG(DISTINCT rm.keyword, ', ') AS keywords,
        STRING_AGG(DISTINCT rm.role || ' (' || rm.nr_order || ')', ', ') AS cast,
        MAX(rm.actor_rank) AS cast_size
    FROM 
        RankedMovies rm
    WHERE 
        LOWER(rm.title) LIKE '%action%'  -- Example filter for movies containing 'action'
    GROUP BY 
        rm.movie_id,
        rm.title,
        rm.production_year
)
SELECT 
    fm.movie_id,
    fm.title,
    fm.production_year,
    fm.keywords,
    fm.cast,
    fm.cast_size
FROM 
    FilteredMovies fm
WHERE 
    fm.cast_size > 5  -- Example filter for movies with more than 5 cast members
ORDER BY 
    fm.production_year DESC, 
    fm.title ASC;
This SQL query performs a comprehensive benchmarking of string processing by retrieving movie titles that contain the keyword "action," along with their associated keywords and cast information, while filtering out movies with fewer than six cast members. It utilizes Common Table Expressions (CTE) for improved readability and efficiency, allows for flexible keyword searching, and aggregates string results for a more inclusive output.
