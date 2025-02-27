
WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        t.id AS movie_id,
        t.title AS movie_title,
        t.production_year,
        NULL AS parent_id,
        1 AS level
    FROM 
        aka_title t
    WHERE 
        t.episode_of_id IS NULL

    UNION ALL

    SELECT 
        e.id AS movie_id,
        e.title AS movie_title,
        e.production_year,
        mh.movie_id AS parent_id,
        mh.level + 1 AS level
    FROM 
        aka_title e
    JOIN 
        MovieHierarchy mh ON e.episode_of_id = mh.movie_id
),
CastDetails AS (
    SELECT 
        ci.movie_id,
        COUNT(*) AS cast_count,
        STRING_AGG(aka.name, ', ') AS actor_names
    FROM 
        cast_info ci
    JOIN 
        aka_name aka ON ci.person_id = aka.person_id
    GROUP BY 
        ci.movie_id
),
FilteredMovies AS (
    SELECT 
        mh.movie_id,
        mh.movie_title,
        mh.production_year,
        cd.cast_count,
        cd.actor_names,
        ROW_NUMBER() OVER (PARTITION BY mh.production_year ORDER BY cd.cast_count DESC) AS rank
    FROM 
        MovieHierarchy mh
    LEFT JOIN 
        CastDetails cd ON mh.movie_id = cd.movie_id
    WHERE 
        mh.production_year IS NOT NULL
)
SELECT 
    fm.movie_title,
    fm.production_year,
    fm.cast_count,
    fm.actor_names,
    COALESCE((SELECT AVG(cast_count) FROM FilteredMovies f2 WHERE f2.production_year = fm.production_year), 0) AS avg_cast_count,
    CASE 
        WHEN fm.cast_count > COALESCE((SELECT AVG(cast_count) FROM FilteredMovies f2 WHERE f2.production_year = fm.production_year), 0) THEN 'Above Average'
        ELSE 'Below Average'
    END AS performance_rating
FROM 
    FilteredMovies fm
WHERE 
    fm.rank <= 5 
ORDER BY 
    fm.production_year, fm.rank;
