WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        0 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year BETWEEN 2000 AND 2023

    UNION ALL

    SELECT 
        ml.linked_movie_id,
        m.title,
        mh.level + 1
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link ml ON ml.movie_id = mh.movie_id
    JOIN 
        aka_title m ON m.id = ml.linked_movie_id
)
SELECT 
    ak.name AS actor_name,
    COUNT(DISTINCT chn.name) AS character_count,
    ARRAY_AGG(DISTINCT idx.info) AS movie_info,
    AVG(CASE WHEN c.nr_order IS NOT NULL THEN c.nr_order ELSE 0 END) AS avg_order,
    ROW_NUMBER() OVER (PARTITION BY ak.person_id ORDER BY COUNT(mh.movie_id) DESC) AS ranking,
    COALESCE(NULLIF(mk.keyword, ''), 'No Keywords') AS movie_keyword
FROM 
    aka_name ak
JOIN 
    cast_info c ON c.person_id = ak.person_id
JOIN 
    MovieHierarchy mh ON mh.movie_id = c.movie_id
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = mh.movie_id
LEFT JOIN 
    char_name chn ON chn.id = c.role_id
LEFT JOIN 
    movie_info idx ON idx.movie_id = mh.movie_id AND idx.info_type_id = 1
WHERE 
    ak.name IS NOT NULL AND ak.name <> ''
GROUP BY 
    ak.id, ak.name, ak.person_id, mk.keyword
HAVING 
    COUNT(DISTINCT mh.movie_id) > 5
ORDER BY 
    ranking;

This SQL query does the following:

1. **CTE (Common Table Expression)**: Defines a recursive CTE `MovieHierarchy` that constructs a hierarchy of movies linked to each other via the `movie_link` table for films released between 2000 and 2023.

2. **Main SELECT Statement**: 
   - Retrieves actor names from the `aka_name` table.
   - Counts the distinct characters played by them (via `char_name`).
   - Aggregates movie information into an array for further analysis.
   - Calculates the average order of their roles using a `CASE` statement to handle NULL values.
   - Ranks actors based on the number of movies via the `ROW_NUMBER()` window function.
   - Uses `COALESCE` and `NULLIF` to manage any potential empty keyword values.

3. **Joins**: Outer joins (LEFT JOIN) with multiple tables like `movie_keyword`, `char_name`, and `movie_info` to fetch related data while ensuring all actors are included even if they don't have corresponding records in those tables.

4. **WHERE Clause**: Filters out any actor names that are null or empty.

5. **HAVING Clause**: Ensures only actors with more than 5 movies are considered in the final output.

6. **ORDER BY**: Sorts results based on actor ranking. 

Overall, this query benchmarks performance through variety while testing the complexity of joins, aggregations, CTEs, window functions, and analytical functions within the specified schema.


