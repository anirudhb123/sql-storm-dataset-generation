WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year IS NOT NULL
    UNION ALL
    SELECT 
        m.id,
        m.title,
        m.production_year,
        mh.level + 1
    FROM 
        aka_title m
    JOIN 
        movie_link ml ON m.id = ml.linked_movie_id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
),
GroupedMovies AS (
    SELECT 
        mh.title,
        mh.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY mh.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rn
    FROM 
        MovieHierarchy mh
    LEFT JOIN 
        cast_info ci ON mh.movie_id = ci.movie_id
    GROUP BY 
        mh.title, mh.production_year
)
SELECT 
    gm.title,
    gm.production_year,
    gm.cast_count,
    COALESCE((SELECT AVG(cast_count) FROM GroupedMovies WHERE production_year = gm.production_year AND rn <= 5), 0) AS avg_top_cast_count,
    CASE 
        WHEN gm.cast_count > COALESCE((SELECT AVG(cast_count) FROM GroupedMovies WHERE production_year = gm.production_year AND rn <= 5), 0) 
        THEN 'Above Average'
        ELSE 'Below Average'
    END AS performance_category
FROM 
    GroupedMovies gm
WHERE 
    gm.rn <= 10
ORDER BY 
    gm.production_year DESC, gm.cast_count DESC;

