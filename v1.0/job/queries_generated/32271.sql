WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        1 AS level
    FROM 
        aka_title m
    WHERE 
        m.production_year >= 2000

    UNION ALL

    SELECT 
        ml.linked_movie_id,
        m.title,
        m.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title m ON ml.linked_movie_id = m.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
)
SELECT 
    mh.movie_title,
    mh.production_year,
    COALESCE(STRING_AGG(DISTINCT a.name, ', '), 'No Actors') AS actor_names,
    COUNT(DISTINCT kc.keyword) AS keyword_count,
    SUM(CASE WHEN cf.kind IS NOT NULL THEN 1 ELSE 0 END) AS company_count,
    MAX(mh.level) AS max_link_depth
FROM 
    movie_hierarchy mh
LEFT JOIN 
    complete_cast cc ON mh.movie_id = cc.movie_id
LEFT JOIN 
    aka_name a ON cc.subject_id = a.person_id
LEFT JOIN 
    movie_keyword mk ON mh.movie_id = mk.movie_id
LEFT JOIN 
    keyword kc ON mk.keyword_id = kc.id
LEFT JOIN 
    movie_companies mc ON mh.movie_id = mc.movie_id
LEFT JOIN 
    company_type cf ON mc.company_type_id = cf.id
WHERE 
    mh.production_year IS NOT NULL
GROUP BY 
    mh.movie_title,
    mh.production_year
ORDER BY 
    max_link_depth DESC, 
    mh.production_year DESC
LIMIT 100;
