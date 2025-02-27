WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS level
    FROM 
        aka_title m
    WHERE 
        m.production_year >= 2000 -- Start from movies made after 2000.
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id AS movie_id,
        m.title,
        m.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title m ON ml.linked_movie_id = m.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
)

SELECT 
    ak.name AS actor_name,
    COUNT(DISTINCT mh.movie_id) AS total_movies_linked,
    AVG(m.production_year) AS avg_production_year,
    STRING_AGG(DISTINCT m.title, ', ') AS movie_titles,
    MAXCASE(mh.level) AS max_linked_level,
    COALESCE(SUM(NULLIF(ci.nr_order, 0)), 0) AS total_cast_order
FROM 
    aka_name ak
INNER JOIN 
    cast_info ci ON ak.person_id = ci.person_id
INNER JOIN 
    movie_hierarchy mh ON ci.movie_id = mh.movie_id
INNER JOIN 
    aka_title m ON mh.movie_id = m.id
LEFT JOIN 
    role_type rt ON ci.role_id = rt.id
WHERE 
    ak.md5sum IS NOT NULL
    AND m.production_year IS NOT NULL
    AND mh.level <= 3 -- Limit to linked movies up to level 3 for performance
GROUP BY 
    ak.name
ORDER BY 
    total_movies_linked DESC, avg_production_year ASC;

### Explanation of the Query:
1. **Recursive CTE**: A recursive Common Table Expression (`movie_hierarchy`) is used to explore linked movies, creating a hierarchy that allows us to find related movies up to three levels deep.
  
2. **Main Query**: The main SELECT statement retrieves actor names along with several aggregated metrics:
   - **Total Movies Linked**: Counter of distinct movies linked through the hierarchy.
   - **Average Production Year**: The average year of production of the movies fetched.
   - **Movie Titles**: A concatenated string of distinct titles of movies the actor has appeared in.
   - **Max Linked Level**: Maximizes the depth of links obtained from the recursive CTE.
   - **Total Cast Order**: Sums the `nr_order` values from the `cast_info`, ignoring any zero values.

3. **Joins**: The query engages various inner and left joins to combine data from multiple tables based on relevant keys.

4. **Filters**: Conditions ensure only valid records (where `md5sum` is not NULL) and relevant production years are included.

5. **Grouping and Ordering**: Results are grouped by actor names and ordered by the number of linked movies in descending order and then the average production year in ascending order. 

This query optimization technique provides a comprehensive look at the links between movies and actors, showcasing the capability to drill down through complex relationships in the database.
