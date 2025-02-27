WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id, 
        mt.title,
        mt.production_year,
        mt.kind_id,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie') -- Base case for movies

    UNION ALL

    SELECT 
        ml.linked_movie_id,
        m.title,
        m.production_year,
        m.kind_id,
        mh.level + 1 AS level
    FROM 
        movie_link ml
    JOIN 
        aka_title m ON ml.linked_movie_id = m.id
    JOIN 
        MovieHierarchy mh ON mh.movie_id = ml.movie_id
)

SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    mh.level,
    COUNT(DISTINCT ci.person_id) AS num_cast_members,
    STRING_AGG(DISTINCT ak.name, ', ') AS all_actor_names,
    MAX(CASE WHEN mt.info_type_id = (SELECT id FROM info_type WHERE info = 'rating') THEN mt.info END) AS movie_rating,
    COALESCE(SUM(CASE WHEN cct.kind IS NOT NULL THEN 1 ELSE 0 END), 0) AS num_companies,
    ROW_NUMBER() OVER (PARTITION BY mh.production_year ORDER BY mh.level DESC) AS year_rank
FROM 
    MovieHierarchy mh
LEFT JOIN 
    complete_cast cc ON mh.movie_id = cc.movie_id
LEFT JOIN 
    cast_info ci ON cc.subject_id = ci.person_id
LEFT JOIN 
    aka_name ak ON ci.person_id = ak.person_id
LEFT JOIN 
    movie_info mt ON mh.movie_id = mt.movie_id
LEFT JOIN 
    movie_companies mc ON mh.movie_id = mc.movie_id
LEFT JOIN 
    company_type cct ON mc.company_type_id = cct.id
WHERE 
    mh.production_year >= 2000 -- Only consider movies from the year 2000 onwards
GROUP BY 
    mh.movie_id, mh.title, mh.production_year, mh.level
HAVING 
    COUNT(DISTINCT ci.person_id) > 5 -- Only include movies with more than 5 cast members
ORDER BY 
    mh.production_year DESC, mh.level ASC;

