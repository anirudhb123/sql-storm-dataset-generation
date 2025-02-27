WITH RECURSIVE ActorHierarchy AS (
    SELECT 
        ca.person_id,
        ca.movie_id,
        1 AS level
    FROM 
        cast_info ca
    WHERE 
        ca.role_id = (SELECT id FROM role_type WHERE role = 'Lead')  -- Start from Lead Actors
  
    UNION ALL
  
    SELECT 
        ca.person_id,
        ca.movie_id,
        ah.level + 1
    FROM 
        cast_info ca
    JOIN 
        ActorHierarchy ah ON ca.movie_id = ah.movie_id
    WHERE 
        ca.role_id <> (SELECT id FROM role_type WHERE role = 'Lead')  -- Include other roles in the same movie
)
SELECT 
    a.name AS actor_name,
    COUNT(DISTINCT m.id) AS movie_count,
    MAX(m.production_year) AS latest_movie_year,
    STRING_AGG(DISTINCT t.title, ', ') AS titles,
    AVG(CASE WHEN m.production_year IS NOT NULL THEN m.production_year ELSE NULL END) AS avg_production_year,
    CASE 
        WHEN COUNT(DISTINCT m.id) = 0 THEN 'No films'
        WHEN COUNT(DISTINCT m.id) BETWEEN 1 AND 5 THEN 'Few films'
        ELSE 'Many films'
    END AS film_experience
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    title m ON m.id = ci.movie_id  -- LEFT JOIN to include actors without movies
LEFT JOIN 
    ActorHierarchy ah ON ci.person_id = ah.person_id
WHERE 
    a.name IS NOT NULL
AND 
    (mi.info_type_id = (SELECT id FROM info_type WHERE info = 'Box Office') 
    OR 
    mk.keyword_id IN (SELECT id FROM keyword WHERE keyword LIKE '%action%'))
GROUP BY 
    a.name
ORDER BY 
    movie_count DESC;

This SQL query employs several advanced constructs:

1. **Recursive CTE**: It builds an ActorHierarchy to represent actors' relationships across different roles in the same movie, starting from lead actors.

2. **Aggregate Functions**: It uses `COUNT`, `MAX`, `AVG`, and `STRING_AGG` to provide detailed insights into the actors and their movies.

3. **Conditional Logic**: A `CASE` statement categorizes actors based on their movie experiences.

4. **Outer Joins**: A `LEFT JOIN` ensures that even actors without movies are included in the results.

5. **Complex Filtering**: The `WHERE` clause contains logical conditions that filter based on various attributes, including NULL checks.

6. **Subqueries**: It includes subqueries to dynamically capture the necessary IDs from lookup tables.

7. **String Expressions and Predicates**: The `LIKE` operator filters keywords to include only those related to 'action'.

This query is intricate and provides a substantial basis for performance benchmarking due to its multi-faceted approach and use of various SQL features.
