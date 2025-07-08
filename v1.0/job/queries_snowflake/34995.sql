
WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        0 AS level,
        CAST(mt.title AS VARCHAR(255)) AS path
    FROM 
        aka_title mt
    WHERE 
        mt.episode_of_id IS NULL  

    UNION ALL

    SELECT 
        ep.id AS movie_id,
        ep.title,
        ep.production_year,
        mh.level + 1,
        CAST(mh.path || ' > ' || ep.title AS VARCHAR(255)) AS path
    FROM 
        aka_title ep
    JOIN 
        MovieHierarchy mh ON ep.episode_of_id = mh.movie_id
)

SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    mh.level,
    mh.path,
    COUNT(DISTINCT mc.company_id) AS company_count,
    SUM(CASE WHEN ci.role_id IS NOT NULL THEN 1 ELSE 0 END) AS cast_count,
    LISTAGG(DISTINCT ak.name, ', ') WITHIN GROUP (ORDER BY ak.name) AS aka_names,
    ARRAY_AGG(DISTINCT mv.info) AS movie_info
FROM 
    MovieHierarchy mh
LEFT JOIN 
    movie_companies mc ON mh.movie_id = mc.movie_id
LEFT JOIN 
    complete_cast cc ON mh.movie_id = cc.movie_id
LEFT JOIN 
    cast_info ci ON cc.subject_id = ci.person_id
LEFT JOIN 
    aka_name ak ON ci.person_id = ak.person_id
LEFT JOIN 
    movie_info mv ON mh.movie_id = mv.movie_id
WHERE 
    mh.production_year >= 2000  
GROUP BY 
    mh.movie_id, mh.title, mh.production_year, mh.level, mh.path
ORDER BY 
    mh.level, mh.production_year DESC;
