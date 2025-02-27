WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        1 AS level
    FROM 
        aka_title m
    WHERE 
        m.production_year >= 2000  -- Filter for recent movies
    UNION ALL
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        mh.level + 1
    FROM 
        aka_title m
    JOIN 
        MovieHierarchy mh ON m.episode_of_id = mh.movie_id  -- Recursive join for episodes
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
ActorRoles AS (
    SELECT 
        ci.movie_id,
        a.name AS actor_name,
        COUNT(ci.role_id) AS role_count,
        ROW_NUMBER() OVER (PARTITION BY ci.movie_id ORDER BY COUNT(ci.role_id) DESC) AS role_rank
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    GROUP BY 
        ci.movie_id, a.name
),
MovieInfo AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        COALESCE(mi.info, 'N/A') AS movie_info
    FROM 
        aka_title m
    LEFT JOIN 
        movie_info mi ON m.id = mi.movie_id
)
SELECT 
    mh.movie_id,
    mh.title,
    mh.production_year,
    mk.keywords,
    ar.actor_name,
    ar.role_count,
    ar.role_rank,
    mi.movie_info
FROM 
    MovieHierarchy mh
LEFT JOIN 
    MovieKeywords mk ON mh.movie_id = mk.movie_id
LEFT JOIN 
    ActorRoles ar ON mh.movie_id = ar.movie_id AND ar.role_rank <= 3  -- Top 3 roles per movie
LEFT JOIN 
    MovieInfo mi ON mh.movie_id = mi.movie_id
WHERE 
    mh.level = 1  -- Limit to top-level movies
ORDER BY 
    mh.production_year DESC, 
    ar.role_count DESC NULLS LAST;  -- Order by production year and role count
