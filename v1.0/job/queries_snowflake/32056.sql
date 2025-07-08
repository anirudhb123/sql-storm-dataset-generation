
WITH RECURSIVE actor_hierarchy AS (
    SELECT 
        c.person_id AS actor_id,
        a.name AS actor_name,
        1 AS level 
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    WHERE 
        c.movie_id IN (
            SELECT id FROM aka_title WHERE production_year = 2020
        )
    UNION ALL
    SELECT 
        c.person_id,
        a.name,
        h.level + 1
    FROM 
        actor_hierarchy h
    JOIN 
        cast_info c ON h.actor_id = c.person_id
    JOIN 
        aka_name a ON c.person_id = a.person_id
)
SELECT 
    a.actor_name,
    COUNT(DISTINCT m.id) AS movies_count,
    AVG(m.production_year) AS avg_production_year,
    LISTAGG(DISTINCT k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords,
    COALESCE(g.kind, 'Not Specified') AS genre,
    ROW_NUMBER() OVER (PARTITION BY a.actor_id ORDER BY AVG(m.production_year) DESC) AS ranking
FROM 
    actor_hierarchy a
JOIN 
    cast_info ci ON a.actor_id = ci.person_id
JOIN 
    aka_title m ON ci.movie_id = m.id
LEFT JOIN 
    movie_keyword mk ON m.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    kind_type g ON m.kind_id = g.id
WHERE 
    m.production_year IS NOT NULL 
    AND m.production_year > 2015
GROUP BY 
    a.actor_id, a.actor_name, g.kind
HAVING 
    COUNT(DISTINCT m.id) >= 5
ORDER BY 
    movies_count DESC, avg_production_year ASC;
