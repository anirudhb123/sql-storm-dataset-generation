WITH RECURSIVE Movie_CTE AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000
    
    UNION ALL
    
    SELECT 
        m.id,
        m.title,
        m.production_year,
        m.kind_id,
        cte.level + 1
    FROM 
        aka_title m
    JOIN 
        Movie_CTE cte ON m.episode_of_id = cte.movie_id
)

SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    COUNT(cc.person_id) AS total_cast,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
    AVG(mr.level) AS average_recursion_level
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    Movie_CTE t ON c.movie_id = t.movie_id
LEFT JOIN 
    movie_keyword mk ON t.movie_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    (SELECT 
        DISTINCT movie_id, 
        ROW_NUMBER() OVER (PARTITION BY movie_id ORDER BY production_year ASC) AS level
     FROM 
        aka_title
     WHERE 
        production_year IS NOT NULL) mr ON t.movie_id = mr.movie_id
WHERE 
    a.name IS NOT NULL 
    AND a.name <> ''
GROUP BY 
    a.name, t.title, t.production_year
HAVING 
    COUNT(cc.person_id) > 5 
    AND AVG(mr.level) IS NOT NULL
ORDER BY 
    average_recursion_level DESC, total_cast DESC;

### Explanation of the Query:

1. **CTE (Recursive)**: The `Movie_CTE` recursively fetches movies which have been produced since the year 2000, including their hierarchy based on the `episode_of_id` field.

2. **Join Operations**: 
   - It joins `aka_name`, `cast_info`, and the CTE.
   - Utilizes outer joins with `movie_keyword` and `keyword` to gather keywords associated with each movie.

3. **Aggregations**:
   - Counts the total cast members (`COUNT(cc.person_id)`) for each actor-movie pairing while filtering out results with fewer than 5 members using the `HAVING` clause.
   - Averages the recursion level from `mr` subquery which assigns a level based on production year.

4. **String Aggregation**: Uses `STRING_AGG` to collect all distinct keywords associated with the movie into a comma-separated string.

5. **Filtering and Ordering**:
   - Filters out actors or movie titles with empty names.
   - Orders the final output based on the average recursion level and the total cast in descending order for performance benchmarking.

This complex query structure provides insights into actor-movie relationships and the hierarchy of shows, allowing for performance evaluation and testing across various SQL features.
