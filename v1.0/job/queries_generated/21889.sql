WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS depth,
        CAST(mt.title AS VARCHAR(255)) AS hierarchy_path
    FROM 
        aka_title mt
    WHERE 
        mt.episode_of_id IS NULL
    
    UNION ALL
    
    SELECT 
        et.id AS movie_id,
        et.title,
        et.production_year,
        mh.depth + 1 AS depth,
        CAST(mh.hierarchy_path || ' -> ' || et.title AS VARCHAR(255)) AS hierarchy_path
    FROM 
        aka_title et
    JOIN 
        movie_hierarchy mh ON et.episode_of_id = mh.movie_id
)

SELECT 
    ak.name AS actor_name,
    mk.keyword AS movie_keyword,
    cmt.title AS movie_title,
    cmt.production_year,
    mh.depth AS hierarchy_depth,
    COALESCE(NULLIF(ak.name, ''), 'Unknown Actor') AS display_actor_name,
    COUNT(DISTINCT cmt.id) OVER (PARTITION BY ak.person_id) AS total_movies_actor,
    CASE 
        WHEN cmt.production_year < 2000 THEN 'Classic'
        WHEN cmt.production_year BETWEEN 2000 AND 2010 THEN 'Modern'
        ELSE 'Recent'
    END AS movie_age_category,
    ROW_NUMBER() OVER (PARTITION BY ak.person_id ORDER BY cmt.production_year DESC) AS rn
FROM 
    aka_name ak
JOIN 
    cast_info ci ON ak.person_id = ci.person_id
JOIN 
    aka_title cmt ON ci.movie_id = cmt.id
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = cmt.id
LEFT JOIN 
    movie_companies mc ON mc.movie_id = cmt.id
LEFT JOIN 
    movie_info mi ON mi.movie_id = cmt.id
LEFT JOIN 
    movie_hierarchy mh ON mh.movie_id = cmt.id
WHERE 
    ak.name IS NOT NULL
    AND ak.name <> ''
    AND ak.md5sum IS NOT NULL
    AND (mk.keyword IS NULL OR mk.keyword LIKE '%Action%')
ORDER BY 
    ak.name, cmt.production_year DESC
LIMIT 1000
OFFSET 0
WITH ORDINALITY
UNION ALL
SELECT 
    'Aggregate Stats' AS actor_name,
    NULL AS movie_keyword,
    NULL AS movie_title,
    NULL AS production_year,
    NULL AS hierarchy_depth,
    NULL AS display_actor_name,
    COUNT(DISTINCT ak.person_id) AS total_actors,
    NULL AS movie_age_category,
    NULL AS rn
FROM 
    aka_name ak
WHERE 
    ak.name IS NOT NULL
    AND ak.md5sum IS NOT NULL
HAVING 
    COUNT(DISTINCT ak.name) > 100
ORDER BY 
    movie_title, actor_name;
