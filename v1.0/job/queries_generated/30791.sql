WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year IS NOT NULL

    UNION ALL

    SELECT 
        ml.linked_movie_id,
        m.title,
        m.production_year,
        mh.level + 1
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title m ON ml.linked_movie_id = m.id
)

SELECT 
    ak.person_id,
    ak.name AS actor_name,
    COUNT(DISTINCT mh.movie_id) AS movies_linked,
    AVG(mh.production_year) AS avg_prod_year,
    STRING_AGG(DISTINCT m.title, ', ') AS related_movies,
    ROW_NUMBER() OVER (PARTITION BY ak.person_id ORDER BY COUNT(DISTINCT mh.movie_id) DESC) AS actor_ranking
FROM 
    aka_name ak
LEFT JOIN 
    cast_info ci ON ak.person_id = ci.person_id
LEFT JOIN 
    MovieHierarchy mh ON ci.movie_id = mh.movie_id
GROUP BY 
    ak.person_id, ak.name
HAVING 
    COUNT(DISTINCT mh.movie_id) > 3
ORDER BY 
    actor_ranking
LIMIT 10;

This query performs the following:

1. **Recursive CTE** to establish a hierarchy of movies based on links to other movies (`MovieHierarchy`).
2. **Join** to the `aka_name` and `cast_info` tables to associate actors with their movies.
3. Calculations for:
   - Count of distinct movies linked to each actor.
   - Average production year of those movies.
   - Aggregation of movie titles using `STRING_AGG`.
4. **Window function** (`ROW_NUMBER()`) to rank actors based on the number of linked movies.
5. A **filter** to ensure that only actors linked to more than three movies are selected.
6. Result ordering and limiting to get the top results.

This combines multiple advanced SQL constructs to test performance and demonstrate complexity.
