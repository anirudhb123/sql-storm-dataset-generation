WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level,
        NULL::integer AS parent_movie_id
    FROM 
        aka_title mt
    WHERE 
        mt.episode_of_id IS NULL
    
    UNION ALL
    
    SELECT 
        et.id AS movie_id,
        et.title,
        et.production_year,
        mh.level + 1,
        mh.movie_id
    FROM 
        aka_title et
    JOIN 
        MovieHierarchy mh ON et.episode_of_id = mh.movie_id
),
ActorRoles AS (
    SELECT 
        ci.person_id,
        r.role,
        COUNT(*) AS role_count
    FROM 
        cast_info ci
    JOIN 
        role_type r ON ci.role_id = r.id
    GROUP BY 
        ci.person_id, r.role
),
RankedMovies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        COUNT(DISTINCT ci.person_id) AS actor_count,
        ROW_NUMBER() OVER (PARTITION BY mh.production_year ORDER BY COUNT(DISTINCT ci.person_id) DESC) AS rank
    FROM 
        MovieHierarchy mh
    LEFT JOIN 
        cast_info ci ON mh.movie_id = ci.movie_id
    GROUP BY 
        mh.movie_id, mh.title, mh.production_year
)
SELECT 
    m.movie_id,
    m.title,
    m.production_year,
    COALESCE(a.name, 'No Actors') AS lead_actor,
    COALESCE(role_counts.role, 'No Role') AS role,
    m.actor_count,
    m.rank
FROM 
    RankedMovies m
LEFT JOIN 
    cast_info ci ON m.movie_id = ci.movie_id
LEFT JOIN 
    aka_name a ON ci.person_id = a.person_id
LEFT JOIN 
    ActorRoles role_counts ON ci.person_id = role_counts.person_id
WHERE 
    m.actor_count > 5
    AND m.production_year >= 2000
ORDER BY 
    m.production_year DESC,
    m.actor_count DESC;

This SQL query consists of several interesting components:

1. **Recursive CTE (MovieHierarchy)**: This CTE builds a hierarchy of movies to include both movies and their episodes, allowing for multi-level relationships.
  
2. **Aggregations and Grouping**: The `ActorRoles` CTE counts the roles for each actor, helping understand the actors' involvement without needing much complexity.

3. **Window Functions**: The `RankedMovies` CTE uses `ROW_NUMBER()` to rank movies within their production year based on the number of unique actors, showcasing performance across years.

4. **Outer Joins**: The final select statement utilizes `LEFT JOINs` to ensure that movies without actors or roles do not get excluded entirely from the results.

5. **COALESCE for Null Logic**: The use of `COALESCE` provides a default value for missing actors or roles, enhancing result readability.

6. **Filtering Conditions**: The final `WHERE` clause restricts results to movies with more than five actors and produced from the year 2000 onwards.

7. **Ordering**: The `ORDER BY` clause sorts results primarily by production year (newest first) and then by actor count.

This all culminates in a comprehensive benchmark for performance analysis of a movie database, focusing on actors' contributions over the years.
