WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        1 AS hierarchy_level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year IS NOT NULL

    UNION ALL

    SELECT 
        ml.linked_movie_id AS movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        mh.hierarchy_level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title mt ON ml.movie_id = mt.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
)

SELECT 
    ak.name AS actor_name,
    at.title AS movie_title,
    at.production_year AS released_year,
    STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords,
    COUNT(DISTINCT cc.id) AS cast_count,
    MAX(CASE WHEN p.gender = 'F' THEN 'Female' ELSE 'Male' END) AS dominant_gender,
    mh.hierarchy_level AS image_hierarchy_level
FROM 
    aka_name ak
JOIN 
    cast_info ci ON ak.person_id = ci.person_id
JOIN 
    aka_title at ON ci.movie_id = at.id
LEFT JOIN 
    movie_keyword mk ON at.id = mk.movie_id
LEFT JOIN 
    keyword kw ON mk.keyword_id = kw.id
LEFT JOIN 
    movie_hierarchy mh ON at.id = mh.movie_id
LEFT JOIN 
    name p ON ak.person_id = p.imdb_id
WHERE 
    at.production_year >= 2000 
    AND ak.name IS NOT NULL
    AND ak.name <> '' 
    AND (p.gender IS NULL OR p.gender IN ('M', 'F'))
GROUP BY 
    ak.name, at.title, at.production_year, mh.hierarchy_level
HAVING 
    COUNT(DISTINCT cc.id) >= 3 
ORDER BY 
    released_year DESC, actor_name ASC

### Explanation of Key Constructs:
1. **CTE (Common Table Expression)**:
   - The CTE `movie_hierarchy` recursively builds a hierarchy of movies based on linked movies.

2. **Aggregation and String Functions**:
   - `STRING_AGG` is used to concatenate distinct keywords related to each movie.

3. **Complex CASE Logic**:
   - A `CASE` statement determines the dominant gender among actors, defaulting to 'Male' if there's no 'F'.

4. **LEFT JOINs**:
   - Used to include movies even if there are no associated keywords or hierarchical data.

5. **Complicated WHERE Clauses**:
   - Multiple conditions ensure that only relevant data is included, accounting for NULL values and empty strings.

6. **HAVING Clause**:
   - Ensures that only actors with at least 3 associations in the `cast_info` table are included.

7. **ORDER BY Clause**:
   - The final results are sorted by the released year descending, and then by actor name ascending. 

This query not only benchmarks different SQL functionalities but also highlights the complexity of working with relationships in the data architecture.
