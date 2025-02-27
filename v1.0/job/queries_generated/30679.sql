WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000

    UNION ALL

    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title,
        at.production_year,
        at.kind_id,
        mh.level + 1
    FROM 
        movie_link ml 
        JOIN aka_title at ON ml.linked_movie_id = at.id
        JOIN movie_hierarchy mh ON ml.movie_id = mh.movie_id
)

SELECT 
    a.name AS actor_name,
    COUNT(DISTINCT ch.movie_id) AS movies_count,
    string_agg(DISTINCT th.title, ', ' ORDER BY th.production_year) AS titles,
    AVG(CASE WHEN vi.info IS NOT NULL THEN length(vi.info) END) AS avg_info_length,
    MAX(ch.production_year) AS last_movie_year
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    complete_cast cc ON ci.movie_id = cc.movie_id
JOIN 
    movie_info vi ON ci.movie_id = vi.movie_id
JOIN 
    movie_hierarchy mh ON ci.movie_id = mh.movie_id
JOIN 
    aka_title th ON mh.movie_id = th.id
LEFT JOIN 
    movie_companies mc ON mh.movie_id = mc.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
WHERE 
    a.name IS NOT NULL
    AND (vi.info IS NOT NULL OR cn.name IS NULL)
GROUP BY 
    a.name
HAVING 
    COUNT(DISTINCT ch.movie_id) > 5
ORDER BY 
    movies_count DESC
LIMIT 10;
