
WITH RECURSIVE movie_hierarchy AS (
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
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN movie_hierarchy mh ON ml.movie_id = mh.movie_id
    JOIN aka_title mt ON ml.linked_movie_id = mt.id
    WHERE 
        mh.level < 3 
)

SELECT 
    a.name AS actor_name,
    COUNT(DISTINCT ci.movie_id) AS total_movies,
    AVG(CASE WHEN mc.status_id IS NOT NULL THEN 1 ELSE 0 END) AS avg_have_complete_cast,
    STRING_AGG(DISTINCT k.keyword, ', ') AS associated_keywords,
    mh.level AS movie_level,
    MIN(mh.production_year) AS first_movie_year,
    MAX(mh.production_year) AS latest_movie_year
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    movie_hierarchy mh ON ci.movie_id = mh.movie_id
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = mh.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    complete_cast mc ON mc.movie_id = mh.movie_id AND mc.subject_id = a.id
WHERE 
    a.name IS NOT NULL
GROUP BY 
    a.name, mh.level
ORDER BY 
    total_movies DESC, first_movie_year ASC;
