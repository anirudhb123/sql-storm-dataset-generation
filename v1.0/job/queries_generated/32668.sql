WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        1 AS depth
    FROM 
        aka_title AS mt
    WHERE 
        mt.production_year = 2020

    UNION ALL

    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title,
        mh.depth + 1
    FROM 
        movie_link AS ml
    JOIN 
        aka_title AS at ON ml.linked_movie_id = at.id
    JOIN 
        movie_hierarchy AS mh ON ml.movie_id = mh.movie_id
)
SELECT 
    mh.title AS Parent_Title,
    STRING_AGG(DISTINCT ak.name, ', ') AS Cast_Names,
    COUNT(DISTINCT mk.keyword) AS Keyword_Count,
    AVG(SUBSTRING(mi.info FROM 'Rating: ([0-9.]+)')::numeric) AS Avg_Rating,
    CASE 
        WHEN COUNT(DISTINCT cc.kind) > 0 THEN 'Has Competing Studios'
        ELSE 'No Competing Studios'
    END AS Competing_Studios_Status
FROM 
    movie_hierarchy AS mh
LEFT JOIN 
    complete_cast AS cc ON mh.movie_id = cc.movie_id
LEFT JOIN 
    cast_info AS ci ON ci.movie_id = mh.movie_id
LEFT JOIN 
    aka_name AS ak ON ak.person_id = ci.person_id
LEFT JOIN 
    movie_keyword AS mk ON mk.movie_id = mh.movie_id
LEFT JOIN 
    movie_info AS mi ON mi.movie_id = mh.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Rating')
LEFT JOIN 
    movie_companies AS mc ON mc.movie_id = mh.movie_id
LEFT JOIN 
    company_name AS cn ON mc.company_id = cn.id
GROUP BY 
    mh.title
HAVING 
    COUNT(DISTINCT mk.keyword) > 5
ORDER BY 
    Avg_Rating DESC
LIMIT 10;

