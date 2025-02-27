WITH RECURSIVE ActorHierarchy AS (
    SELECT 
        ci.person_id,
        ca.name AS actor_name,
        1 AS level
    FROM 
        cast_info ci
    JOIN 
        aka_name ca ON ci.person_id = ca.person_id
    WHERE 
        ci.movie_id IN (SELECT movie_id FROM aka_title WHERE kind_id = 1)  -- Assuming 1 corresponds to feature films

    UNION ALL

    SELECT 
        ci.person_id,
        ah.actor_name,
        ah.level + 1
    FROM 
        cast_info ci
    JOIN 
        ActorHierarchy ah ON ci.movie_id IN (SELECT movie_id FROM cast_info WHERE person_id = ah.person_id)
)

SELECT 
    ah.actor_name,
    COUNT(DISTINCT ci.movie_id) AS movie_count,
    AVG(t.production_year) AS avg_production_year,
    STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords,
    CASE 
        WHEN COUNT(DISTINCT ci.movie_id) > 5 THEN 'Frequent Actor'
        ELSE 'Novice Actor'
    END AS actor_status
FROM 
    ActorHierarchy ah
JOIN 
    cast_info ci ON ah.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword kw ON mk.keyword_id = kw.id
GROUP BY 
    ah.actor_name
HAVING 
    COUNT(DISTINCT ci.movie_id) > 2 AND 
    AVG(t.production_year) > COALESCE(NULLIF(MIN(t.production_year), 0), 1900)
ORDER BY 
    movie_count DESC
LIMIT 10;

This SQL query:
- Defines a recursive CTE `ActorHierarchy` to traverse and build a hierarchy of actors based on their cast.
- Joins multiple tables: `cast_info`, `aka_name`, `title`, and `keyword` to gather relevant data about actors and their movies.
- Uses aggregate functions to compute counts of movies acted in and average production year.
- Utilizes string aggregation to combine keywords associated with each movie.
- Applies a `CASE` statement to categorize actors based on their frequency of roles.
- Filters results in the `HAVING` clause according to specific conditions.
- Orders the results by the count of movies in descending order and limits the output to the top 10 actors.
