WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        0 AS depth
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000 -- Starting with movies from the year 2000

    UNION ALL

    SELECT 
        ml.linked_movie_id,
        (SELECT title FROM aka_title WHERE id = ml.linked_movie_id) AS movie_title,
        mh.depth + 1
    FROM 
        movie_link ml
    JOIN 
        MovieHierarchy mh ON mh.movie_id = ml.movie_id
)

SELECT 
    ak.name AS actor_name,
    COUNT(DISTINCT ch.movie_id) AS total_movies,
    AVG(mr.depth) AS avg_movie_depth,
    STRING_AGG(DISTINCT mt.title, ', ') AS related_movies,
    SUM(CASE 
        WHEN ml.link_type_id IS NOT NULL THEN 1 
        ELSE 0 
    END) AS related_links_count
FROM 
    aka_name ak
JOIN 
    cast_info ci ON ak.person_id = ci.person_id
JOIN 
    complete_cast cc ON cc.movie_id = ci.movie_id
LEFT JOIN 
    MovieHierarchy mr ON mr.movie_id = ci.movie_id
LEFT JOIN 
    movie_link ml ON ml.movie_id = ci.movie_id
JOIN 
    aka_title mt ON mt.id = ci.movie_id
WHERE 
    ak.name IS NOT NULL 
    AND mt.production_year IS NOT NULL 
    AND ci.note IS NULL
GROUP BY 
    ak.name
HAVING 
    COUNT(DISTINCT ch.movie_id) > 5
ORDER BY 
    total_movies DESC;

### Explanation:
- **CTE Allowance:** The recursive CTE (`MovieHierarchy`) explores linked movies (sequel or series) represented in the `movie_link` table, starting from movies released in the year 2000.
- **Joins:** The primary query joins multiple tables — `aka_name`, `cast_info`, `complete_cast`, `movie_link`, and `aka_title` — to gather necessary details about actors and their movies.
- **Calculations:** It calculates total movies by each actor, the average depth in the movie hierarchy of the actor's films, and counts related links. 
- **String Aggregation and NULL Handling:** `STRING_AGG` is used to concatenate titles of related movies, and NULL checks ensure data integrity.
- **Group By and Having:** The results are grouped by actor names, with a condition on having a significant minimum count of unique movies (greater than 5). 

This query covers various constructs like outer joins, CTEs, aggregate functions, and conditional logic within SQL analytics.
