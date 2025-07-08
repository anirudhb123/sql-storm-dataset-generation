
WITH RECURSIVE ActorHierarchy AS (
    SELECT 
        ci.person_id AS actor_id,
        a.name AS actor_name,
        1 AS depth
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    WHERE 
        ci.movie_id IN (SELECT id FROM aka_title WHERE title LIKE '%Avengers%')
    
    UNION ALL
    
    SELECT 
        ca.person_id,
        a.name,
        ah.depth + 1
    FROM 
        ActorHierarchy ah
    JOIN 
        cast_info ca ON ah.actor_id = ca.person_id
    JOIN 
        aka_name a ON ca.person_id = a.person_id
    WHERE 
        ca.movie_id IN (SELECT movie_id FROM complete_cast WHERE subject_id = ah.actor_id)
)
SELECT 
    ah.actor_name,
    COUNT(DISTINCT ci.movie_id) AS movies_count,
    AVG(m.production_year) AS average_year,
    LISTAGG(DISTINCT k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords,
    ROW_NUMBER() OVER (PARTITION BY ah.actor_name ORDER BY COUNT(DISTINCT ci.movie_id) DESC) AS rank
FROM 
    ActorHierarchy ah
JOIN 
    cast_info ci ON ci.person_id = ah.actor_id
JOIN 
    aka_title m ON ci.movie_id = m.movie_id
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = m.movie_id
LEFT JOIN 
    keyword k ON k.id = mk.keyword_id
WHERE 
    m.production_year BETWEEN 2000 AND 2023
GROUP BY 
    ah.actor_name
HAVING 
    COUNT(DISTINCT ci.movie_id) > 2
ORDER BY 
    movies_count DESC, average_year DESC;
