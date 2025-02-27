WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mc.company_id,
        mc.company_type_id,
        1 AS level
    FROM 
        aka_title mt
    LEFT JOIN 
        movie_companies mc ON mt.id = mc.movie_id

    UNION ALL

    SELECT 
        mh.movie_id,
        mh.title,
        mc.company_id,
        mc.company_type_id,
        mh.level + 1
    FROM 
        movie_hierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title mt ON ml.linked_movie_id = mt.id
    LEFT JOIN 
        movie_companies mc ON mt.id = mc.movie_id
    WHERE 
        mh.level < 3  -- Limit the recursion to prevent deep hierarchy
)

SELECT 
    ak.name AS actor_name,
    ARRAY_AGG(DISTINCT mt.title) AS movies,
    COUNT(DISTINCT mh.movie_id) AS total_movies,
    AVG(mi.year) AS average_production_year,
    STRING_AGG(DISTINCT cn.name, ', ') AS companies_involved,
    SUM(CASE WHEN m.status_id IS NULL THEN 1 ELSE 0 END) AS unproduced_movies
FROM 
    cast_info ci
JOIN 
    aka_name ak ON ci.person_id = ak.person_id
JOIN 
    movie_companies mc ON ci.movie_id = mc.movie_id
JOIN 
    movie_info mi ON ci.movie_id = mi.movie_id
LEFT JOIN 
    movie_hierarchy mh ON ci.movie_id = mh.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
WHERE 
    mi.info_type_id = (SELECT id FROM info_type WHERE info = 'production year')
    AND ak.name IS NOT NULL
GROUP BY 
    ak.name
HAVING 
    COUNT(DISTINCT mh.movie_id) > 2
ORDER BY 
    total_movies DESC;

### Explanation:
1. **CTE `movie_hierarchy`:** Implements a recursive query to build a hierarchy of movies and their associated linked movies, limiting the depth of recursion to three levels.

2. **Main Query:**
    - Joins multiple tables to gather details of actors, movies, production years, and companies involved.
    - Uses `ARRAY_AGG` to aggregate movie titles for each actor.
    - Computes `COUNT` of movies each actor was involved in.
    - Computes the average production year of movies using `AVG`.
    - Uses `STRING_AGG` to list the companies associated with the movies.
    - Sums the number of unproduced movies where the status ID is NULL.
  
3. **Filtering & Grouping:** The results are filtered to include only those actors with more than two movies in the hierarchy and grouped by actor names.

4. **Ordering:** Finally, it orders the results by the total number of movies in descending order to highlight the most prolific actors.
