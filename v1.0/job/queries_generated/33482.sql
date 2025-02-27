WITH RECURSIVE ActorHierarchy AS (
    SELECT 
        ci.person_id, 
        a.name AS actor_name,
        0 AS level
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    WHERE 
        ci.movie_id IN (SELECT id FROM aka_title WHERE production_year >= 2000)
    
    UNION ALL
    
    SELECT 
        ci.person_id, 
        a.name,
        ah.level + 1
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        ActorHierarchy ah ON ci.movie_id IN (SELECT movie_id FROM cast_info WHERE person_id = ah.person_id)
)
SELECT 
    a.actor_name,
    COUNT(DISTINCT m.id) AS movies_count,
    AVG(m.production_year) AS avg_production_year,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
    MAX(m.production_year) AS last_movie_year,
    (CASE 
        WHEN COUNT(DISTINCT m.id) > 10 THEN 'Prolific Actor' 
        ELSE 'Emerging Talent' 
    END) AS actor_status
FROM 
    ActorHierarchy a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    aka_title m ON ci.movie_id = m.id
LEFT JOIN 
    movie_keyword mk ON m.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    a.level = 0 
GROUP BY 
    a.actor_name
HAVING 
    AVG(m.production_year) < 2010
ORDER BY 
    movies_count DESC
LIMIT 20;

SELECT 
    DISTINCT c.kind
FROM 
    movie_companies mc
JOIN 
    company_type c ON mc.company_type_id = c.id
WHERE 
    mc.movie_id IN (SELECT id FROM aka_title WHERE production_year > 2010)
ORDER BY 
    c.kind;

SELECT 
    DISTINCT m.title, 
    a.actor_name, 
    m.production_year,
    (SELECT COUNT(*) 
        FROM movie_info mi 
        WHERE mi.movie_id = m.id 
        AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'rating')
    ) AS rating_count
FROM 
    aka_title m
JOIN 
    cast_info ci ON m.id = ci.movie_id
JOIN 
    aka_name a ON ci.person_id = a.person_id
WHERE 
    m.kind_id IN (SELECT id FROM kind_type WHERE kind IN ('movie', 'tv movie'))
    AND a.name IS NOT NULL
ORDER BY 
    m.production_year DESC
LIMIT 50;
