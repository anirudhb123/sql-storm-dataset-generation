WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        mt.production_year,
        1 AS level,
        CAST(mt.title AS VARCHAR) AS path
    FROM 
        aka_title mt
    WHERE 
        mt.production_year IS NOT NULL

    UNION ALL

    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title AS movie_title,
        at.production_year,
        mh.level + 1,
        CAST(mh.path || ' -> ' || at.title AS VARCHAR)
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
)

SELECT 
    mh.movie_id,
    mh.movie_title,
    mh.production_year,
    ARRAY_AGG(DISTINCT ak.name) AS actors,
    COUNT(DISTINCT mi.info) AS info_count,
    AVG(CASE 
            WHEN LENGTH(ak.name) > 10 THEN 1 
            ELSE 0 
        END) OVER(PARTITION BY mh.movie_id) AS avg_long_actor_name,
    MAX(mh.level) AS max_level
FROM 
    MovieHierarchy mh
LEFT JOIN 
    complete_cast cc ON mh.movie_id = cc.movie_id
LEFT JOIN 
    aka_name ak ON cc.subject_id = ak.person_id
LEFT JOIN 
    movie_info mi ON mh.movie_id = mi.movie_id
WHERE 
    mh.production_year BETWEEN 2000 AND 2020
GROUP BY 
    mh.movie_id, 
    mh.movie_title, 
    mh.production_year
HAVING 
    COUNT(DISTINCT ak.name) > 5
ORDER BY 
    mh.production_year DESC, 
    max_level DESC;

-- Checking for NULL conditions and string expressions
SELECT 
    COALESCE(NULLIF(ak.name, ''), 'Unknown Actor') AS actor_name,
    mi.info,
    CASE 
        WHEN mi.info IS NULL THEN 'No Info Available'
        ELSE mi.info 
    END AS info_description
FROM 
    aka_name ak
LEFT JOIN 
    movie_info mi ON ak.person_id = mi.movie_id
WHERE 
    ak.name IS NOT NULL 
    AND ak.name <> ''
ORDER BY 
    LENGTH(ak.name) DESC 
LIMIT 10;

