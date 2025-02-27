WITH RECURSIVE movie_hierarchy AS (
    SELECT
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS depth
    FROM
        aka_title mt
    WHERE
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
        
    UNION ALL
    
    SELECT
        ml.linked_movie_id,
        mt.title,
        mt.production_year,
        mh.depth + 1
    FROM
        movie_link ml
    JOIN
        aka_title mt ON ml.linked_movie_id = mt.id
    JOIN
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
)

SELECT 
    ak.name AS actor_name,
    mt.title AS movie_title,
    mt.production_year,
    COUNT(DISTINCT mc.company_id) AS company_count,
    AVG(CASE WHEN pi.info IS NOT NULL THEN 1 ELSE 0 END) AS has_person_info_rate,
    ROW_NUMBER() OVER (PARTITION BY ak.person_id ORDER BY mt.production_year DESC) AS movie_rank,
    STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords
FROM
    aka_name ak
JOIN 
    cast_info ci ON ak.person_id = ci.person_id
JOIN 
    movie_hierarchy mh ON ci.movie_id = mh.movie_id
JOIN 
    title mt ON mh.movie_id = mt.id
LEFT JOIN 
    movie_companies mc ON mt.id = mc.movie_id
LEFT JOIN 
    movie_keyword mk ON mt.id = mk.movie_id
LEFT JOIN 
    keyword kw ON mk.keyword_id = kw.id
LEFT JOIN 
    person_info pi ON ak.person_id = pi.person_id
WHERE 
    ak.name IS NOT NULL
    AND (mt.production_year > 2000 OR mt.production_year IS NULL)
GROUP BY 
    ak.name, mt.title, mt.production_year
HAVING 
    COUNT(DISTINCT mc.company_id) > 1
ORDER BY 
    mt.production_year DESC,
    ak.name;
