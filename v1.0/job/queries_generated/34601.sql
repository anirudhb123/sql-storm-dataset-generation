WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id, 
        mt.title, 
        mt.production_year, 
        mt.kind_id,
        1 AS depth
    FROM aka_title mt
    WHERE mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie') -- base case for movies
    
    UNION ALL

    SELECT 
        m.id AS movie_id, 
        m.title, 
        m.production_year, 
        m.kind_id,
        mh.depth + 1
    FROM aka_title m
    INNER JOIN movie_link ml ON m.id = ml.linked_movie_id
    INNER JOIN MovieHierarchy mh ON ml.movie_id = mh.movie_id
),
CompanyMovieCount AS (
    SELECT 
        mc.company_id,
        COUNT(DISTINCT mc.movie_id) AS movie_count,
        STRING_AGG(DISTINCT a.name, ', ') AS company_names
    FROM movie_companies mc
    JOIN company_name a ON mc.company_id = a.id
    GROUP BY mc.company_id
),
CastRoles AS (
    SELECT 
        ci.movie_id,
        rt.role AS role_name,
        COUNT(ci.role_id) AS role_count
    FROM cast_info ci
    JOIN role_type rt ON ci.role_id = rt.id
    GROUP BY ci.movie_id, rt.role
),
TopMovies AS (
    SELECT 
        mh.movie_id, 
        mh.title, 
        mh.production_year,
        mh.depth,
        cc.movie_count,
        cr.role_name,
        cr.role_count,
        ROW_NUMBER() OVER (PARTITION BY mh.depth ORDER BY cr.role_count DESC) AS role_rank
    FROM MovieHierarchy mh
    LEFT JOIN CompanyMovieCount cc ON mh.movie_id = cc.company_id
    LEFT JOIN CastRoles cr ON mh.movie_id = cr.movie_id
)
SELECT 
    tm.movie_id,
    tm.title,
    tm.production_year,
    tm.depth,
    COALESCE(tm.movie_count, 0) AS total_companies,
    tm.role_name,
    tm.role_count
FROM TopMovies tm
WHERE tm.depth <= 3 AND tm.role_rank <= 5
ORDER BY tm.production_year DESC, tm.role_count DESC;

This SQL query performs several operations:

- It uses a recursive CTE `MovieHierarchy` to create a hierarchy of movies, assuming there's a relation that allows movies to link to one another.
- It aggregates company data in `CompanyMovieCount`, counting how many movies each company is associated with and collecting their names.
- It counts roles for each movie in `CastRoles`, grouping by role type.
- The `TopMovies` CTE combines the previous data, ordering movies by the count of roles.
- Finally, the main select statement pulls out the top movies by year, restricting to the first three depths of the hierarchy and limiting results to a maximum of the top five roles per movie. 

This showcases various SQL constructs, including CTEs, joins, window functions, aggregation, and conditional expressions.
