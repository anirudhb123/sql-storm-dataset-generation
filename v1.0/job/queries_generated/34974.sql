WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS level
    FROM 
        aka_title m
    WHERE 
        m.production_year >= 2000
    
    UNION ALL
    
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
    JOIN 
        aka_title m ON ml.linked_movie_id = m.id
)

SELECT 
    a.name AS actor_name,
    COUNT(DISTINCT c.movie_id) AS total_movies,
    AVG(m.production_year) AS average_production_year,
    STRING_AGG(DISTINCT CONCAT_WS(', ', k.keyword), '; ') AS keywords,
    FIRST_VALUE(m.title) OVER (PARTITION BY a.id ORDER BY c.nr_order) AS first_movie_title,
    SUM(CASE WHEN m.production_year IS NOT NULL THEN 1 ELSE 0 END) AS valid_movies,
    CASE 
        WHEN MAX(m.production_year) < 2020 THEN 'Older Movie'
        ELSE 'Recent Movie'
    END AS movie_category
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    aka_title m ON c.movie_id = m.movie_id
LEFT JOIN 
    movie_keyword mk ON m.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    (SELECT movie_id, COUNT(*) AS links_count 
     FROM movie_link 
     GROUP BY movie_id) ml ON ml.movie_id = m.id
WHERE 
    ml.links_count > 1
GROUP BY 
    a.id, a.name
HAVING 
    COUNT(DISTINCT c.movie_id) > 5
ORDER BY 
    total_movies DESC
LIMIT 10;


