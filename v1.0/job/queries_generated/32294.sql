WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        1 AS depth,
        NULL::integer AS parent_id
    FROM 
        aka_title mt
    WHERE 
        mt.episode_of_id IS NULL
    
    UNION ALL
    
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        mh.depth + 1,
        mh.movie_id AS parent_id
    FROM 
        aka_title mt
    JOIN 
        MovieHierarchy mh ON mt.episode_of_id = mh.movie_id
),

CastWithRoles AS (
    SELECT 
        ci.movie_id,
        ak.name AS actor_name,
        rt.role AS role_name,
        ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY ci.nr_order) AS role_rank
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    JOIN 
        role_type rt ON ci.role_id = rt.id
),

MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS all_keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)

SELECT 
    mh.movie_id,
    mh.movie_title,
    COALESCE(cwr.actor_name, 'Unknown Actor') AS actor_name,
    COALESCE(cwr.role_name, 'Unknown Role') AS role_name,
    mh.depth,
    mk.all_keywords,
    CASE 
        WHEN mh.depth > 1 THEN 'Part of a Series'
        ELSE 'Standalone Movie'
    END AS movie_type,
    COUNT(DISTINCT cwr.role_name) OVER (PARTITION BY mh.movie_id) AS unique_roles_count
FROM 
    MovieHierarchy mh
LEFT JOIN 
    CastWithRoles cwr ON mh.movie_id = cwr.movie_id
LEFT JOIN 
    MovieKeywords mk ON mh.movie_id = mk.movie_id
ORDER BY 
    mh.movie_id, cwr.role_rank;

### Explanation:
1. **Recursive CTE (`MovieHierarchy`)**: This recursively retrieves movies that are stand-alone and those that are part of a series by linking `episode_of_id` to `movie_id`.
  
2. **`CastWithRoles` CTE**: Joins `cast_info`, `aka_name`, and `role_type` to gather actor names along with their respective roles while assigning a rank to each role using `ROW_NUMBER()`.

3. **`MovieKeywords` CTE**: Aggregates keywords associated with each movie into a single string using `STRING_AGG`.

4. **Main Query**: The final query selects the movie details, including the title, actor name (with NULL handling), role name, depth of the movie in the hierarchy, concatenated keywords, and categorizes the movie as part of a series or stand-alone. It also computes the count of unique roles using a `COUNT` window function.

This query combines various SQL constructs and is suitable for benchmarking query performance with diverse joins, aggregations, recursive queries, and window functions while considering NULL handling and intricate calculations.
