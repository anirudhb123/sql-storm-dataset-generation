WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        0 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id AS movie_id,
        ak.title,
        mh.level + 1
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title ak ON ml.linked_movie_id = ak.id
)

SELECT 
    ak.id AS person_id,
    ak.name,
    COUNT(DISTINCT ch.movie_id) AS total_movies,
    SUM(CASE WHEN mt.production_year < 2010 THEN 1 ELSE 0 END) AS pre_2010_movies,
    COUNT(DISTINCT mk.keyword) AS total_keywords,
    ROW_NUMBER() OVER (PARTITION BY ak.person_id ORDER BY COUNT(DISTINCT ch.movie_id) DESC) AS movie_rank
FROM 
    aka_name ak
LEFT JOIN 
    cast_info ci ON ak.person_id = ci.person_id
LEFT JOIN 
    complete_cast cc ON ci.movie_id = cc.movie_id
LEFT JOIN 
    MovieHierarchy mh ON cc.movie_id = mh.movie_id
LEFT JOIN 
    movie_keyword mk ON mh.movie_id = mk.movie_id
LEFT JOIN 
    aka_title mt ON mh.movie_id = mt.id
WHERE 
    ak.name IS NOT NULL 
    AND ak.name <> ''
    AND (mt.production_year IS NULL OR mt.production_year >= 2000)
GROUP BY 
    ak.id, ak.name
HAVING 
    COUNT(DISTINCT ch.movie_id) > 5
ORDER BY 
    total_movies DESC;

### Explanation
1. **Recursive CTE (Common Table Expression)**: `MovieHierarchy` built to capture a hierarchy of linked movies starting from movies produced after 2000.
   
2. **Main Query**: 
   - Selects from `aka_name` to get person details.
   - Joins multiple tables (`cast_info`, `complete_cast`, `movie_keyword`, `aka_title`) to gather detailed information about movies the person has worked on.
   
3. **Aggregations**: 
   - Counts total movies associated with each person.
   - Counts movies produced before 2010 using conditional aggregation (`SUM` with `CASE`).
   - Counts the distinct keywords associated with movies using `COUNT(DISTINCT mk.keyword)`.

4. **Predicate Logic**: 
   - Filters and checks for non-null and non-empty names.
   - Includes filtering based on production year, implementing NULL logic for the join with `aka_title`.

5. **Window Function**: 
   - Utilizes `ROW_NUMBER()` to rank persons based on the total number of movies they have acted in.

6. **Final Output**: 
   - Orders the results based on the total number of movies in descending order, providing a clear insight into the most prolific actors in the MovieHierarchy.
