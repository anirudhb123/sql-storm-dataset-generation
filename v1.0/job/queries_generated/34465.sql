WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000

    UNION ALL

    SELECT 
        ml.linked_movie_id,
        at.title,
        at.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
)
SELECT 
    mk.keyword,
    COUNT(DISTINCT mc.movie_id) AS movie_count,
    AVG(mh.level) AS avg_hierarchy_level
FROM 
    movie_keyword mk
JOIN 
    movie_companies mc ON mk.movie_id = mc.movie_id
LEFT JOIN 
    movie_hierarchy mh ON mc.movie_id = mh.movie_id
JOIN 
    aka_title at ON mc.movie_id = at.id
WHERE 
    mk.keyword IS NOT NULL
    AND at.production_year >= 2000
GROUP BY 
    mk.keyword
ORDER BY 
    movie_count DESC
LIMIT 10;

-- Adding a complex filter expression through a correlated subquery
SELECT 
    ak.name,
    COUNT(DISTINCT ci.movie_id) AS movies_with_role,
    SUM(CASE WHEN (SELECT COUNT(*) FROM complete_cast cc WHERE cc.movie_id = ci.movie_id AND cc.subject_id = ak.id) > 0 
             THEN 1 ELSE 0 END) AS movies_in_complete_cast
FROM 
    aka_name ak
JOIN 
    cast_info ci ON ak.person_id = ci.person_id
WHERE 
    ak.name IS NOT NULL
    AND ak.name NOT IN (SELECT name FROM aka_name WHERE name LIKE '%unknown%')
GROUP BY 
    ak.name
HAVING 
    COUNT(DISTINCT ci.movie_id) > 5
ORDER BY 
    movies_with_role DESC;
