WITH RECURSIVE movie_hierarchy AS (
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
        ml.linked_movie_id,
        at.title,
        at.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        movie_hierarchy mh ON mh.movie_id = ml.movie_id
    WHERE 
        mh.level < 5 -- Limit the hierarchy depth
)

SELECT 
    ak.name AS actor_name,
    COUNT(DISTINCT m.movie_id) AS total_movies,
    AVG(CASE WHEN c.nr_order IS NOT NULL THEN c.nr_order ELSE 0 END) AS avg_order,
    MAX(mh.production_year) AS latest_movie_year,
    STRING_AGG(DISTINCT kt.keyword, ', ') AS keywords
FROM 
    aka_name ak
JOIN 
    cast_info c ON ak.person_id = c.person_id
JOIN 
    movie_companies mc ON mc.movie_id = c.movie_id
JOIN 
    company_name co ON mc.company_id = co.id
JOIN 
    movie_keyword mk ON mk.movie_id = c.movie_id
JOIN 
    keyword kt ON mk.keyword_id = kt.id
LEFT OUTER JOIN 
    movie_hierarchy mh ON mh.movie_id = c.movie_id
WHERE 
    co.country_code = 'USA'
    AND ak.name IS NOT NULL
GROUP BY 
    ak.id
HAVING 
    COUNT(DISTINCT m.movie_id) > 5
ORDER BY 
    total_movies DESC, 
    latest_movie_year DESC;

### Explanation:
1. **Recursive CTE**: The `movie_hierarchy` CTE creates a recursive structure to identify linked movies for a particular range of production years, limiting the hierarchy to a depth of 5.
  
2. **Joins & Aggregates**: The main query combines records from `aka_name`, `cast_info`, `movie_companies`, and other tables to accumulate various statistics.
   
3. **Case Expressions**: A `CASE` statement calculates average order while handling `NULL` values.

4. **String Aggregation**: `STRING_AGG` collects keywords associated with the movies.

5. **Filtering and Grouping**: A standard `WHERE` clause restricts results to entries with specific criteria, and the `HAVING` clause ensures only those actors with more than 5 movies in the results are considered.

6. **Ordering**: Results are sorted based on total movies and latest movie year for optimized viewability. 

This query structure is designed for performance benchmarking by utilizing several complex SQL concepts effectively.
