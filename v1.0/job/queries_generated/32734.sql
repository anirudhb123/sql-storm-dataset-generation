WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        COALESCE(mh.production_year, mt.production_year) AS production_year,
        mh.linked_movie_id AS linked_movie_id,
        0 AS depth
    FROM 
        aka_title mt
    LEFT JOIN 
        movie_link ml ON mt.id = ml.movie_id
    LEFT JOIN 
        aka_title mh ON ml.linked_movie_id = mh.id
    WHERE 
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL
    
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        ml.linked_movie_id,
        depth + 1
    FROM 
        movie_hierarchy mh
    JOIN 
        movie_link ml ON mh.linked_movie_id = ml.movie_id
)

SELECT 
    a.name AS actor_name,
    mt.title AS movie_title,
    mh.production_year,
    COUNT(DISTINCT mc.company_id) AS company_count,
    SUM(CASE WHEN mi.info_type_id = (SELECT id FROM info_type WHERE info = 'budget') THEN CAST(mi.info AS BIGINT) ELSE 0 END) AS total_budget,
    ROW_NUMBER() OVER (PARTITION BY a.name ORDER BY mh.depth) AS movie_rank
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    movie_hierarchy mh ON ci.movie_id = mh.movie_id
JOIN 
    movie_companies mc ON mh.movie_id = mc.movie_id
LEFT JOIN 
    movie_info mi ON mh.movie_id = mi.movie_id
LEFT JOIN 
    aka_title mt ON mh.movie_id = mt.id
WHERE 
    a.name IS NOT NULL
    AND mh.production_year > 2000
    AND EXISTS (
        SELECT 1
        FROM movie_keyword mk
        WHERE mk.movie_id = mh.movie_id AND mk.keyword_id IN (
            SELECT id FROM keyword WHERE keyword IN ('action', 'drama')
        )
    )
GROUP BY 
    a.name, mt.title, mh.production_year
HAVING 
    COUNT(DISTINCT mc.company_id) > 1
ORDER BY 
    total_budget DESC, actor_name, movie_rank;
