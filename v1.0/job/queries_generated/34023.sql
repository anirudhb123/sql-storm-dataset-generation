WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        COALESCE(mt.season_nr, 0) AS season,
        COALESCE(mt.episode_nr, 0) AS episode,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.episode_of_id IS NULL
    
    UNION ALL
    
    SELECT 
        mt.id AS movie_id,
        mt.title,
        COALESCE(mt.season_nr, 0),
        COALESCE(mt.episode_nr, 0),
        mh.level + 1
    FROM 
        aka_title mt
    JOIN 
        MovieHierarchy mh ON mt.episode_of_id = mh.movie_id
),
CastInfoWithRoles AS (
    SELECT 
        ci.movie_id,
        COUNT(CASE WHEN ci.person_role_id IS NOT NULL THEN 1 END) AS actor_count,
        STRING_AGG(DISTINCT r.role, ', ') AS roles
    FROM 
        cast_info ci
    LEFT JOIN 
        role_type r ON ci.role_id = r.id
    GROUP BY 
        ci.movie_id
),
MovieInfo AS (
    SELECT 
        title.id AS movie_id,
        title.title,
        COALESCE(mi.info, 'No Info') AS movie_info
    FROM 
        title
    LEFT JOIN 
        movie_info mi ON title.id = mi.movie_id AND mi.note IS NULL
)
SELECT 
    mh.movie_id,
    mh.title,
    mh.level,
    ci.actor_count,
    ci.roles,
    mi.movie_info
FROM 
    MovieHierarchy mh
LEFT JOIN 
    CastInfoWithRoles ci ON mh.movie_id = ci.movie_id
LEFT JOIN 
    MovieInfo mi ON mh.movie_id = mi.movie_id
WHERE 
    (mh.season > 0 OR ci.actor_count > 0)
ORDER BY 
    mh.level ASC,
    mh.title ASC;

### Explanation:
1. **Recursive CTE (MovieHierarchy)**: This generates a hierarchy of movies, distinguishing between regular movies and episodes. It recursively joins episodes to their parent series.
2. **CastInfoWithRoles**: This CTE calculates the actor count per movie and aggregates their roles into a comma-separated string.
3. **MovieInfo**: This retrieves additional information for each movie, defaulting to 'No Info' if no related records are found.
4. **Final SELECT**:
   - Joins the hierarchical movie data with actor counts and their respective roles, as well as additional movie information.
   - Filters results to include either movies that belong to a season or those with at least one actor.
   - Orders the results by movie hierarchy level and title. 

This complex query effectively showcases the use of recursive queries, aggregates, joins, and complex filtering criteria in a single cohesive output suitable for performance benchmarking.
