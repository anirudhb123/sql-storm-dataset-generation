WITH RECURSIVE ActorHierarchy AS (
    SELECT 
        ci.id AS cast_id,
        ci.person_id,
        ci.movie_id,
        1 AS level
    FROM 
        cast_info ci
    WHERE 
        ci.role_id = (SELECT id FROM role_type WHERE role = 'Lead Actor')
    
    UNION ALL
    
    SELECT 
        ci.id AS cast_id,
        ci.person_id,
        ci.movie_id,
        ah.level + 1
    FROM 
        cast_info ci
    JOIN 
        ActorHierarchy ah ON ci.movie_id = ah.movie_id
    WHERE 
        ci.role_id != (SELECT id FROM role_type WHERE role = 'Lead Actor')
)
SELECT 
    ak.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    COUNT(DISTINCT ah.person_id) AS total_cast,
    AVG(ah.level) AS average_cast_level,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
FROM 
    ActorHierarchy ah
JOIN 
    aka_name ak ON ak.person_id = ah.person_id
JOIN 
    aka_title at ON at.id = ah.movie_id
JOIN 
    title t ON t.id = at.movie_id
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = ah.movie_id
LEFT JOIN 
    keyword k ON k.id = mk.keyword_id
WHERE 
    t.production_year IS NOT NULL AND t.production_year > 2000
GROUP BY 
    ak.name, t.title, t.production_year
HAVING 
    COUNT(DISTINCT ah.person_id) > 2
ORDER BY 
    t.production_year DESC, total_cast DESC;

This SQL query leverages several advanced SQL features, including:

1. A recursive Common Table Expression (CTE) to build a hierarchy of actors based on their roles in movies.
2. Aggregation functions such as `COUNT`, `AVG`, and `STRING_AGG` for generating insights about the cast and associated keywords.
3. Joins across multiple tables to gather required data about actors (via `aka_name`), movie titles (via `aka_title` and `title`), and related keywords (via `movie_keyword` and `keyword`).
4. An outer join (`LEFT JOIN`) to include movies that may not have any associated keywords.
5. Filtering (`WHERE`) to include only movies released after 2000 with at least three cast members.
6. Ordering the results by production year and total cast count.

This query provides a robust foundation for performance benchmarking, showcasing complex SQL capabilities.
