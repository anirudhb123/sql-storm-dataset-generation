WITH RECURSIVE movie_hierarchy AS (
    SELECT
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        0 AS level
    FROM 
        aka_title m
    WHERE 
        m.production_year >= 2000
    UNION ALL
    SELECT
        lc.linked_movie_id AS movie_id,
        lt.title AS movie_title,
        lt.production_year,
        mh.level + 1 AS level
    FROM 
        movie_link lc
    JOIN 
        aka_title lt ON lc.linked_movie_id = lt.id
    JOIN 
        movie_hierarchy mh ON lc.movie_id = mh.movie_id
)
SELECT 
    ak.name AS actor_name,
    GROUP_CONCAT(DISTINCT mk.keyword) AS keywords,
    COUNT(DISTINCT mh.movie_id) AS linked_movie_count,
    AVG(mh.production_year) AS avg_production_year,
    MAX(mh.level) AS max_hierarchy_level
FROM 
    aka_name ak
JOIN 
    cast_info ci ON ak.person_id = ci.person_id
JOIN 
    movie_hierarchy mh ON ci.movie_id = mh.movie_id
LEFT JOIN 
    movie_keyword mk ON mh.movie_id = mk.movie_id
WHERE 
    ak.name IS NOT NULL
AND 
    NOT EXISTS (
        SELECT 1 
        FROM company_name cn 
        WHERE cn.name = ak.name
    )
GROUP BY 
    ak.name
HAVING 
    COUNT(DISTINCT mh.movie_id) > 1
ORDER BY 
    avg_production_year DESC
LIMIT 10;

### Explanation of the Query:
1. **CTE (Common Table Expression)**: We use a recursive CTE `movie_hierarchy` to find all linked movies starting from titles produced from 2000 onwards. This part collects not only the movies but also their hierarchy level.

2. **Main Query**: 
    - It selects data from `aka_name`, `cast_info`, and the `movie_hierarchy` CTE.
    - It joins the tables to get actors (from `aka_name`) and their linked movies (from `movie_hierarchy`).
    
3. **Aggregation**: 
    - It calculates the keywords associated with each actor using `GROUP_CONCAT`.
    - The query counts how many distinct linked movies each actor has worked in and averages their production years.
    - It uses `MAX(mh.level)` to identify the deepest hierarchy level for movies linked to each actor.

4. **Filtering**:
    - The `HAVING` clause filters out actors with only one linked movie.
    - The `NOT EXISTS` clause ensures that names in `aka_name` don't match those in the `company_name` table.

5. **Final Sorting and Limiting**: The results are ordered by the average production year in descending order, showing the most recent actors at the top, limited to the top 10 results. 

This query aims to perform well on a substantial dataset, showcasing complex relationships within the schema while measuring various metrics related to actors and their movie connections.
