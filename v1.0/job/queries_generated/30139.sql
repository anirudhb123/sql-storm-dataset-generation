WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.title,
        mt.production_year,
        ml.linked_movie_id,
        1 AS level
    FROM 
        title mt
    LEFT JOIN 
        movie_link ml ON mt.id = ml.movie_id
    WHERE 
        mt.production_year >= 2000 -- Starting with movies from the year 2000
    UNION ALL
    SELECT 
        mt.title,
        mt.production_year,
        ml.linked_movie_id,
        mh.level + 1
    FROM 
        movie_hierarchy mh
    JOIN 
        movie_link ml ON mh.linked_movie_id = ml.movie_id
    JOIN 
        title mt ON ml.linked_movie_id = mt.id
)
SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    COUNT(DISTINCT kw.keyword) AS keyword_count,
    MAX(mh.level) AS max_link_level,
    STRING_AGG(DISTINCT ckt.kind, ', ') AS company_kinds,
    COALESCE(SUM(CASE WHEN pi.info_type_id = 1 THEN 1 ELSE 0 END), 0) AS personal_info_count
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
LEFT JOIN 
    movie_keyword mw ON t.id = mw.movie_id
LEFT JOIN 
    keyword kw ON mw.keyword_id = kw.id
LEFT JOIN 
    movie_companies mc ON t.id = mc.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
LEFT JOIN 
    company_type ckt ON mc.company_type_id = ckt.id
LEFT JOIN 
    person_info pi ON a.person_id = pi.person_id
LEFT JOIN 
    movie_hierarchy mh ON t.id = mh.linked_movie_id
GROUP BY 
    a.id, t.id
ORDER BY 
    max_link_level DESC, keyword_count DESC
LIMIT 50;
