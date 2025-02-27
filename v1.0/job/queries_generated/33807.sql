WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.movie_id,
        m.title,
        m.production_year,
        1 AS level
    FROM 
        aka_title m
    WHERE 
        m.production_year BETWEEN 2000 AND 2020

    UNION ALL
    
    SELECT 
        m.movie_id,
        m.title,
        m.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        movie_hierarchy mh ON ml.linked_movie_id = mh.movie_id
    JOIN 
        aka_title m ON ml.movie_id = m.movie_id
    WHERE 
        mh.level < 3
)

SELECT 
    h.title AS movie_title,
    h.production_year,
    COALESCE(STRING_AGG(DISTINCT ak.name, ', '), 'No cast') AS cast_names,
    COUNT(DISTINCT kc.keyword) AS keyword_count,
    COUNT(DISTINCT mc.company_id) AS company_count,
    AVG(CASE 
        WHEN p.info IS NOT NULL THEN LENGTH(p.info) 
        ELSE 0 
    END) AS avg_person_info_length
FROM 
    movie_hierarchy h
LEFT JOIN 
    cast_info c ON h.movie_id = c.movie_id
LEFT JOIN 
    aka_name ak ON c.person_id = ak.person_id
LEFT JOIN 
    movie_keyword mk ON h.movie_id = mk.movie_id
LEFT JOIN 
    keyword kc ON mk.keyword_id = kc.id
LEFT JOIN 
    movie_companies mc ON h.movie_id = mc.movie_id
LEFT JOIN 
    person_info p ON c.person_id = p.person_id
GROUP BY 
    h.movie_id, h.title, h.production_year
HAVING 
    COUNT(DISTINCT c.id) > 5
ORDER BY 
    h.production_year DESC, movie_title ASC;
