WITH RECURSIVE MovieCTE AS (
    SELECT 
        t.id AS movie_id, 
        t.title, 
        t.production_year, 
        1 AS level
    FROM 
        aka_title t
    WHERE 
        t.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')

    UNION ALL

    SELECT 
        m.linked_movie_id AS movie_id, 
        mt.title, 
        mt.production_year,
        cte.level + 1
    FROM 
        movie_link m
    JOIN 
        MovieCTE cte ON m.movie_id = cte.movie_id
    JOIN 
        aka_title mt ON m.linked_movie_id = mt.id
    WHERE 
        cte.level < 3  -- Limit the recursive depth
)

SELECT 
    ak.name AS actor_name,
    mt.title AS movie_title,
    mt.production_year,
    COUNT(mo.id) AS num_movies,
    STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords,
    AVG(wm.avg_role_order) AS avg_role_order,
    MAX(IFNULL(ci.note, 'No Note')) AS cast_note
FROM 
    cast_info ci
JOIN 
    aka_name ak ON ci.person_id = ak.person_id
JOIN 
    MovieCTE mt ON ci.movie_id = mt.movie_id
LEFT JOIN 
    movie_keyword mk ON mt.movie_id = mk.movie_id
LEFT JOIN 
    keyword kw ON mk.keyword_id = kw.id
JOIN (
    SELECT 
        movie_id, 
        AVG(nr_order) AS avg_role_order
    FROM 
        cast_info
    GROUP BY 
        movie_id
) wm ON mt.movie_id = wm.movie_id
WHERE 
    mt.production_year BETWEEN 2000 AND 2023
GROUP BY 
    ak.name, mt.title, mt.production_year
HAVING 
    COUNT(mo.id) > 1
ORDER BY 
    mt.production_year DESC,
    ak.name ASC;

### Query Breakdown:
1. **Common Table Expressions (CTEs)**: 
   - A recursive CTE `MovieCTE` is used to retrieve movies and their linked movies, limiting the recursive depth to 3 levels.

2. **Joins**:
   - It employs multiple joins, including inner joins to associate actors with movies and left joins to fetch keywords related to those movies.

3. **Aggregations**:
   - The query computes the number of movies per actor, aggregates keywords into a single string, and averages the order of roles.

4. **NULL Logic and String Functions**:
   - It uses `IFNULL` to provide a fallback note if no cast note exists for a movie.

5. **HAVING Clause**:
   - This filters the results to include only actors who've performed in more than one movie.

6. **Complex Predicates**:
   - The `WHERE` clause filters movies produced between 2000 and 2023, demonstrating date-based predicate logic.

7. **Order By Clause**:
   - The final result is sorted by production year in descending order and actor name in ascending order. 

This query allows for comprehensive performance benchmarking across multiple dimensions such as movie, actor, and keyword relationships, fully leveraging various SQL constructs for complexity.
