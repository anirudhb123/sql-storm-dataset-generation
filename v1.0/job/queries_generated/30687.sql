WITH RECURSIVE actor_hierarchy AS (
    SELECT 
        ci.person_id,
        ca.name AS actor_name,
        1 AS level
    FROM 
        cast_info ci
    JOIN 
        aka_name ca ON ci.person_id = ca.person_id
    WHERE 
        ci.movie_id IN (SELECT id FROM aka_title WHERE production_year > 2000)

    UNION ALL

    SELECT 
        ci.person_id,
        ca.name AS actor_name,
        ah.level + 1
    FROM 
        cast_info ci
    JOIN 
        aka_name ca ON ci.person_id = ca.person_id
    JOIN 
        actor_hierarchy ah ON ci.movie_id = ah.movie_id
)

SELECT 
    t.title,
    t.production_year,
    STRING_AGG(DISTINCT ah.actor_name, ', ') AS actors,
    COUNT(DISTINCT mc.company_id) AS company_count,
    AVG(
        CASE 
            WHEN mc.note IS NOT NULL THEN LENGTH(mc.note) 
            ELSE 0 
        END
    ) AS avg_note_length,
    COUNT(DISTINCT mk.keyword) AS keyword_count
FROM 
    aka_title t
LEFT JOIN 
    complete_cast cc ON t.id = cc.movie_id
LEFT JOIN 
    movie_companies mc ON t.id = mc.movie_id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    actor_hierarchy ah ON t.id = ah.movie_id
WHERE 
    t.production_year BETWEEN 2000 AND 2023
    AND EXISTS (SELECT 1 FROM movie_info mi WHERE mi.movie_id = t.id AND mi.info ILIKE '%award%')
GROUP BY 
    t.id
ORDER BY 
    t.production_year DESC, 
    STRING_AGG(DISTINCT ah.actor_name, ', ') DESC
LIMIT 50;
