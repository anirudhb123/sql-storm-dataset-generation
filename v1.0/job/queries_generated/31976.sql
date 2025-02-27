WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mt.episode_of_id,
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
        at.episode_of_id,
        mh.level + 1 AS level
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
)

SELECT 
    ak.name AS actor_name,
    COUNT(DISTINCT mh.movie_id) AS movie_count,
    AVG(mh.production_year) AS average_production_year,
    STRING_AGG(DISTINCT mw.keyword, ', ') AS keywords,
    ROW_NUMBER() OVER (PARTITION BY ak.name ORDER BY COUNT(DISTINCT mh.movie_id) DESC) AS row_num
FROM 
    aka_name ak
JOIN 
    cast_info ci ON ak.person_id = ci.person_id
JOIN 
    movie_hierarchy mh ON ci.movie_id = mh.movie_id
LEFT JOIN 
    movie_keyword mw ON mh.movie_id = mw.movie_id
WHERE 
    ak.surname_pcode IS NOT NULL
    AND (mh.production_year BETWEEN 2010 AND 2020 OR mh.episode_of_id IS NOT NULL)
GROUP BY 
    ak.name
HAVING 
    COUNT(DISTINCT mh.movie_id) > 3
ORDER BY 
    average_production_year DESC, 
    movie_count DESC;

### Explanation:
1. **CTE (Common Table Expression)**:
   - `movie_hierarchy`: Recursively constructs a hierarchy of movies starting from those produced from the year 2000 onward, including any linked movies.
  
2. **Main Query**:
   - Joins the `aka_name`, `cast_info`, `movie_hierarchy`, and optionally `movie_keyword`.
   - Selects the actor's name, counts the distinct movies they appeared in, calculates the average production year, and aggregates keywords related to those movies.

3. **Filters and Conditions**:
   - `WHERE`: Ensures actor's surname_pcode is not null and checks for specific production years or episodes.
   - `HAVING`: Filters for actors with more than 3 associated movies.

4. **Window Function**:
   - `ROW_NUMBER()`: Provides ranking to actor records based on their movie count.

5. **String Aggregation**:
   - `STRING_AGG()`: Combines multiple keywords into a single string for each actor.

6. **Ordering**:
   - The results are ordered first by average production year and then by movie count in descending order.
