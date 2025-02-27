WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title, 
        m.production_year,
        1 AS level
    FROM 
        aka_title m
    WHERE 
        m.kind_id = (SELECT id FROM kind_type WHERE kind = 'feature')

    UNION ALL

    SELECT 
        cm.linked_movie_id AS movie_id,
        mt.title, 
        mt.production_year,
        mh.level + 1
    FROM 
        movie_link cm
    JOIN 
        movie_hierarchy mh ON cm.movie_id = mh.movie_id
    JOIN 
        aka_title mt ON cm.linked_movie_id = mt.id
    WHERE 
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'feature')
)

SELECT 
    a.id AS aka_id,
    a.name AS actor_name,
    m.movie_id,
    m.title AS movie_title,
    m.production_year,
    COUNT(distinct ki.keyword) AS total_keywords,
    ROW_NUMBER() OVER (PARTITION BY a.id ORDER BY m.production_year DESC) AS row_num
FROM 
    aka_name a
LEFT JOIN 
    cast_info c ON a.person_id = c.person_id
LEFT JOIN 
    complete_cast cc ON c.movie_id = cc.movie_id
LEFT JOIN 
    movie_info mi ON cc.movie_id = mi.movie_id
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = mi.movie_id
LEFT JOIN 
    keyword ki ON mk.keyword_id = ki.id
JOIN 
    movie_hierarchy m ON c.movie_id = m.movie_id
WHERE 
    (m.production_year >= 2000 OR m.production_year IS NULL)
    AND a.name IS NOT NULL 
GROUP BY 
    a.id, a.name, m.movie_id, m.title, m.production_year
HAVING 
    COUNT(m.movie_id) > 1
ORDER BY 
    actor_name, m.production_year DESC;
