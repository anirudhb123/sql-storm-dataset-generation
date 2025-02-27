WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        1 AS depth
    FROM 
        aka_title mt
    WHERE 
        mt.production_year > 2000

    UNION ALL

    SELECT 
        m.id,
        m.title,
        m.production_year,
        m.kind_id,
        mh.depth + 1
    FROM 
        aka_title m
    JOIN 
        movie_link ml ON m.id = ml.linked_movie_id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
)

SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    AVG(mi.info) AS avg_runtime,
    COUNT(*) FILTER (WHERE mc.note IS NOT NULL) AS total_companies,
    MAX(mkh.keyword) AS top_keyword,
    ROW_NUMBER() OVER (PARTITION BY a.name ORDER BY AVG(mi.info) DESC) AS rank
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    movie_hierarchy mh ON ci.movie_id = mh.movie_id
LEFT JOIN 
    movie_info mi ON mh.movie_id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'runtime')
LEFT JOIN 
    movie_companies mc ON mh.movie_id = mc.movie_id
LEFT JOIN 
    movie_keyword mk ON mh.movie_id = mk.movie_id
LEFT JOIN 
    keyword mkh ON mk.keyword_id = mkh.id
JOIN 
    title t ON mh.movie_id = t.id
WHERE 
    a.name IS NOT NULL 
GROUP BY 
    a.name, t.title
HAVING 
    AVG(mi.info) IS NOT NULL 
ORDER BY 
    rank, actor_name;
