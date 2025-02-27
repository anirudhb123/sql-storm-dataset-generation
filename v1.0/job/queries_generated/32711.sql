WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        0 AS level
    FROM 
        aka_title m
    WHERE 
        m.production_year IS NOT NULL

    UNION ALL

    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
    JOIN 
        aka_title m ON ml.linked_movie_id = m.id
)
SELECT 
    a.name AS actor_name,
    m.movie_title,
    m.production_year,
    ARRAY_AGG(DISTINCT k.keyword) AS keywords,
    COUNT(DISTINCT mc.company_id) AS company_count,
    SUM(CASE 
            WHEN c.nr_order IS NOT NULL THEN 1 
            ELSE 0 
        END) AS cast_count
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    movie_hierarchy m ON c.movie_id = m.movie_id
LEFT JOIN 
    movie_keyword mk ON m.movie_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_companies mc ON m.movie_id = mc.movie_id
WHERE 
    a.name IS NOT NULL
    AND m.production_year > 2000
GROUP BY 
    a.name, m.movie_title, m.production_year
HAVING 
    COUNT(DISTINCT c.movie_id) > 1 
ORDER BY 
    m.production_year DESC, actor_name;

This SQL query performs the following:

1. **Recursive CTE**: It constructs a hierarchy of movies based on links between them, starting with movies that have a production year. The CTE recursively retrieves movies linked to each other.

2. **Join multiple tables**: It joins the `aka_name`, `cast_info`, `movie_hierarchy`, `movie_keyword`, `keyword`, and `movie_companies` tables to gather information about actors, the movies they've been in, associated keywords, and movie companies linked to those movies.

3. **Aggregation**: The query uses `ARRAY_AGG` to collect distinct keywords for each movie and counts the number of unique companies associated with each movie.

4. **Conditional Counting**: It calculates the total count of roles filled by the actor using a conditional count logic, counting only when `nr_order` is not NULL.

5. **Filter Data**: Conditions in the `WHERE` clause filter for movies produced after 2000 and ensure actor names are not NULL.

6. **Group and Order**: It groups the result by actor, movie title, and production year, and then orders it by production year and actor name.

7. **Having clause**: It limits the results to only those actors who have been in more than one movie.

This combination of constructs and logic tests the performance of the underlying database when handling complex queries with multiple joins, aggregations, and subqueries.
