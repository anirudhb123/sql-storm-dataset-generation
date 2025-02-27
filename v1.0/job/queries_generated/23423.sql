WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id IN (SELECT id FROM kind_type WHERE kind LIKE '%Movie%')
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id, 
        at.title, 
        at.production_year,
        at.kind_id,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
)
SELECT 
    ak.name AS actor_name,
    STRING_AGG(DISTINCT mh.title, ', ') AS linked_movies,
    COUNT(DISTINCT cn.id) AS production_company_count,
    ROW_NUMBER() OVER (PARTITION BY ak.id ORDER BY COUNT(DISTINCT mh.movie_id) DESC) AS rank
FROM 
    aka_name ak
LEFT JOIN 
    cast_info ci ON ak.person_id = ci.person_id
LEFT JOIN 
    movie_hierarchy mh ON ci.movie_id = mh.movie_id
LEFT JOIN 
    movie_companies mc ON mh.movie_id = mc.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
WHERE 
    ak.name IS NOT NULL 
    AND ak.name <> ''
    AND (mh.production_year > 2000 OR mh.production_year IS NULL)
GROUP BY 
    ak.id, ak.name
HAVING 
    COUNT(DISTINCT mh.movie_id) > 0
ORDER BY 
    rank ASC, actor_name ASC
LIMIT 100
OFFSET 0;  

### Explanation

1. **CTE (Common Table Expression)**: 
   - `movie_hierarchy` builds a recursive hierarchy starting from movies classified as 'Movies', capturing linked movies and their levels.

2. **Main Query**: 
   - The main query pulls actor names from the `aka_name` table. It joins the `cast_info` table to associate actors with their movies, the `movie_hierarchy` to get data on linked movies, and the `movie_companies` along with `company_name` to gather production company data.

3. **Aggregations**:
   - `STRING_AGG` is used to concatenate linked movie titles into a single string for each actor.
   - `COUNT(DISTINCT cn.id)` counts the unique production companies that have been linked to the movies the actor has participated in.

4. **Window Function**: 
   - `ROW_NUMBER()` assigns a rank to actors based on how many distinct movies they are associated with in descending order.

5. **Filtering**:
   - The `WHERE` clause ensures we are considering only valid actor names and movies produced after the year 2000, allowing for NULL production years.

6. **Final Grouping and Ordering**:
   - Results are grouped by actor id and name. The final output is ordered by rank and then actor name, to provide a clean list of actors and their linked movies.

7. **Limits**: 
   - The query uses `LIMIT` and `OFFSET` for pagination, allowing you to control the amount of data retrieved effectively.

This query structure allows for advanced SQL techniques while demonstrating various subtle complexities and corner cases in SQL semantics.
