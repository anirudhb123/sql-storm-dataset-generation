WITH RECURSIVE ActorHierarchy AS (
    SELECT 
        a.id AS actor_id,
        a.name AS actor_name,
        ca.movie_id AS movie_id,
        1 AS level
    FROM 
        aka_name a
    JOIN 
        cast_info ca ON a.person_id = ca.person_id
    WHERE 
        a.name IS NOT NULL

    UNION ALL

    SELECT 
        a.id AS actor_id,
        a.name AS actor_name,
        lc.linked_movie_id AS movie_id,
        ah.level + 1 AS level
    FROM 
        ActorHierarchy ah
    JOIN 
        movie_link lc ON ah.movie_id = lc.movie_id
    JOIN 
        aka_title at ON lc.linked_movie_id = at.id
    JOIN 
        cast_info ca ON at.movie_id = ca.movie_id
    JOIN 
        aka_name a ON ca.person_id = a.person_id
)
SELECT 
    a.actor_name,
    COUNT(DISTINCT ah.movie_id) AS total_movies,
    MIN(at.production_year) AS first_movie_year,
    MAX(at.production_year) AS last_movie_year,
    COUNT(DISTINCT CASE WHEN mci.company_id IS NOT NULL THEN mci.company_id END) AS production_companies,
    STRING_AGG(DISTINCT kc.keyword, ', ') AS associated_keywords
FROM 
    ActorHierarchy ah
JOIN 
    aka_title at ON ah.movie_id = at.id
LEFT JOIN 
    movie_companies mci ON ah.movie_id = mci.movie_id
LEFT JOIN 
    movie_keyword mk ON ah.movie_id = mk.movie_id
LEFT JOIN 
    keyword kc ON mk.keyword_id = kc.id
JOIN 
    (SELECT DISTINCT person_id FROM cast_info) unique_actors ON ah.actor_id = unique_actors.person_id
WHERE 
    ah.level <= 2
GROUP BY 
    a.actor_name
HAVING 
    COUNT(DISTINCT ah.movie_id) > 5
ORDER BY 
    total_movies DESC, 
    first_movie_year ASC;

This SQL query accomplishes several tasks:
1. It defines a recursive Common Table Expression (CTE) named `ActorHierarchy` that builds a hierarchy of actors based on the movies they have acted in, going through linked movies.
2. The main query aggregates data from this CTE to retrieve actors' names, the total number of movies they have been associated with, the first and last production years of the movies they took part in, the number of unique production companies involved, and any associated keywords.
3. It includes a `LEFT JOIN` to incorporate possible production companies and keywords, counting only those films that meet the level of association within two degrees.
4. The `HAVING` clause filters for actors who have worked in more than 5 distinct movies, sorting the results by the number of movies first and then by the year they first appeared.

This setup provides a structured performance benchmark for SQL capabilities across multiple dimensions, including joins, aggregations, and recursive queries.
