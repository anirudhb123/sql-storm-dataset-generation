WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS level
    FROM 
        aka_title m
    WHERE 
        m.production_year IS NOT NULL
    
    UNION ALL
    
    SELECT 
        mh.movie_id,
        m.title,
        m.production_year,
        mh.level + 1
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title m ON ml.linked_movie_id = m.id
)
SELECT 
    ak.name AS actor_name,
    av.title AS movie_title,
    av.production_year,
    wc.rank AS role_rank,
    COUNT(DISTINCT C.movie_id) AS total_movies,
    ARRAY_AGG(DISTINCT kw.keyword) AS keywords,
    AVG(CASE WHEN mi.info IS NOT NULL THEN 1 ELSE 0 END) AS average_info_count
FROM 
    aka_name ak
JOIN 
    cast_info ci ON ak.person_id = ci.person_id
JOIN 
    aka_title at ON ci.movie_id = at.id
LEFT JOIN 
    MovieHierarchy mh ON at.id = mh.movie_id
JOIN 
    role_type rt ON ci.role_id = rt.id
LEFT JOIN 
    movie_keyword mk ON at.id = mk.movie_id
LEFT JOIN 
    keyword kw ON mk.keyword_id = kw.id
LEFT JOIN 
    movie_info mi ON mi.movie_id = at.id
LEFT JOIN 
    (SELECT 
         movie_id, 
         DENSE_RANK() OVER (PARTITION BY movie_id ORDER BY nr_order ASC) AS rank
     FROM 
         cast_info) wc ON wc.movie_id = ci.movie_id
WHERE 
    ak.name IS NOT NULL AND ak.name <> ''
    AND mh.level <= 2
GROUP BY 
    ak.name, av.title, av.production_year, wc.rank
ORDER BY 
    total_movies DESC, average_info_count DESC
LIMIT 10;

### Explanation:

1. **CTE (Common Table Expression)**:
   - **MovieHierarchy**: A recursive CTE that constructs a hierarchy of movies linked together through the `movie_link` table. This helps identify related movies that might be sequels or remakes.

2. **FROM Clause**:
   - Joining multiple tables (`aka_name`, `cast_info`, `aka_title`, etc.) to gather information about actors, the movies they appeared in, and related details.

3. **LEFT JOINs**:
   - Used to include additional data such as keywords and information about the roles of actors, even if some of these records are NULL.

4. **Window Function**:
   - The `DENSE_RANK()` function is used to rank roles within each movie. This might help in understanding the importance or order of roles played.

5. **Aggregation Functions**:
   - `COUNT(DISTINCT C.movie_id)` gives the count of unique movies per actor.
   - `ARRAY_AGG(DISTINCT kw.keyword)` collects all unique keywords associated with the movies.

6. **Average Calculation**:
   - A derived average to check the prevalence of information related to movies.

7. **Predicates**:
   - A condition checks if the actor's name isn’t NULL or empty.
   - A constraint on hierarchy levels of movies to limit the depth of the search.

8. **ORDER BY and LIMIT**:
   - Orders the final result by the total number of movies and average information count, limiting the output to the top 10 results. 

This query would provide a performance benchmark by demonstrating the use of complex SQL capabilities such as recursion, window functions, and complex joins while also testing the efficiency of aggregating data in a relational database context.
