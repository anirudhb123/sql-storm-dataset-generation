WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.kind_id = 1  -- Assuming 1 represents 'movie'

    UNION ALL
    
    SELECT 
        ml.linked_movie_id AS movie_id,
        mt.title,
        mt.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title mt ON ml.movie_id = mt.id
    JOIN 
        movie_hierarchy mh ON mh.movie_id = ml.movie_id
)
SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    COUNT(DISTINCT cc.person_id) AS cast_count,
    STRING_AGG(DISTINCT ak.name, ', ') AS actors,
    MAX(mk.keyword) AS top_keyword,
    CASE 
        WHEN COUNT(DISTINCT ak.name) > 5 THEN 'Large Cast'
        WHEN COUNT(DISTINCT ak.name) BETWEEN 3 AND 5 THEN 'Medium Cast'
        ELSE 'Small Cast'
    END AS cast_size,
    COALESCE(mc.company_name, 'Independent') AS company_name
FROM 
    movie_hierarchy mh
LEFT JOIN 
    complete_cast cc ON mh.movie_id = cc.movie_id
LEFT JOIN 
    cast_info ci ON ci.movie_id = cc.movie_id
LEFT JOIN 
    aka_name ak ON ak.person_id = ci.person_id
LEFT JOIN 
    movie_companies mc ON mc.movie_id = mh.movie_id
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = mh.movie_id
GROUP BY 
    mh.movie_id, mh.title, mh.production_year, mc.company_name
HAVING 
    mh.production_year >= 2000 AND 
    COUNT(DISTINCT ak.name) > 0
ORDER BY 
    mh.production_year DESC, 
    cast_count DESC
LIMIT 10;

### Query Breakdown:
1. **Recursive CTE (`movie_hierarchy`)**:
   - Starts with all movies recorded in `aka_title`.
   - Connects to other linked movies through the `movie_link` table to create a hierarchy of movies.

2. **Main SELECT**:
   - Gathers key data from the recursive CTE regarding movies' title, production year, and count of actors involved.
   - Uses `STRING_AGG` to concatenate distinct actor names.
   - Uses `MAX` to find the top keyword for each movie.

3. **Conditional Logic with `CASE`**:
   - Categorizes the cast size based on the count of distinct actor names.

4. **NULL Logic**:
   - Uses `COALESCE` to provide a fallback value for the company name if no associated company is found.

5. **Filtering and Ordering**:
   - Only includes movies produced after 2000 that have at least one actor logged.
   - Orders results by production year (from latest to oldest) and by cast size.

6. **Limit**:
   - Restricts output to the top 10 results for performance benchmarking.
