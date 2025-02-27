WITH RECURSIVE film_series AS (
    SELECT 
        a.id AS movie_id,
        a.title,
        a.production_year,
        1 AS series_level
    FROM 
        aka_title a
    WHERE 
        a.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL
    
    SELECT 
        a.id AS movie_id,
        a.title,
        a.production_year,
        fs.series_level + 1
    FROM 
        aka_title a
    JOIN 
        film_series fs ON a.episode_of_id = fs.movie_id
    WHERE 
        a.kind_id = (SELECT id FROM kind_type WHERE kind = 'episode')
)

SELECT 
    n.name AS actor_name,
    m.title AS movie_title,
    m.production_year,
    COUNT(CASE WHEN c.role_id IS NOT NULL THEN 1 END) AS cast_count,
    STRING_AGG(DISTINCT m_keyword.keyword, ', ') AS movie_keywords,
    AVG(CASE WHEN mi.info IS NOT NULL THEN LENGTH(mi.info) END) AS avg_info_length
FROM 
    name n
JOIN 
    cast_info c ON n.id = c.person_id
JOIN 
    film_series fs ON c.movie_id = fs.movie_id
JOIN 
    aka_title m ON fs.movie_id = m.id
LEFT JOIN 
    movie_keyword m_keyword ON m.id = m_keyword.movie_id
LEFT JOIN 
    movie_info mi ON m.id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'summary')
WHERE 
    n.gender = 'M' 
    AND (m.production_year BETWEEN 1990 AND 2000 OR m.title LIKE '%Action%')
GROUP BY 
    n.name, m.title, m.production_year
HAVING 
    COUNT(c.id) > 0
ORDER BY 
    m.production_year DESC, actor_name ASC;
