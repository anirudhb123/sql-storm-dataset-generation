WITH RECURSIVE ActorHierarchy AS (
    SELECT 
        ci.person_id,
        p.name AS actor_name,
        1 AS level
    FROM 
        cast_info ci
    JOIN 
        aka_name p ON ci.person_id = p.person_id
    WHERE 
        ci.movie_id = (SELECT MIN(movie_id) FROM cast_info)
    
    UNION ALL
    
    SELECT 
        ci.person_id,
        p.name AS actor_name,
        ah.level + 1
    FROM 
        cast_info ci
    JOIN 
        aka_name p ON ci.person_id = p.person_id
    JOIN 
        ActorHierarchy ah ON ci.movie_id IN (
            SELECT movie_id FROM cast_info WHERE person_id = ah.person_id
        )
)

SELECT 
    a.actor_name,
    COUNT(DISTINCT ci.movie_id) AS movie_count,
    STRING_AGG(DISTINCT t.title, ', ') AS movies,
    COUNT(DISTINCT kc.keyword) AS keyword_count,
    FIRST_VALUE(CASE WHEN c.kind IS NULL THEN 'Unknown Company' ELSE c.kind END) 
        OVER (PARTITION BY a.actor_name ORDER BY COALESCE(c.kind, '')) AS company_type,
    MAX(CASE WHEN mi.info_type_id = it.id THEN mi.info END) AS specific_info
FROM 
    ActorHierarchy a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    aka_title t ON ci.movie_id = t.movie_id
LEFT JOIN 
    movie_companies mc ON mc.movie_id = t.movie_id
LEFT JOIN 
    company_name c ON mc.company_id = c.id
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = t.movie_id
LEFT JOIN 
    keyword kc ON mk.keyword_id = kc.id
LEFT JOIN 
    movie_info mi ON mi.movie_id = t.movie_id
LEFT JOIN 
    info_type it ON mi.info_type_id = it.id
GROUP BY 
    a.actor_name
HAVING 
    COUNT(DISTINCT ci.movie_id) > 5
ORDER BY 
    movie_count DESC;
