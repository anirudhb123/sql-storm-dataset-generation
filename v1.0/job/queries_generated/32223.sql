WITH RECURSIVE actor_hierarchy AS (
    SELECT 
        c.person_id,
        a.name AS actor_name,
        ARRAY[a.name] AS path, 
        1 AS level
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    WHERE 
        c.movie_id IN (SELECT id FROM aka_title WHERE production_year = 2023)

    UNION ALL

    SELECT 
        c.person_id,
        a.name AS actor_name,
        path || a.name, 
        level + 1
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        actor_hierarchy ah ON c.movie_id = (SELECT movie_id FROM cast_info WHERE person_id = ah.person_id LIMIT 1)
    WHERE 
        a.name NOT IN (SELECT UNNEST(path))  
)

SELECT 
    ah.actor_name,
    COUNT(DISTINCT ci.movie_id) AS total_movies,
    STRING_AGG(DISTINCT at.title, ', ') AS movie_titles,
    MAX(at.production_year) AS last_movie_year,
    MIN(at.production_year) AS first_movie_year,
    SUM(CASE WHEN ci.person_role_id IS NULL THEN 1 ELSE 0 END) AS roles_without_id
FROM 
    actor_hierarchy ah
JOIN 
    cast_info ci ON ah.person_id = ci.person_id
JOIN 
    aka_title at ON ci.movie_id = at.movie_id
GROUP BY 
    ah.actor_name
ORDER BY 
    total_movies DESC
LIMIT 10;

-- Perform an outer join to find actors who haven't appeared in any movies
SELECT 
    n.name,
    COUNT(DISTINCT ci.movie_id) AS total_movies
FROM 
    aka_name n
LEFT JOIN 
    cast_info ci ON n.person_id = ci.person_id
WHERE 
    n.name IS NOT NULL
GROUP BY 
    n.name
HAVING 
    total_movies = 0
ORDER BY 
    n.name;

-- Aggregate keyword information for movies featuring an actor from the previous result set
SELECT 
    n.name AS actor_name,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
FROM 
    aka_name n
JOIN 
    cast_info ci ON n.person_id = ci.person_id
JOIN 
    movie_keyword mk ON ci.movie_id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    n.name IN (SELECT actor_name FROM actor_hierarchy)
GROUP BY 
    n.name
ORDER BY 
    n.name;
