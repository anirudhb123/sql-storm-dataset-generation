WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS level,
        ARRAY[m.title] AS path
    FROM 
        aka_title m
    WHERE 
        m.production_year >= 2000
    UNION ALL
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        mh.level + 1,
        path || m.title
    FROM 
        aka_title m
    JOIN 
        movie_link ml ON m.id = ml.linked_movie_id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
)
SELECT 
    m.title AS Movie,
    m.production_year AS Year,
    COALESCE(aka.name, 'Unknown') AS Actor,
    string_agg(DISTINCT k.keyword, ', ') AS Keywords,
    COUNT(DISTINCT c.id) AS Cast_Count,
    COUNT(DISTINCT ml.linked_movie_id) AS Linked_Movies,
    AVG(m.production_year) OVER (PARTITION BY a.name) AS Avg_Year_Of_Actor_Movies
FROM 
    aka_title m
LEFT JOIN 
    cast_info c ON m.id = c.movie_id
LEFT JOIN 
    aka_name aka ON c.person_id = aka.person_id
LEFT JOIN 
    movie_keyword mk ON m.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_link ml ON m.id = ml.movie_id
LEFT JOIN 
    MovieHierarchy mh ON m.id = mh.movie_id
LEFT JOIN 
    title t ON m.id = t.id
LEFT JOIN 
    person_info pi ON aka.person_id = pi.person_id
WHERE 
    m.production_year BETWEEN 2000 AND 2023
    AND (pi.info IS NULL OR pi.info_type_id = (SELECT id FROM info_type WHERE info = 'Awards'))
GROUP BY 
    m.id, aka.name
ORDER BY 
    m.production_year ASC, Cast_Count DESC
LIMIT 100;
