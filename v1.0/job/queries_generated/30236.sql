WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS level
    FROM 
        aka_title m
    WHERE 
        m.id IN (SELECT DISTINCT movie_id FROM movie_companies)
    
    UNION ALL
    
    SELECT 
        link.linked_movie_id AS movie_id,
        m.title,
        m.production_year,
        h.level + 1
    FROM 
        movie_link link
    JOIN 
        aka_title m ON link.linked_movie_id = m.id
    JOIN 
        movie_hierarchy h ON link.movie_id = h.movie_id
)
SELECT 
    m.title AS movie_title,
    m.production_year,
    COALESCE(p.first_name, 'Unknown') AS actor_first_name,
    COALESCE(p.last_name, 'Unknown') AS actor_last_name,
    COUNT(DISTINCT c.id) AS total_cast,
    AVG(CASE WHEN c.nr_order IS NOT NULL THEN c.nr_order ELSE 0 END) AS avg_cast_order,
    STRING_AGG(DISTINCT k.keyword, ', ') AS associated_keywords,
    MAX(CASE WHEN mi.info_type_id = 1 THEN mi.info END) AS movie_summary
FROM 
    movie_hierarchy m
LEFT JOIN 
    cast_info c ON m.movie_id = c.movie_id
LEFT JOIN 
    aka_name p ON c.person_id = p.person_id
LEFT JOIN 
    movie_keyword mk ON m.movie_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_info mi ON m.movie_id = mi.movie_id
GROUP BY 
    m.movie_id, m.title, m.production_year, p.first_name, p.last_name
HAVING 
    COUNT(DISTINCT c.id) > 2
ORDER BY 
    m.production_year DESC, total_cast DESC;
