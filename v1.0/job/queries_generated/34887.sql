WITH RECURSIVE movie_hierarchy AS (
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
        mt.title,
        mt.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
    JOIN 
        aka_title mt ON ml.linked_movie_id = mt.id
)
SELECT 
    a.name AS actor_name,
    COUNT(DISTINCT c.movie_id) AS movie_count,
    STRING_AGG(DISTINCT t.title, ', ') AS titles,
    AVG(mh.level) AS avg_link_level,
    COALESCE(COUNT(DISTINCT CASE WHEN c.nr_order = 1 THEN c.movie_id END), 0) AS lead_roles
FROM 
    cast_info c
JOIN 
    aka_name a ON c.person_id = a.person_id
JOIN 
    movie_hierarchy mh ON c.movie_id = mh.movie_id
JOIN 
    aka_title t ON c.movie_id = t.id
WHERE 
    t.production_year >= 2000
    AND a.name IS NOT NULL
GROUP BY 
    a.name
HAVING 
    COUNT(DISTINCT c.movie_id) > 5
ORDER BY 
    movie_count DESC
LIMIT 10;

This SQL query performs the following functions:

1. **Common Table Expression (CTE)**: A recursive CTE is created to construct a hierarchy of movies based on links between them, capturing how many levels deep linked movies go.

2. **Joins**:
   - It joins multiple tables (`cast_info`, `aka_name`, `movie_hierarchy`, and `aka_title`) to gather detailed information about actors, the movies they've worked on, their titles, and their production years.

3. **Aggregations**:
   - The query counts the number of distinct movies an actor has featured in, aggregates the titles into a comma-separated list, and averages the levels of linked movies.

4. **Conditional Aggregations**: 
   - It counts how many lead roles (first cast member) an actor has based on the `nr_order` field.

5. **Filters and Conditions**:
   - Filters are applied for movies produced from the year 2000 onward, and to exclude actors with NULL names.

6. **Group By and Having Clause**: 
   - The actors are grouped by name, and a having clause ensures that only those actors who have featured in more than five distinct movies are included.

7. **Order and Limiting Results**: 
   - The results are ordered by the number of movies in descending order, returning the top 10 actors who meet the criteria.

This elaborate query aims not only to benchmark performance in terms of complex joins and aggregations but also handles NULLs and employs more advanced SQL constructs like CTEs and aggregates.
