WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        1 AS level,
        mt.production_year
    FROM 
        aka_title mt
    WHERE 
        mt.title IS NOT NULL 

    UNION ALL

    SELECT 
        linked_movie.linked_movie_id,
        lt.title,
        mh.level + 1,
        lt.production_year
    FROM 
        movie_link linked_movie
    JOIN 
        aka_title lt ON linked_movie.linked_movie_id = lt.id
    JOIN 
        movie_hierarchy mh ON mh.movie_id = linked_movie.movie_id
)
SELECT 
    mh.title,
    mh.production_year,
    COUNT(mc.company_id) AS company_count,
    COUNT(DISTINCT ci.person_id) AS actor_count,
    STRING_AGG(DISTINCT ak.name, ', ') AS actors,
    SUM(mi.info LIKE '%Awards%') AS awards_info,
    AVG(mh.level) AS average_link_level
FROM 
    movie_hierarchy mh
LEFT JOIN 
    movie_companies mc ON mh.movie_id = mc.movie_id
LEFT JOIN 
    cast_info ci ON mh.movie_id = ci.movie_id
LEFT JOIN 
    aka_name ak ON ci.person_id = ak.person_id
LEFT JOIN 
    movie_info mi ON mh.movie_id = mi.movie_id AND mi.info_type_id = 
        (SELECT id FROM info_type WHERE info = 'Awards' LIMIT 1)
GROUP BY 
    mh.movie_id, mh.title, mh.production_year
HAVING 
    COUNT(mc.company_id) > 1 AND AVG(mh.level) < 2
ORDER BY 
    mh.production_year DESC, movie_count DESC;

### Explanation:
1. **CTE**: A recursive Common Table Expression (`movie_hierarchy`) is used to generate a hierarchy of movies based on their links to each other, keeping track of the production year and hierarchical level.
2. **Main Select**: The main select combines various constructs:
   - **LEFT JOINs**: To gather information from related tables (`movie_companies`, `cast_info`, `aka_name`, and `movie_info`).
   - **Aggregations**: 
        - `COUNT` and `STRING_AGG` to count companies and list actors, respectively.
        - `SUM` to check for the presence of awards information.
        - `AVG` to find the average link level.
3. **Filtering**: The `HAVING` clause limits results to movies with more than one company and an average level of less than two in the hierarchical relationship.
4. **Ordering**: The results are ordered by the production year and the count of linked companies.

This query is designed to showcase the complexity of SQL capabilities with diverse SQL constructs, which may be useful for performance benchmarking.
