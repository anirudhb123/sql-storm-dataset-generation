WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        0 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id,
        mt.title,
        mt.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title mt ON ml.movie_id = mt.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
)

SELECT 
    ak.name AS actor_name,
    m.title AS movie_title,
    mh.level AS hierarchy_level,
    COUNT(DISTINCT c.person_id) OVER (PARTITION BY m.id) AS actor_count,
    STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords,
    COALESCE(ci.kind, 'N/A') AS company_type,
    (SELECT COUNT(*) 
     FROM movie_info mi 
     WHERE mi.movie_id = m.id 
       AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'description')) AS description_info_count,
    SUM(CASE WHEN c.note IS NOT NULL THEN 1 ELSE 0 END) AS notes_with_content
FROM 
    aka_name ak
JOIN 
    cast_info c ON ak.person_id = c.person_id
JOIN 
    aka_title m ON c.movie_id = m.id
LEFT JOIN 
    movie_companies mc ON mc.movie_id = m.id
LEFT JOIN 
    company_type ci ON mc.company_type_id = ci.id
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = m.id
LEFT JOIN 
    keyword kw ON mk.keyword_id = kw.id
JOIN 
    movie_hierarchy mh ON mh.movie_id = m.id
WHERE 
    m.production_year > 2000
    AND (ak.name ILIKE '%John%' OR ak.name ILIKE '%Doe%')
GROUP BY 
    ak.name, m.title, mh.level, ci.kind
ORDER BY 
    mh.level, actor_count DESC, m.title;
