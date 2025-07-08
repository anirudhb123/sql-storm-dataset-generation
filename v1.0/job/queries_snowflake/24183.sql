
WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        0 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year IS NOT NULL

    UNION ALL

    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        m.kind_id,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN movie_hierarchy mh ON ml.movie_id = mh.movie_id
    JOIN aka_title m ON ml.linked_movie_id = m.id
)
SELECT 
    ak.name AS actor_name,
    mt.title AS movie_title,
    mt.production_year,
    COUNT(*) OVER (PARTITION BY mt.id) AS actor_count,
    ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY ak.name) AS actor_rank,
    LISTAGG(DISTINCT k.keyword, ', ') AS keywords,
    COALESCE(cg.kind, 'Unknown') AS company_type
FROM 
    cast_info ci
JOIN 
    aka_name ak ON ci.person_id = ak.person_id
JOIN 
    aka_title mt ON ci.movie_id = mt.movie_id
LEFT JOIN 
    movie_companies mc ON mc.movie_id = mt.id
LEFT JOIN 
    company_type cg ON mc.company_type_id = cg.id
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = mt.id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_info mi ON mi.movie_id = mt.id
WHERE 
    mt.production_year BETWEEN 2000 AND 2023
    AND (ak.md5sum IS NOT NULL OR ak.name IS NOT NULL)
GROUP BY 
    ak.name, mt.id, mt.title, mt.production_year, cg.kind
HAVING 
    COUNT(DISTINCT ci.id) > 1
ORDER BY 
    mt.production_year DESC, actor_rank;
