WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year IS NOT NULL
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id,
        lt.title,
        lt.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title lt ON ml.linked_movie_id = lt.id
    JOIN 
        movie_hierarchy mh ON mh.id = ml.movie_id
)

SELECT 
    ak.name AS actor_name,
    mt.title AS movie_title,
    mt.production_year,
    COUNT(DISTINCT mc.company_id) AS company_count,
    STRING_AGG(DISTINCT cn.name, ', ') AS company_names,
    AVG(mv_info.note IS NOT NULL AND mv_info.info_type_id = 1) * 100 AS rating_percentage,
    mh.level AS hierarchy_level
FROM 
    cast_info ci
JOIN 
    aka_name ak ON ci.person_id = ak.person_id
JOIN 
    movie_hierarchy mh ON ci.movie_id = mh.id
LEFT JOIN 
    movie_companies mc ON mh.id = mc.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
LEFT JOIN 
    movie_info mv_info ON mh.id = mv_info.movie_id AND mv_info.info_type_id IS NOT NULL
JOIN 
    aka_title mt ON mh.id = mt.id
WHERE 
    ak.name IS NOT NULL 
    AND ak.name <> ''
    AND mt.production_year BETWEEN 2000 AND 2023
GROUP BY 
    ak.name, mt.title, mt.production_year, mh.level
HAVING 
    COUNT(DISTINCT mc.company_id) > 0
ORDER BY 
    rating_percentage DESC, movie_title ASC;

This SQL query performs several advanced SQL operations:

1. **Recursive CTE** (`movie_hierarchy`): This creates a hierarchy of movies, allowing us to explore linked movies and their levels.

2. **Aggregations**: It counts the number of distinct companies associated with each movie and also aggregates company names into a comma-separated string.

3. **String Handling**: It filters out NULL and empty values for actor names.

4. **Window Functions**: Although not separately shown in this example, you could easily embed window functions to analyze rows in different groups further if desired.

5. **Complicated predicates**: The query contains various predicates, including checks for non-NULL names and production years within a specified range.

6. **LEFT JOINs**: Used to extract information from associated tables even when there might not be a corresponding entry.

7. **HAVING Clause**: Used to filter groups based on the results of an aggregate function.

This query, therefore, significantly utilizes different SQL constructs, providing rich information on movie actor involvement and company engagement relative to the production years.
