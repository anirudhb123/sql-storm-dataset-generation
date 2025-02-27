WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000

    UNION ALL

    SELECT 
        ml.linked_movie_id AS movie_id,
        a.title,
        a.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title a ON ml.linked_movie_id = a.id
    JOIN 
        MovieHierarchy mh ON mh.movie_id = ml.movie_id
)
SELECT 
    a.name,
    COUNT(DISTINCT m.movie_id) AS movie_count,
    MAX(CASE WHEN m.production_year IS NULL THEN 'Unknown' ELSE m.production_year END) AS last_production_year,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
    AVG(CASE WHEN ci.nr_order IS NULL THEN 0 ELSE ci.nr_order END) AS avg_order
FROM 
    aka_name a
LEFT JOIN 
    cast_info ci ON a.person_id = ci.person_id
LEFT JOIN 
    MovieHierarchy m ON ci.movie_id = m.movie_id
LEFT JOIN 
    movie_keyword mk ON m.movie_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    a.name IS NOT NULL
    AND (m.production_year IS NOT NULL OR a.name NOT LIKE '%[0-9]%')
GROUP BY 
    a.id
HAVING 
    COUNT(DISTINCT m.movie_id) > 5
ORDER BY 
    avg_order DESC NULLS LAST;

### Explanation:
1. **CTE (Common Table Expression):** A recursive CTE named `MovieHierarchy` is used to create a hierarchy of movies starting from those produced after the year 2000. This allows for working with linked movies even if there are multiple layers of connections.
  
2. **String Aggregation:** The use of `STRING_AGG` to collect keywords associated with movies that the actors have participated in.

3. **Complex Joins:** The query demonstrates several outer joins to link actors to the movies they acted in while also retrieving related keywords.

4. **Aggregate Functions & Grouping:** It uses `COUNT`, `MAX`, and `AVG` to derive interesting metrics about each actor such as the number of unique movies, the last production year, and average order of appearance.

5. **Weird NULL handling:** The `CASE` logic captures corner cases where years may be unknown to replace NULL with 'Unknown' and accounts for NULL in averaging the order in which actors appear in movies.

6. **HAVING clause:** Filters actors who have worked in more than 5 distinct movies, ensuring the results focus on prolific actors.

7. **Ordering:** The final results are ordered by `avg_order` in descending order while ensuring that any NULL values in `avg_order` are placed last.

This query combines various SQL features to create a robust and intricate performance benchmark scenario while simultaneously addressing some of the more bizarre semantics SQL can exhibit.
