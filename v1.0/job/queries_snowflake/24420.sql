
WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS depth
    FROM 
        aka_title mt
    WHERE 
        mt.production_year IS NOT NULL

    UNION ALL

    SELECT 
        m.linked_movie_id AS movie_id,
        m2.title,
        m2.production_year,
        mh.depth + 1
    FROM 
        movie_link m
    JOIN 
        aka_title m2 ON m.linked_movie_id = m2.id
    JOIN 
        movie_hierarchy mh ON m.movie_id = mh.movie_id
    WHERE 
        mh.depth < 3
)

SELECT 
    ak.name AS actor_name,
    mt.title AS movie_title,
    mt.production_year,
    COUNT(DISTINCT mc.company_id) AS num_companies,
    LISTAGG(DISTINCT cn.name, ', ') WITHIN GROUP (ORDER BY cn.name) AS company_names,
    ROW_NUMBER() OVER (PARTITION BY ak.name ORDER BY mt.production_year) AS actor_movie_order,
    SUM(CASE WHEN mt.production_year < 2000 THEN 1 ELSE 0 END) OVER (PARTITION BY ak.name) AS pre_2000_movies
FROM 
    aka_name ak
JOIN 
    cast_info ci ON ak.person_id = ci.person_id
JOIN 
    movie_companies mc ON ci.movie_id = mc.movie_id
JOIN 
    aka_title mt ON mc.movie_id = mt.id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
LEFT JOIN 
    movie_keyword mk ON mt.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    ak.name IS NOT NULL
    AND mt.production_year >= 1980
    AND (mt.kind_id IN (SELECT id FROM kind_type WHERE kind LIKE '%Movie%') OR mt.kind_id IS NULL)
    AND (k.keyword IS NULL OR k.keyword LIKE '%Action%')
GROUP BY 
    ak.name,
    mt.id,
    mt.title,
    mt.production_year
HAVING 
    COUNT(DISTINCT k.id) > 2
ORDER BY 
    actor_movie_order,
    mt.production_year DESC;
