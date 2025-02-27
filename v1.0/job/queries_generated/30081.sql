WITH RECURSIVE cte_movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id, 
        mt.title AS movie_title, 
        0 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id AS movie_id, 
        at.title AS movie_title, 
        ch.level + 1
    FROM 
        cte_movie_hierarchy ch
    JOIN 
        movie_link ml ON ml.movie_id = ch.movie_id
    JOIN 
        aka_title at ON at.id = ml.linked_movie_id
    WHERE 
        ch.level < 3
)

SELECT 
    ak.name AS actor_name, 
    at.title AS movie_title,
    COUNT(DISTINCT ml.linked_movie_id) AS linked_movies_count,
    ARRAY_AGG(DISTINCT ky.keyword) AS keywords,
    AVG(mv.production_year) AS avg_production_year
FROM 
    cast_info ci
JOIN 
    aka_name ak ON ak.person_id = ci.person_id
JOIN 
    aka_title at ON at.id = ci.movie_id
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = at.id
LEFT JOIN 
    keyword ky ON ky.id = mk.keyword_id
JOIN 
    movie_link ml ON ml.movie_id = ci.movie_id
LEFT JOIN 
    cte_movie_hierarchy mh ON mh.movie_id = ci.movie_id
WHERE 
    ak.name IS NOT NULL
    AND ak.name NOT LIKE '%Unknown%'
    AND at.production_year IS NOT NULL
GROUP BY 
    ak.name, at.title
HAVING 
    COUNT(DISTINCT ml.linked_movie_id) > 2
ORDER BY 
    avg_production_year DESC, 
    actor_name ASC;

### Explanation:
- **CTE**: The recursive common table expression (`cte_movie_hierarchy`) generates a hierarchy of movies linked to each other, starting from movies released after the year 2000, and exploring up to three levels of linked movies.
  
- **JOINs**: The main query uses various joins:
  - `JOIN` between `cast_info`, `aka_name`, and `aka_title` to relate actors to the movies they acted in.
  - `LEFT JOIN` to gather keywords associated with those movies.
  - `JOIN` with `movie_link` to count linked movies.

- **WHERE** Clause: Filters to exclude unknown actors or movies with null production years.

- **Aggregation**: The results include an aggregated count of linked movies and an array of keywords for each actor's movie, along with the average production year for further analysis.

- **HAVING**: Conditions enforce that only actors linked to more than two movies are included.

- **ORDER BY**: Finally, the results are sorted by average production year in descending order and actor names in ascending order.
