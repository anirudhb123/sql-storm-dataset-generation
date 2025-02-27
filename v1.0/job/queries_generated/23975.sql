WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        mt.kind_id,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year IS NOT NULL

    UNION ALL

    SELECT 
        m.id, 
        m.title,
        m.production_year,
        m.kind_id,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
    JOIN 
        aka_title m ON m.id = ml.linked_movie_id
    WHERE 
        mh.level < 5  -- Limit the depth of recursion to avoid infinite loops
),
CastRoleCounts AS (
    SELECT 
        ci.movie_id,
        rt.role,
        COUNT(ci.role_id) AS role_count
    FROM 
        cast_info ci
    JOIN 
        role_type rt ON ci.role_id = rt.id
    WHERE 
        ci.note IS NULL OR ci.note NOT LIKE '%cameo%'
    GROUP BY 
        ci.movie_id, rt.role
),
MovieAverages AS (
    SELECT 
        movie_id,
        AVG(role_count) AS average_roles
    FROM 
        CastRoleCounts
    GROUP BY 
        movie_id
),
FilteredMovies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        coalesce(ma.average_roles, 0) AS avg_roles
    FROM 
        MovieHierarchy mh
    LEFT JOIN 
        MovieAverages ma ON mh.movie_id = ma.movie_id
    WHERE 
        mh.kind_id IN (
            SELECT id FROM kind_type WHERE kind LIKE 'A%' -- Filtering based on kind type starting with 'A'
        )
    AND
        (mh.production_year BETWEEN 2000 AND 2023 OR mh.title LIKE '%Action%') -- Year or genre constraint
)

SELECT 
    fm.title,
    fm.production_year,
    fm.avg_roles,
    COALESCE(NULLIF(fm.avg_roles, 0), (SELECT AVG(avg_roles) FROM FilteredMovies) ) AS fallback_w_avg_roles
FROM 
    FilteredMovies fm
WHERE 
    fm.avg_roles > 1
ORDER BY 
    fm.avg_roles DESC
FETCH FIRST 10 ROWS ONLY;


### Explanation of the Query:
1. **Recursive CTE (MovieHierarchy)**: This builds a hierarchy of movies based on links to other movies, limiting the recursion to a depth of 5 to prevent infinite loops.
  
2. **Aggregate Role Counts (CastRoleCounts)**: It aggregates the count of roles for each movie that does not have cameo appearances.
  
3. **Compute Averages (MovieAverages)**: It calculates the average count of roles across all movies grouped by movie ID.
  
4. **FilteredMovies CTE**: Combines the previous CTEs to filter for specific conditions, including movie kinds starting with 'A' and those produced in a certain timeframe or containing certain titles.
  
5. **Final Selection**: The main query selects titles, years, and average roles, applying a **NULL** fallback logic using a nested **SELECT**. 

This query includes complex join structures, filtering, aggregation, and handling of NULL values all while adhering to conditional logic, making it ideal for performance benchmarking.
