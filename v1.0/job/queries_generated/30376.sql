WITH RECURSIVE actor_hierarchy AS (
    SELECT 
        c.person_id,
        c.movie_id,
        1 AS depth
    FROM 
        cast_info c
    WHERE 
        c.role_id = (SELECT id FROM role_type WHERE role = 'Director') -- Starting point: Directors in the cast

    UNION ALL

    SELECT 
        c.person_id,
        c.movie_id,
        depth + 1
    FROM 
        cast_info c
    JOIN 
        actor_hierarchy a ON c.movie_id = a.movie_id
    WHERE 
        c.role_id = (SELECT id FROM role_type WHERE role = 'Actor') -- Expand for Actors in the same movie
)

SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    COUNT(DISTINCT r.person_id) AS num_directors,
    AVG(t.production_year - a_h.depth) AS avg_depth_of_directors,
    STRING_AGG(DISTINCT cmp.name, ', ') AS companies_involved,
    COUNT(DISTINCT k.keyword) AS related_keywords
FROM 
    actor_hierarchy a_h
JOIN 
    aka_name a ON a_h.person_id = a.person_id
JOIN 
    title t ON a_h.movie_id = t.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cmp ON mc.company_id = cmp.id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    t.production_year >= 2000 AND 
    t.kind_id IN (SELECT id FROM kind_type WHERE kind IN ('movie', 'tv series')) 
GROUP BY 
    a.name, t.title, t.production_year
HAVING 
    COUNT(DISTINCT r.person_id) > 3 -- Only display movies with more than 3 directors
ORDER BY 
    avg_depth_of_directors DESC, 
    num_directors DESC;
