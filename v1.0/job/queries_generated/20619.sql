WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        0 AS level
    FROM 
        aka_title mt 
    WHERE 
        mt.kind_id IN (SELECT id FROM kind_type WHERE kind LIKE '%Feature%')

    UNION ALL

    SELECT 
        ml.linked_movie_id,
        m.title,
        m.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
    JOIN 
        aka_title m ON ml.linked_movie_id = m.id
    WHERE 
        mh.level < 3
)

SELECT 
    ak.name AS actor_name,
    mv.title AS movie_title,
    mv.production_year,
    COUNT(DISTINCT mc.company_id) AS company_count,
    AVG(CASE WHEN k.keyword IS NOT NULL THEN 1 ELSE 0 END) AS avg_contains_keyword,
    SUM(COALESCE(ca.nr_order, 0)) AS total_cast_order,
    ROW_NUMBER() OVER (PARTITION BY mv.title ORDER BY mv.production_year DESC) AS rank_within_title
FROM 
    movie_hierarchy mv
LEFT JOIN 
    cast_info ca ON mv.movie_id = ca.movie_id
LEFT JOIN 
    aka_name ak ON ak.person_id = ca.person_id
LEFT JOIN 
    movie_companies mc ON mv.movie_id = mc.movie_id
LEFT JOIN 
    movie_keyword mk ON mv.movie_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    mv.production_year IS NOT NULL 
    AND ak.name IS NOT NULL
    AND (k.keyword LIKE '%%' OR k.keyword IS NULL) -- bizarre logic to include NULLs or any keyword
GROUP BY 
    ak.name, mv.title, mv.production_year
HAVING 
    COUNT(DISTINCT mc.company_id) > 2 -- companies producing the movie
ORDER BY 
    mv.production_year, actor_name;
