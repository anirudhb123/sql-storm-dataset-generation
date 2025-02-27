WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title AS mt
    WHERE 
        mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
      
    UNION ALL
   
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        mh.level + 1
    FROM 
        movie_link AS ml
    JOIN 
        aka_title AS m ON ml.linked_movie_id = m.id
    JOIN 
        MovieHierarchy AS mh ON ml.movie_id = mh.movie_id
)

SELECT 
    a.name AS actor_name,
    m.title AS movie_title,
    m.production_year,
    COUNT(*) OVER (PARTITION BY a.person_id) AS movie_count,
    (SELECT COUNT(*) FROM complete_cast AS cc WHERE cc.movie_id = m.movie_id) AS total_cast,
    AVG(CASE WHEN m.production_year < 2000 THEN 1 ELSE 0 END) OVER () AS pre_2000_movie_ratio,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
FROM 
    cast_info AS ci
JOIN 
    aka_name AS a ON ci.person_id = a.person_id
JOIN 
    MovieHierarchy AS m ON ci.movie_id = m.movie_id
LEFT JOIN 
    movie_keyword AS mk ON mk.movie_id = m.movie_id
LEFT JOIN 
    keyword AS k ON mk.keyword_id = k.id
WHERE 
    a.name IS NOT NULL
    AND (m.production_year >= 1990 AND m.production_year < 2023)
GROUP BY 
    a.name, m.title, m.production_year
HAVING 
    COUNT(*) > 1
ORDER BY 
    movie_count DESC, actor_name;

### Explanation of Constructs Used:
1. **Recursive CTE (`MovieHierarchy`)**: This CTE builds a hierarchy of movies, including linked movies, starting from the base movie kind.
  
2. **Window Functions**: 
   - `COUNT(*) OVER (PARTITION BY a.person_id)` counts how many movies each actor has participated in.
   - `AVG(CASE WHEN m.production_year < 2000 THEN 1 ELSE 0 END) OVER ()` calculates the overall ratio of movies released before the year 2000.

3. **Outer Join**: The `LEFT JOIN` with movie keywords allows us to retrieve all movies and their keywords, including those without any keywords.

4. **String Aggregation**: `STRING_AGG` combines keywords associated with each movie into a comma-separated list.

5. **Complicated Filtering**: The `WHERE` clause applies a date restriction and checks for non-null actor names.
   
6. **Grouping and Having Clause**: Results are grouped by actor name, movie title, and production year, ensuring only actors who have acted in more than one movie are included in the results.

7. **Final Ordering**: The results are ordered first by the count of movies in descending order and then by actor name. 

This query aims to benchmark performance by filtering through potentially large datasets while demonstrating various SQL concepts.
