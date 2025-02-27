
WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        COALESCE(SUM(CASE WHEN mc.note IS NOT NULL THEN 1 ELSE 0 END), 0) AS company_count,
        ARRAY_AGG(DISTINCT c.name) AS cast_names
    FROM
        aka_title mt
    LEFT JOIN movie_companies mc ON mt.id = mc.movie_id
    LEFT JOIN company_name c ON mc.company_id = c.id
    WHERE 
        mt.production_year >= 2000 
    GROUP BY 
        mt.id, mt.title

    UNION ALL
    
    SELECT 
        mh.movie_id,
        mh.title,
        mh.company_count,
        mh.cast_names
    FROM 
        MovieHierarchy mh
    JOIN movie_link ml ON mh.movie_id = ml.movie_id
    JOIN aka_title at ON ml.linked_movie_id = at.id
),
LatestMovies AS (
    SELECT 
        at.id AS movie_id, 
        at.title, 
        at.production_year,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY at.id DESC) AS rn
    FROM 
        aka_title at
    WHERE 
        at.kind_id = (SELECT id FROM kind_type WHERE kind = 'feature')
)

SELECT 
    mh.movie_id,
    mh.title,
    mh.company_count,
    mh.cast_names,
    lm.production_year
FROM 
    MovieHierarchy mh
JOIN LatestMovies lm ON mh.movie_id = lm.movie_id
WHERE 
    lm.rn = 1
ORDER BY 
    lm.production_year DESC, mh.company_count DESC
FETCH FIRST 10 ROWS ONLY;
