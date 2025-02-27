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
        at.title,
        at.production_year,
        mh.level + 1
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    WHERE 
        mh.level < 5
)
SELECT 
    a.name AS actor_name,
    at.title AS movie_title,
    at.production_year,
    COUNT(DISTINCT kc.keyword) AS keyword_count,
    STRING_AGG(DISTINCT kc.keyword, ', ') AS keywords,
    AVG(CASE 
            WHEN c.nr_order IS NOT NULL THEN c.nr_order 
            ELSE 0 
        END) AS avg_cast_order,
    ROW_NUMBER() OVER (PARTITION BY a.name ORDER BY at.production_year DESC) AS rank
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    MovieHierarchy mh ON c.movie_id = mh.movie_id
JOIN 
    aka_title at ON mh.movie_id = at.id
LEFT JOIN 
    movie_keyword mk ON at.id = mk.movie_id
LEFT JOIN 
    keyword kc ON mk.keyword_id = kc.id
GROUP BY 
    a.name, at.title, at.production_year
HAVING 
    COUNT(DISTINCT kc.keyword) > 1
ORDER BY 
    actor_name, production_year DESC;

### Explanation
1. **CTE (Common Table Expression)**: The `MovieHierarchy` CTE recursively retrieves movies that were produced from the year 2000 onwards, linking them to their corresponding related movies through a many-to-many relationship defined by `movie_link`. The recursion continues until it reaches a maximum depth of 5 levels of connections.

2. **Joins**:
   - **Inner Join** between `aka_name` and `cast_info` connects actors to their roles in movies.
   - **Join** with the `MovieHierarchy` CTE retrieves the movies and their connections.
   - **Left Joins** on `movie_keyword` and `keyword` allow us to gather keyword information for the movies, even if they don't have keywords (hence the use of LEFT JOIN).

3. **Aggregations**:
   - **COUNT(DISTINCT kc.keyword)** to count the number of unique keywords associated with each movie.
   - **STRING_AGG** to concatenate the keywords into a single string for easy readability.

4. **Average Calculation**: The `AVG` function calculates the average value of `nr_order` from the `cast_info` table, handling potential NULL values with a CASE expression.

5. **Window Function**: `ROW_NUMBER()` is used to rank movies by production year for each actor.

6. **HAVING Clause**: Filters the results to only include actors/movies with more than one unique keyword associated.

7. **Final Output**: The result is ordered by actor name and production year, ensuring a well-organized report for further analysis or benchmarking.
