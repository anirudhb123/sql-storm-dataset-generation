WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS depth
    FROM 
        aka_title m
    WHERE 
        m.production_year IS NOT NULL
    UNION ALL
    SELECT 
        m.id,
        m.title,
        m.production_year,
        mh.depth + 1
    FROM 
        aka_title m
    JOIN 
        movie_link ml ON m.id = ml.linked_movie_id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
    WHERE 
        mh.depth < 5 -- Limit depth to 5 for recursive search
)
SELECT 
    m.title AS movie_title,
    COALESCE(c.name, 'Unknown Role') AS character_name,
    a.name AS actor_name,
    COUNT(DISTINCT k.keyword) AS keyword_count,
    SUM(CASE WHEN mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Box Office') THEN CAST(mi.info AS numeric) ELSE 0 END) AS total_box_office,
    RANK() OVER (PARTITION BY m.production_year ORDER BY COUNT(DISTINCT k.keyword) DESC) AS keyword_rank
FROM 
    movie_hierarchy mh
JOIN 
    complete_cast cc ON mh.movie_id = cc.movie_id
JOIN 
    cast_info ci ON cc.subject_id = ci.person_id
JOIN 
    aka_name a ON ci.person_id = a.person_id
LEFT JOIN 
    char_name c ON ci.role_id = c.id
LEFT JOIN 
    movie_keyword mk ON mh.movie_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_info mi ON mh.movie_id = mi.movie_id
WHERE 
    mh.production_year BETWEEN 2000 AND 2022
GROUP BY 
    m.title, c.name, a.name, mh.production_year
HAVING 
    COUNT(DISTINCT ci.person_id) > 1 -- Only consider movies with more than 1 actor
ORDER BY 
    total_box_office DESC NULLS LAST, keyword_count DESC;
