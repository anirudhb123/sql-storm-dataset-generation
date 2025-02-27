WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS depth
    FROM 
        aka_title mt
    WHERE 
        mt.production_year >= 2000
    UNION ALL
    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title,
        at.production_year,
        mh.depth + 1
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    WHERE 
        mh.depth < 5
),
ActorRoleStats AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS actor_count,
        COUNT(DISTINCT ci.role_id) AS role_count
    FROM 
        cast_info ci
    GROUP BY 
        ci.movie_id
),
TopMovies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        COALESCE(ars.actor_count, 0) AS total_actors,
        COALESCE(ars.role_count, 0) AS total_roles,
        ROW_NUMBER() OVER (PARTITION BY mh.production_year ORDER BY mh.production_year DESC, mh.title) AS row_num
    FROM 
        MovieHierarchy mh
    LEFT JOIN 
        ActorRoleStats ars ON mh.movie_id = ars.movie_id
)
SELECT 
    tm.title,
    tm.production_year,
    tm.total_actors,
    tm.total_roles,
    CASE 
        WHEN tm.total_actors > 15 THEN 'Ensemble Cast'
        WHEN tm.total_actors BETWEEN 10 AND 15 THEN 'Moderate Cast'
        ELSE 'Small Cast'
    END AS cast_size_category
FROM 
    TopMovies tm
WHERE 
    tm.row_num <= 10
ORDER BY 
    tm.production_year DESC, 
    tm.total_roles DESC;

This SQL query is designed to analyze the top movies from the Join Order Benchmark schema, focusing on their cast sizes and roles while exploring recursive relationships. Here's a breakdown of the components:

1. **Recursive CTE (WITH RECURSIVE)**: The `MovieHierarchy` CTE builds a hierarchy of movies linked through the `movie_link` table, going up to five levels of linked movies, starting from movies produced after 2000.

2. **Aggregate CTE (ActorRoleStats)**: This CTE counts the number of distinct actors and roles per movie from the `cast_info` table to gather statistics for each movie.

3. **Top Movies Selection**: The `TopMovies` CTE combines information from `MovieHierarchy` and `ActorRoleStats`, utilizing `LEFT JOIN` to get actor and role counts. It also uses `ROW_NUMBER()` to rank movies per production year.

4. **Final Selection**: The main query filters the top movies, categorizes cast sizes using a `CASE` statement, and orders results by production year and roles, highlighting trends in casting across different productions.

This query structure allows for detailed insights while employing various SQL constructs to challenge and benchmark performance with complex data relationships.
