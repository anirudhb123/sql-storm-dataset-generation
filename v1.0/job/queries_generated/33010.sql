WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        mt.production_year,
        NULL::integer AS parent_movie_id
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id,
        mt.title AS movie_title,
        mt.production_year,
        mh.movie_id AS parent_movie_id
    FROM 
        movie_link ml
    JOIN 
        aka_title mt ON ml.linked_movie_id = mt.id
    JOIN 
        movie_hierarchy mh ON ml.movie_id = mh.movie_id
)
SELECT 
    mv.movie_title,
    mv.production_year,
    COUNT(ca.person_id) AS actor_count,
    STRING_AGG(DISTINCT a.name, ', ') AS actors,
    SUM(CASE WHEN mo.info IS NOT NULL THEN 1 ELSE 0 END) AS info_count,
    AVG(COALESCE(ca.nr_order, 0)) AS avg_order,
    ROW_NUMBER() OVER (PARTITION BY mv.production_year ORDER BY COUNT(ca.person_id) DESC) AS rank_by_actors
FROM 
    movie_hierarchy mv
LEFT JOIN 
    complete_cast cc ON mv.movie_id = cc.movie_id
LEFT JOIN 
    cast_info ca ON cc.subject_id = ca.id
LEFT JOIN 
    aka_name a ON ca.person_id = a.person_id
LEFT JOIN 
    movie_info mo ON mv.movie_id = mo.movie_id AND mo.info_type_id IN (
        SELECT id FROM info_type WHERE info IN ('description', 'rating')
    )
WHERE 
    mv.production_year IS NOT NULL
GROUP BY 
    mv.movie_id, mv.movie_title, mv.production_year
ORDER BY 
    mv.production_year DESC, actor_count DESC;

### Explanation of the Query Elements:

1. **Recursive CTE**: The `movie_hierarchy` CTE creates a hierarchy of movies starting from those produced in the year 2000, recursively linking to other movies through `movie_link`.

2. **Count & Aggregation**: The main query counts actors associated with each movie, using `COUNT` on the person_id from `cast_info` and aggregates actor names with `STRING_AGG`.

3. **Conditional Aggregation**: We check for null info using `SUM` with a `CASE` statement to count movie information entries that are not null.

4. **Window Function**: The `ROW_NUMBER()` function ranks movies by actor count within each production year.

5. **Outer Joins**: The query utilizes `LEFT JOIN` to include all movies, even if they do not have associated records in `complete_cast`, `cast_info`, or `movie_info`.

6. **NULL Logic**: The query makes use of `COALESCE` to handle any potential null values in `nr_order`.

This query is multifaceted, integrating various SQL features and demonstrating complex relationships across multiple tables in the performance benchmarking context.
