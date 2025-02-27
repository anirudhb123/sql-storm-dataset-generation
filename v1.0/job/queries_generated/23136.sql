WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        t.title,
        t.production_year,
        1 AS level
    FROM 
        aka_title t
    JOIN 
        movie_link ml ON t.id = ml.movie_id
    LEFT JOIN 
        title m ON m.id = ml.linked_movie_id
    WHERE 
        t.production_year IS NOT NULL AND m.id IS NOT NULL

    UNION ALL

    SELECT 
        m.id AS movie_id,
        mh.title,
        mh.production_year,
        mh.level + 1
    FROM 
        MovieHierarchy mh
    JOIN 
        movie_link ml ON mh.movie_id = ml.movie_id
    JOIN 
        aka_title t ON t.id = ml.linked_movie_id
    JOIN 
        title m ON m.id = t.id
)
, CompanyAggregates AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        COUNT(mc.id) AS company_count
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    GROUP BY 
        mc.movie_id, c.name
)
, ActorsInMovies AS (
    SELECT 
        ci.movie_id,
        a.name AS actor_name,
        COUNT(ci.id) AS num_roles,
        STRING_AGG(DISTINCT r.role, ', ') AS roles
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        role_type r ON ci.role_id = r.id
    GROUP BY 
        ci.movie_id, a.name
)
SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    COALESCE(ca.company_name, 'Unknown Company') AS company_name,
    COALESCE(ai.actor_name, 'No Actors') AS actor_name,
    ai.num_roles,
    ai.roles,
    mh.level
FROM 
    MovieHierarchy mh
LEFT JOIN 
    CompanyAggregates ca ON mh.movie_id = ca.movie_id
LEFT JOIN 
    ActorsInMovies ai ON mh.movie_id = ai.movie_id
WHERE 
    (mh.production_year >= 2000 OR mh.production_year IS NULL)
    AND (mh.title IS NOT NULL AND LENGTH(mh.title) > 0)
ORDER BY 
    mh.production_year DESC, 
    mh.title ASC 
LIMIT 100;
