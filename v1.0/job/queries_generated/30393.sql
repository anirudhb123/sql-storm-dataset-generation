WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        0 AS level
    FROM 
        aka_title m
    WHERE 
        m.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie') 

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
    mh.title AS linked_movie,
    mh.production_year,
    mh.level,
    a.name AS actor_name,
    COUNT(DISTINCT mc.company_id) AS production_companies,
    SUM(CASE WHEN mk.keyword IS NOT NULL THEN 1 ELSE 0 END) AS keyword_count,
    ROW_NUMBER() OVER (PARTITION BY mh.movie_id ORDER BY mh.level DESC) AS movie_rank
FROM 
    movie_hierarchy mh
LEFT JOIN 
    cast_info ci ON mh.movie_id = ci.movie_id
LEFT JOIN 
    aka_name a ON ci.person_id = a.person_id
LEFT JOIN 
    movie_companies mc ON mh.movie_id = mc.movie_id
LEFT JOIN 
    movie_keyword mk ON mh.movie_id = mk.movie_id
WHERE 
    mh.production_year >= 2000
GROUP BY 
    mh.movie_id, a.name, mh.level, mh.title, mh.production_year
HAVING 
    COUNT(DISTINCT ci.person_id) > 2
ORDER BY 
    mh.level, mh.production_year DESC;
