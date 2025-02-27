WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mcl.linked_movie_id,
        1 AS level
    FROM 
        aka_title mt
    LEFT JOIN 
        movie_link mcl ON mt.id = mcl.movie_id
    WHERE 
        mt.production_year IS NOT NULL

    UNION ALL

    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mcl.linked_movie_id,
        mh.level + 1
    FROM 
        movie_hierarchy mh
    JOIN 
        movie_link mcl ON mh.linked_movie_id = mcl.movie_id
    JOIN 
        aka_title mt ON mcl.linked_movie_id = mt.id
)
SELECT 
    aa.name,
    COUNT(DISTINCT a.title) AS total_movies,
    AVG(COALESCE(mh.level, 0)) AS avg_link_depth,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
FROM 
    aka_name aa
JOIN 
    cast_info ci ON aa.person_id = ci.person_id
JOIN 
    aka_title a ON ci.movie_id = a.id
LEFT JOIN 
    movie_keyword mk ON a.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_hierarchy mh ON mh.movie_id = a.id
WHERE 
    a.production_year >= 2000
    AND aa.name IS NOT NULL
    AND (k.keyword IS NULL OR k.keyword NOT LIKE '%unrelated%')
GROUP BY 
    aa.name
ORDER BY 
    total_movies DESC, 
    avg_link_depth ASC
LIMIT 10;
