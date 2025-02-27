WITH RECURSIVE MovieCTE AS (
    SELECT 
        title.id AS movie_id,
        title.title,
        title.production_year,
        ARRAY[title.title] AS title_path,
        1 AS level
    FROM 
        title
    WHERE 
        title.production_year >= 2000
    
    UNION ALL

    SELECT 
        mt.linked_movie_id,
        t.title,
        t.production_year,
        m.title_path || t.title,
        level + 1
    FROM 
        MovieCTE m
    JOIN 
        movie_link ml ON m.movie_id = ml.movie_id
    JOIN 
        title t ON ml.linked_movie_id = t.id
)
SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    m.production_year,
    COALESCE(c.company_name, 'Independent') AS company_name,
    (SELECT COUNT(*) FROM movie_keyword mk WHERE mk.movie_id = t.id) AS keyword_count,
    RANK() OVER (PARTITION BY t.production_year ORDER BY COUNT(c.id) DESC) AS cast_rank
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
LEFT JOIN 
    movie_companies mc ON mc.movie_id = t.id
LEFT JOIN 
    company_name c ON mc.company_id = c.id
JOIN 
    MovieCTE m ON m.movie_id = t.id
WHERE 
    t.production_year IS NOT NULL
    AND (m.level > 1 OR c.company_id IS NOT NULL)
    AND a.name IS NOT NULL
GROUP BY 
    a.name, t.title, m.production_year, c.company_name
HAVING 
    COUNT(c.id) > 1
ORDER BY 
    m.production_year DESC, cast_rank ASC;
