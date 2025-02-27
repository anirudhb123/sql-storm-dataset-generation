WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level,
        mt.episode_of_id
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id AS movie_id,
        mt.title,
        mt.production_year,
        mh.level + 1,
        mt.episode_of_id
    FROM 
        movie_link ml
    JOIN 
        aka_title mt ON ml.movie_id = mt.id
    JOIN 
        movie_hierarchy mh ON mh.movie_id = ml.movie_id
)
SELECT 
    mh.title AS Movie_Title,
    mh.production_year AS Production_Year,
    mh.level AS Hierarchy_Level,
    coalesce(cn.name, 'Unknown') AS Company_Name,
    ARRAY_AGG(DISTINCT tmp.name) AS Cast,
    COUNT(DISTINCT kw.id) AS Keyword_Count,
    SUM(CASE WHEN ci.note IS NOT NULL THEN 1 ELSE 0 END) AS Cast_Note_Count
FROM 
    movie_hierarchy mh
LEFT JOIN 
    movie_companies mc ON mh.movie_id = mc.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
LEFT JOIN 
    cast_info ci ON mh.movie_id = ci.movie_id
LEFT JOIN 
    aka_name tmp ON ci.person_id = tmp.person_id
LEFT JOIN 
    movie_keyword mk ON mh.movie_id = mk.movie_id
LEFT JOIN 
    keyword kw ON mk.keyword_id = kw.id
WHERE 
    mh.production_year < 2023
GROUP BY 
    mh.title, mh.production_year, mh.level, cn.name
ORDER BY 
    mh.production_year DESC, mh.title;
