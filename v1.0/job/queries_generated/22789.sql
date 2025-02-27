WITH RECURSIVE MovieHierarchy AS (
    -- Base case: Select the root movies
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        COALESCE(v._title, 'Unknown') AS variance_title,
        0 AS level
    FROM 
        aka_title mt
    LEFT JOIN 
        (SELECT movie_id, string_agg(DISTINCT title, ', ') AS _title
         FROM aka_title 
         WHERE production_year IS NOT NULL
         GROUP BY movie_id) AS v 
    ON mt.id = v.movie_id

    UNION ALL

    -- Recursive case: Join with linked movies
    SELECT 
        ml.linked_movie_id, 
        mt.title AS title,
        mt.production_year,
        COALESCE(v._title, 'Unknown') AS variance_title,
        level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title mt ON ml.movie_id = mt.id
    LEFT JOIN 
        (SELECT movie_id, string_agg(DISTINCT title, ', ') AS _title
         FROM aka_title 
         WHERE production_year IS NOT NULL
         GROUP BY movie_id) AS v 
    ON ml.linked_movie_id = v.movie_id
    JOIN MovieHierarchy mh ON ml.movie_id = mh.movie_id
)

-- Final selection with window functions and outer joins
SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    mh.variance_title,
    COALESCE(ki.keyword, 'No Keywords') AS keywords,
    COUNT(DISTINCT c.id) OVER (PARTITION BY mh.movie_id) AS cast_count,
    SUM(CASE WHEN ci.person_role_id IS NOT NULL THEN 1 ELSE 0 END) OVER (PARTITION BY mh.movie_id) AS visible_roles,
    ROW_NUMBER() OVER (PARTITION BY mh.production_year ORDER BY mh.level DESC) AS year_rank
FROM 
    MovieHierarchy mh
LEFT JOIN 
    movie_keyword mk ON mh.movie_id = mk.movie_id
LEFT JOIN 
    keyword ki ON mk.keyword_id = ki.id
LEFT JOIN 
    cast_info c ON mh.movie_id = c.movie_id
LEFT JOIN 
    complete_cast cc ON mh.movie_id = cc.movie_id
WHERE 
    mh.production_year > 2000
    AND coalesce(cc.status_id, -1) > 0
ORDER BY 
    mh.production_year DESC, 
    mh.title;

-- Consider using UNION with EXCEPT for additional complexity
WITH DistinctMovies AS (
    SELECT DISTINCT 
        movie_id, 
        title 
    FROM 
        aka_title
), 
ExcludedMovies AS (
    SELECT 
        movie_id 
    FROM 
        movie_info 
    WHERE 
        info_type_id IN (SELECT id FROM info_type WHERE info = 'Censored')
)

SELECT 
    dm.movie_id, 
    dm.title 
FROM 
    DistinctMovies dm 
EXCEPT 
SELECT 
    em.movie_id, 
    dm.title 
FROM 
    ExcludedMovies em 
JOIN 
    DistinctMovies dm ON dm.movie_id = em.movie_id;
