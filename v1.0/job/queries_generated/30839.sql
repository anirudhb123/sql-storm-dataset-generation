WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.season_nr IS NULL  -- Start with top-level movies (not episodes)
    
    UNION ALL

    SELECT 
        et.id AS movie_id,
        et.title,
        et.production_year,
        mh.level + 1
    FROM 
        aka_title et
    JOIN 
        aka_title ep ON et.episode_of_id = ep.id
    JOIN 
        MovieHierarchy mh ON ep.id = mh.movie_id
),
ActorRoles AS (
    SELECT 
        ci.movie_id,
        a.name AS actor_name,
        COUNT(DISTINCT ci.person_id) OVER (PARTITION BY ci.movie_id) AS number_of_actors,
        STRING_AGG(DISTINCT rt.role, ', ') AS roles
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    LEFT JOIN 
        role_type rt ON ci.role_id = rt.id
    GROUP BY 
        ci.movie_id, a.name
)

SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    ar.actor_name,
    ar.number_of_actors,
    ar.roles,
    COALESCE(MI.info, 'No additional info') AS additional_info
FROM 
    MovieHierarchy mh
LEFT JOIN 
    ActorRoles ar ON mh.movie_id = ar.movie_id
LEFT JOIN 
    movie_info MI ON mh.movie_id = MI.movie_id AND MI.info_type_id = (SELECT id FROM info_type WHERE info = 'Synopsis')
WHERE 
    mh.production_year >= 2000
ORDER BY 
    mh.production_year DESC, mh.title, ar.actor_name;

### Query Explanation:

1. **CTE `MovieHierarchy`**: This recursive Common Table Expression (CTE) constructs a hierarchy of movies, starting with top-level titles (movies without episodes) and recursively joining to titles that are episodes of those movies.

2. **CTE `ActorRoles`**: This aggregates actor names for each movie, counts distinct actors, and compiles their roles into a comma-separated list using the `STRING_AGG` function.

3. **Final SELECT**: The main query selects from `MovieHierarchy` and joins with the `ActorRoles` CTE to get information about the actors and their roles. Additionally, it tries to fetch the movie synopsis from the `movie_info` table, using `COALESCE` to handle cases where no info is present.

4. **WHERE Clause**: The filter ensures that only movies produced in the year 2000 or later are included in the results.

5. **ORDER BY Clause**: It organizes the output first by production year (newest first) and then by title and actor name within that.

This query is intricate, demonstrating various SQL features to showcase performance benchmarking capabilities such as recursive queries, window functions, and complex joins.
