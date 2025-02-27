WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000

    UNION ALL

    SELECT 
        ml.linked_movie_id,
        at.title,
        at.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
    WHERE 
        at.production_year >= 2000
),
CastDetails AS (
    SELECT 
        ci.movie_id,
        COUNT(ci.person_id) AS cast_count,
        STRING_AGG(DISTINCT ak.name, ', ') AS actor_names
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    GROUP BY 
        ci.movie_id
),
MovieInfo AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        COALESCE(ci.cast_count, 0) AS cast_count,
        COALESCE(ci.actor_names, 'No cast') AS actor_names,
        CASE 
            WHEN mt.production_year < 2010 THEN 'Older'
            ELSE 'Newer'
        END AS movie_category
    FROM 
        aka_title mt
    LEFT JOIN 
        CastDetails ci ON mt.id = ci.movie_id
)
SELECT 
    mi.title,
    mi.production_year,
    mi.cast_count,
    mi.actor_names,
    mh.level AS hierarchy_level
FROM 
    MovieInfo mi
LEFT JOIN 
    MovieHierarchy mh ON mi.movie_id = mh.movie_id
WHERE 
    mi.cast_count > 0
ORDER BY 
    mh.level DESC, mi.production_year DESC;

-- Performance Benchmarking Considerations:
-- This query incorporates:
-- 1. Recursive CTE to build a movie hierarchy from linked movies.
-- 2. Aggregation with COUNT and STRING_AGG to gather cast information.
-- 3. LEFT JOIN to combine movie details with casting information.
-- 4. CASE statement to categorize movies by year.
-- 5. Filtering to exclude movies without cast.
-- 6. Complex ordering based on multiple criteria.
