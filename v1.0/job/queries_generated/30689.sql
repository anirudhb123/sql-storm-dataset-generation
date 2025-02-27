WITH RECURSIVE ActorHierarchy AS (
    SELECT 
        c.person_id,
        c.movie_id,
        c.nr_order,
        1 AS level
    FROM 
        cast_info c
    WHERE 
        c.nr_order = 1
    
    UNION ALL
    
    SELECT 
        c.person_id,
        c.movie_id,
        c.nr_order,
        ah.level + 1
    FROM 
        cast_info c
    JOIN 
        ActorHierarchy ah ON c.movie_id = ah.movie_id AND c.nr_order = ah.nr_order + 1
)
SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    COALESCE(ci.kind, 'Not Specified') AS company_type,
    COUNT(DISTINCT m.company_id) AS company_count,
    AVG(ni.info_length) AS avg_info_length,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
    ROW_NUMBER() OVER (PARTITION BY a.name ORDER BY t.production_year DESC) AS actor_rank
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    aka_title t ON c.movie_id = t.movie_id
LEFT JOIN 
    movie_companies m ON t.id = m.movie_id
LEFT JOIN 
    company_type ci ON m.company_type_id = ci.id
LEFT JOIN (
    SELECT 
        movie_id,
        LENGTH(info) AS info_length
    FROM 
        movie_info
    WHERE
        info IS NOT NULL
) ni ON t.id = ni.movie_id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    t.production_year >= 2000
    AND EXISTS (SELECT 1 FROM ActorHierarchy ah WHERE ah.person_id = a.person_id)
GROUP BY 
    a.id, t.id, ci.kind
HAVING 
    COUNT(DISTINCT m.company_id) > 1
ORDER BY 
    actor_rank, t.production_year DESC;
