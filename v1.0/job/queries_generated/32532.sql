WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level,
        NULL::integer AS parent_id
    FROM 
        aka_title mt
    WHERE 
        mt.episode_of_id IS NULL

    UNION ALL

    SELECT 
        et.id AS movie_id,
        et.title,
        et.production_year,
        mh.level + 1,
        mh.movie_id AS parent_id
    FROM 
        aka_title et
    JOIN 
        movie_hierarchy mh ON et.episode_of_id = mh.movie_id
)
SELECT 
    ak.name AS actor_name,
    COALESCE(mh.title, 'N/A') AS movie_title,
    mh.production_year,
    COUNT(DISTINCT mc.company_id) AS company_count,
    SUM(CASE WHEN mw.keyword IS NOT NULL THEN 1 ELSE 0 END) AS keyword_count,
    ARRAY_AGG(DISTINCT mw.keyword) AS keywords,
    STRING_AGG(DISTINCT cn.name, ', ') FILTER (WHERE cn.name IS NOT NULL) AS company_names
FROM 
    aka_name ak
JOIN 
    cast_info ci ON ak.person_id = ci.person_id
LEFT JOIN 
    movie_hierarchy mh ON ci.movie_id = mh.movie_id
LEFT JOIN 
    movie_companies mc ON mh.movie_id = mc.movie_id
LEFT JOIN 
    movie_keyword mw ON mh.movie_id = mw.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
WHERE 
    ak.name IS NOT NULL
GROUP BY 
    ak.name, mh.title, mh.production_year
ORDER BY 
    COUNT(DISTINCT mc.company_id) DESC,
    ak.name;
