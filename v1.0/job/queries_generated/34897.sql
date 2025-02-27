WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS level
    FROM 
        aka_title m
    WHERE 
        m.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
    
    UNION ALL
    
    SELECT 
        m.id,
        m.title,
        m.production_year,
        mh.level + 1
    FROM 
        aka_title m
    JOIN 
        movie_link ml ON m.id = ml.linked_movie_id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
), 

MovieCast AS (
    SELECT 
        c.movie_id,
        a.name AS actor_name,
        COUNT(DISTINCT c.nr_order) AS total_roles
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    GROUP BY 
        c.movie_id, a.name
),

MovieInfo AS (
    SELECT
        m.id AS movie_id,
        m.title,
        m.production_year,
        COALESCE(mi.info, 'No info available') AS info
    FROM 
        aka_title m
    LEFT JOIN 
        movie_info mi ON m.id = mi.movie_id
)

SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    COALESCE(mc.actor_name, 'Unknown') AS lead_actor,
    COALESCE(mc.total_roles, 0) AS total_roles,
    mi.info
FROM 
    MovieHierarchy mh
LEFT JOIN 
    MovieCast mc ON mh.movie_id = mc.movie_id
LEFT JOIN 
    MovieInfo mi ON mh.movie_id = mi.movie_id
WHERE 
    mh.level = 1     -- Only include top-level movies
    AND (mh.production_year > 2000 OR mc.total_roles > 5)  -- Conditions for filtering
ORDER BY 
    mh.production_year DESC, 
    mh.title;

-- This query retrieves a hierarchical list of movies produced after 2000 with 
-- details of their lead actors and the total number of roles.
-- The query utilizes CTEs, outer joins, string expressions, 
-- and complex predicates for filtering results.
