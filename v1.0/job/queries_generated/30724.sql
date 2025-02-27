WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS level
    FROM 
        aka_title m
    WHERE 
        m.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL
    
    SELECT 
        m.id,
        m.title,
        m.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        movie_hierarchy mh ON ml.linked_movie_id = mh.movie_id
    JOIN 
        aka_title m ON ml.movie_id = m.id
    WHERE 
        m.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
)
SELECT 
    h.movie_id,
    h.title,
    h.production_year,
    COUNT(DISTINCT c.person_id) AS total_actors,
    STRING_AGG(DISTINCT a.name, ', ') AS actor_names,
    MAX(i.info) AS movie_info,
    CASE 
        WHEN COUNT(DISTINCT c.person_id) = 0 THEN 'No actors found'
        ELSE 'Found actors'
    END AS actor_status,
    ROW_NUMBER() OVER (PARTITION BY h.production_year ORDER BY h.production_year DESC) AS year_rank
FROM 
    movie_hierarchy h
LEFT JOIN 
    complete_cast cc ON h.movie_id = cc.movie_id
LEFT JOIN 
    cast_info c ON cc.subject_id = c.movie_id
LEFT JOIN 
    aka_name a ON c.person_id = a.person_id
LEFT JOIN 
    movie_info i ON h.movie_id = i.movie_id AND i.info_type_id = (SELECT id FROM info_type WHERE info = 'Synopsis')
GROUP BY 
    h.movie_id, h.title, h.production_year
HAVING 
    h.production_year >= 2000
ORDER BY 
    h.production_year DESC, total_actors DESC;
