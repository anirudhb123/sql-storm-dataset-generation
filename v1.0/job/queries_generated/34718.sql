WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id, 
        m.title,
        1 AS level
    FROM 
        aka_title m
    WHERE 
        m.production_year BETWEEN 2000 AND 2023

    UNION ALL

    SELECT 
        m.id AS movie_id, 
        CONCAT(m.title, ' (Sequel)') AS title,
        level + 1
    FROM 
        aka_title m
    INNER JOIN 
        movie_link ml ON m.id = ml.linked_movie_id
    INNER JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
),

FilteredMovies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        COUNT(c.id) AS cast_count,
        STRING_AGG(DISTINCT a.name, ', ') AS actor_names
    FROM 
        MovieHierarchy mh
    LEFT JOIN 
        cast_info c ON c.movie_id = mh.movie_id
    LEFT JOIN 
        aka_name a ON a.person_id = c.person_id
    GROUP BY 
        mh.movie_id, mh.title

),

RankedMovies AS (
    SELECT 
        fm.movie_id,
        fm.title,
        fm.cast_count,
        fm.actor_names,
        RANK() OVER (ORDER BY fm.cast_count DESC) AS rank
    FROM 
        FilteredMovies fm
    WHERE 
        fm.cast_count IS NOT NULL
)

SELECT 
    rm.rank,
    rm.title,
    rm.cast_count,
    rm.actor_names,
    COALESCE(mi.info, 'No additional info') AS additional_info
FROM 
    RankedMovies rm
LEFT JOIN 
    movie_info mi ON rm.movie_id = mi.movie_id
WHERE 
    rm.rank <= 10
ORDER BY 
    rm.rank;
