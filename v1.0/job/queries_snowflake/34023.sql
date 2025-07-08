
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
        LISTAGG(DISTINCT r.role, ', ') WITHIN GROUP (ORDER BY r.role) AS roles
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
