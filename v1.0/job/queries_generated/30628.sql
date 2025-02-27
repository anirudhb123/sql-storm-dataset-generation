WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        NULL::integer AS parent_movie_id,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id = 1 -- Assuming 1 is the ID for movies

    UNION ALL

    SELECT 
        ml.linked_movie_id,
        mt.title,
        mt.production_year,
        mh.movie_id,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title mt ON ml.linked_movie_id = mt.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
)

SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    mh.parent_movie_id,
    mh.level,
    COUNT(DISTINCT cc.id) AS cast_count,
    STRING_AGG(DISTINCT ak.name, ', ') AS cast_names,
    AVG(CASE WHEN mi.info_type_id = 1 THEN CAST(mi.info AS FLOAT) END) AS average_movie_rating -- Assuming info_type_id = 1 is for ratings
FROM 
    MovieHierarchy mh
LEFT JOIN 
    complete_cast cc ON mh.movie_id = cc.movie_id
LEFT JOIN 
    cast_info ci ON ci.movie_id = mh.movie_id
LEFT JOIN 
    aka_name ak ON ak.person_id = ci.person_id 
LEFT JOIN 
    movie_info mi ON mi.movie_id = mh.movie_id
GROUP BY 
    mh.movie_id, mh.title, mh.production_year, mh.parent_movie_id, mh.level
ORDER BY 
    mh.level, mh.production_year DESC
LIMIT 100;

-- Additional exploration of companies involved in these movies
WITH CompanyStats AS (
    SELECT 
        mt.id AS movie_id,
        COUNT(DISTINCT mc.company_id) AS company_count,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names
    FROM 
        aka_title mt
    LEFT JOIN 
        movie_companies mc ON mc.movie_id = mt.id
    LEFT JOIN 
        company_name cn ON cn.id = mc.company_id
    WHERE 
        mt.production_year >= 2000
    GROUP BY 
        mt.id
)

SELECT 
    mh.movie_id,
    mh.title,
    cs.company_count,
    cs.company_names
FROM 
    MovieHierarchy mh
LEFT JOIN 
    CompanyStats cs ON mh.movie_id = cs.movie_id
WHERE 
    cs.company_count IS NOT NULL
ORDER BY 
    cs.company_count DESC
LIMIT 50;
