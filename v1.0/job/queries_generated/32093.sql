WITH RECURSIVE actor_hierarchy AS (
    SELECT 
        c.person_id,
        ak.name AS actor_name,
        1 AS level
    FROM 
        cast_info c
    JOIN 
        aka_name ak ON ak.person_id = c.person_id
    WHERE 
        c.movie_id IN (SELECT id FROM aka_title WHERE production_year >= 2000)
    
    UNION ALL
    
    SELECT 
        c.person_id,
        ak.name AS actor_name,
        ah.level + 1
    FROM 
        cast_info c
    JOIN 
        aka_name ak ON ak.person_id = c.person_id
    JOIN 
        actor_hierarchy ah ON ah.person_id = c.person_id
)

SELECT 
    a.actor_name,
    COUNT(DISTINCT c.movie_id) AS movie_count,
    STRING_AGG(DISTINCT at.title, ', ') AS movie_titles,
    SUM(CASE 
        WHEN at.production_year BETWEEN 2000 AND 2010 THEN 1 
        ELSE 0 
    END) AS movies_2000s,
    MAX(at.production_year) AS latest_movie_year,
    AVG(CASE 
        WHEN at.production_year IS NOT NULL THEN at.production_year 
        ELSE NULL 
    END) AS avg_year,
    ROW_NUMBER() OVER (ORDER BY movie_count DESC) AS actor_rank
FROM 
    actor_hierarchy a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    aka_title at ON ci.movie_id = at.id
LEFT JOIN 
    movie_info mi ON at.id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Rating')
WHERE 
    at.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
GROUP BY 
    a.actor_name
HAVING 
    COUNT(DISTINCT ci.movie_id) > 5
ORDER BY 
    actor_rank, latest_movie_year DESC;
