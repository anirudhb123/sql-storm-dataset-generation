WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title AS movie_title,
        mt.production_year,
        1 AS level,
        NULL::integer AS parent_movie_id
    FROM title mt
    WHERE mt.kind_id = (SELECT id FROM kind_type WHERE kind = 'feature')
    
    UNION ALL
    
    SELECT 
        ml.linked_movie_id,
        lt.title,
        lt.production_year,
        mh.level + 1,
        mh.movie_id
    FROM MovieHierarchy mh
    JOIN movie_link ml ON mh.movie_id = ml.movie_id
    JOIN title lt ON ml.linked_movie_id = lt.id
    WHERE mh.level < 3  -- Limit to 3 levels of hierarchy
),
RankedMovies AS (
    SELECT 
        mh.movie_id,
        mh.movie_title,
        mh.production_year,
        mh.level,
        RANK() OVER (PARTITION BY mh.level ORDER BY mh.production_year DESC) AS year_rank
    FROM MovieHierarchy mh
),
CastMovieInfo AS (
    SELECT 
        ci.movie_id,
        a.name AS actor_name,
        c2.kind AS role_type,
        COUNT(ci.id) AS role_count
    FROM cast_info ci
    JOIN aka_name a ON ci.person_id = a.person_id
    LEFT JOIN role_type c2 ON ci.role_id = c2.id
    GROUP BY ci.movie_id, a.name, c2.kind
),
CombinedResults AS (
    SELECT 
        rm.movie_id,
        rm.movie_title,
        rm.production_year,
        rm.level,
        cm.actor_name,
        cm.role_type,
        cm.role_count,
        COALESCE(cm.role_count, 0) AS total_roles  -- Handling NULLs
    FROM RankedMovies rm
    LEFT JOIN CastMovieInfo cm ON rm.movie_id = cm.movie_id
)
SELECT 
    cr.movie_id,
    cr.movie_title,
    cr.production_year,
    cr.level,
    cr.actor_name,
    cr.role_type,
    cr.total_roles,
    CASE 
        WHEN cr.total_roles > 0 THEN 'Active'
        ELSE 'Inactive'
    END AS status_description
FROM CombinedResults cr
WHERE cr.production_year >= 2000  -- Filter for more recent movies
ORDER BY cr.level, cr.production_year DESC
LIMIT 100;  -- Limit for performance benchmarking
