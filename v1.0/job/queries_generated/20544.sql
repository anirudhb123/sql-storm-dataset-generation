WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        '' AS parent_title,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year IS NOT NULL
      
    UNION ALL
      
    SELECT 
        ml.linked_movie_id,
        mt.title,
        mh.title AS parent_title,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title mt ON ml.movie_id = mt.movie_id
    JOIN 
        movie_hierarchy mh ON mh.movie_id = ml.movie_id
)

SELECT 
    ak.name AS actor_name,
    at.title AS movie_title,
    COALESCE(NULLIF(c.note, ''), 'No notes available') AS role_note,
    mh.parent_title,
    mh.level AS hierarchy_level,
    COUNT(DISTINCT mk.keyword) AS keyword_count,
    SUM(CASE WHEN cc.kind IS NULL THEN 1 ELSE 0 END) AS null_company_count
FROM 
    cast_info c
JOIN 
    aka_name ak ON c.person_id = ak.person_id
JOIN 
    aka_title at ON c.movie_id = at.id
LEFT JOIN 
    movie_keyword mk ON at.id = mk.movie_id
LEFT JOIN 
    movie_companies mc ON at.id = mc.movie_id
LEFT JOIN 
    company_type cc ON mc.company_type_id = cc.id
JOIN 
    movie_hierarchy mh ON at.id = mh.movie_id
WHERE 
    at.production_year >= 2000
    AND (c.note IS NULL OR c.note LIKE '%star%')
GROUP BY 
    ak.name, at.title, c.note, mh.parent_title, mh.level
HAVING 
    COUNT(DISTINCT ak.name) > 1
ORDER BY 
    mh.level DESC, keyword_count DESC;
