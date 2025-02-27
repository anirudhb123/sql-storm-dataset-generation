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
        ml.linked_movie_id,
        lt.title,
        lt.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title lt ON ml.linked_movie_id = lt.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
)
SELECT 
    person.name AS actor_name,
    mt.title AS movie_title,
    mt.production_year,
    COUNT(DISTINCT cc.id) AS total_cast_members,
    STRING_AGG(DISTINCT kc.keyword, ', ') AS keywords,
    AVG(CASE 
        WHEN mp.info IS NOT NULL THEN LENGTH(mp.info)
        ELSE NULL
    END) AS avg_info_length,
    ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY COUNT(DISTINCT cc.id) DESC) AS rank_cast_count
FROM 
    movie_hierarchy mh
JOIN 
    complete_cast cc ON mh.movie_id = cc.movie_id
JOIN 
    cast_info ci ON cc.subject_id = ci.person_id
JOIN 
    name person ON ci.person_id = person.id
JOIN 
    movie_keyword mk ON mk.movie_id = mh.movie_id
JOIN 
    keyword kc ON mk.keyword_id = kc.id
LEFT JOIN 
    movie_info mp ON mh.movie_id = mp.movie_id AND mp.info_type_id = (SELECT id FROM info_type WHERE info = 'Awards')
WHERE 
    mh.level <= 2 -- Limiting to the current movie and its direct links
GROUP BY 
    actor_name, mt.title, mt.production_year
HAVING 
    COUNT(DISTINCT cc.id) > 5 -- Only movies with more than 5 cast members
ORDER BY 
    production_year DESC, total_cast_members DESC;
