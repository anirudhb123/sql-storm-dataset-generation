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
        ml.linked_movie_id AS movie_id,
        mt.title,
        mt.production_year,
        mh.level + 1 AS level
    FROM 
        movie_link ml
    JOIN 
        aka_title mt ON ml.movie_id = mt.id
    JOIN 
        MovieHierarchy mh ON ml.linked_movie_id = mh.movie_id
),
FilteredMovies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_info mi ON mh.movie_id = mi.movie_id
    WHERE 
        mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Genre')
        AND mi.info LIKE '%Action%'
),
RankedMovies AS (
    SELECT 
        fm.movie_id,
        fm.title,
        fm.production_year,
        COUNT(ci.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY fm.production_year ORDER BY COUNT(ci.person_id) DESC) AS rn
    FROM 
        FilteredMovies fm
    LEFT JOIN 
        cast_info ci ON fm.movie_id = ci.movie_id
    GROUP BY 
        fm.movie_id, fm.title, fm.production_year
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    rm.cast_count,
    CASE 
        WHEN rm.cast_count IS NULL THEN 'No Cast'
        ELSE 'Has Cast'
    END AS cast_status
FROM 
    RankedMovies rm
WHERE 
    rm.rn <= 5
ORDER BY 
    rm.production_year DESC, rm.cast_count DESC;
