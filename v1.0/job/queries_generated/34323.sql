WITH RECURSIVE movie_hierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS depth
    FROM 
        aka_title m
    WHERE 
        m.production_year IS NOT NULL

    UNION ALL

    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        mh.depth + 1
    FROM 
        movie_link ml
    JOIN 
        movie_hierarchy mh ON ml.linked_movie_id = mh.movie_id
    JOIN 
        aka_title m ON ml.movie_id = m.id
)
, ranked_cast AS (
    SELECT 
        ci.person_id,
        ci.movie_id,
        ci.nr_order,
        RANK() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS role_rank
    FROM 
        cast_info ci
)
SELECT 
    m.title AS movie_title,
    m.production_year,
    COUNT(DISTINCT rc.person_id) AS cast_count,
    AVG(rp.role_rank) AS avg_role_rank,
    STRING_AGG(DISTINCT ak.name, ', ') AS aka_names
FROM 
    movie_hierarchy m
LEFT JOIN 
    ranked_cast rc ON m.movie_id = rc.movie_id
LEFT JOIN 
    aka_name ak ON rc.person_id = ak.person_id
WHERE 
    m.production_year BETWEEN 2000 AND 2023
    AND m.title IS NOT NULL
GROUP BY 
    m.movie_id, m.title, m.production_year
HAVING 
    COUNT(DISTINCT rc.person_id) > 5
ORDER BY 
    avg_role_rank ASC;

### Explanation:
1. **CTE - Recursive Movie Hierarchy**: The `movie_hierarchy` CTE generates a hierarchy of movies, allowing for recursive retrieval of linked movies while capturing their depth in the hierarchy.
  
2. **CTE - Ranked Cast**: The `ranked_cast` CTE assigns a rank to each cast member per movie based on the order of their appearance.

3. **Main Query**:
   - Joins the movie hierarchy with the ranked cast and the aka_name to gather all necessary information.
   - Filters movies produced between 2000 and 2023 that have non-null titles.
   - Groups the results by movie and calculates the total distinct cast count and average role rank.
   - Uses `STRING_AGG` to concatenate names from the `aka_name` table.
   - Applies a filtering condition in the `HAVING` clause to only include movies with more than 5 distinct cast members.
   - Orders the final output by the average role rank, from lowest to highest.
