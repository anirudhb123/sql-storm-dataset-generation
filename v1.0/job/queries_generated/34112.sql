WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL
    
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        mh.level + 1
    FROM 
        aka_title m
        JOIN movie_link ml ON m.id = ml.linked_movie_id
        JOIN MovieHierarchy mh ON ml.movie_id = mh.movie_id
)
SELECT 
    ak.name AS actor_name,
    ak.md5sum AS actor_md5,
    mt.title AS movie_title,
    mt.production_year AS movie_year,
    COUNT(DISTINCT mh.movie_id) AS related_movies,
    AVG(mk.keywords_count) AS average_movie_keywords,
    STRING_AGG(DISTINCT mk.keyword, ', ') AS all_keywords,
    COALESCE(cn.name, 'Unknown Company') AS company_name,
    ROW_NUMBER() OVER (PARTITION BY ak.person_id ORDER BY mt.production_year DESC) AS actor_rank
FROM 
    aka_name ak
JOIN 
    cast_info ci ON ak.person_id = ci.person_id
JOIN 
    aka_title mt ON ci.movie_id = mt.id
LEFT JOIN 
    movie_companies mc ON mt.id = mc.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
LEFT JOIN (
    SELECT 
        mk.movie_id, 
        COUNT(mk.keyword_id) AS keywords_count
    FROM 
        movie_keyword mk
    GROUP BY 
        mk.movie_id
) mk ON mk.movie_id = mt.id
JOIN 
    MovieHierarchy mh ON mh.movie_id = mt.id
WHERE 
    ak.name IS NOT NULL
    AND (mt.production_year IS NOT NULL AND mt.production_year >= 2000)
    AND (cn.country_code IS NULL OR cn.country_code IN ('USA', 'GB'))
GROUP BY 
    ak.person_id, ak.name, ak.md5sum, mt.id, mt.title, mt.production_year, cn.name
HAVING 
    COUNT(DISTINCT mt.id) > 1
ORDER BY 
    actor_rank, movie_year DESC;

