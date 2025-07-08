
WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        1 AS level
    FROM 
        aka_title m
    WHERE 
        m.production_year >= 2000

    UNION ALL

    SELECT 
        ml.linked_movie_id AS movie_id,
        at.title,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
    WHERE 
        mh.level < 3
),
RankedMovies AS (
    SELECT 
        mk.movie_id,
        COUNT(DISTINCT mk.keyword_id) AS keyword_count,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY COUNT(DISTINCT mk.keyword_id) DESC) AS rank
    FROM 
        movie_keyword mk
    JOIN 
        aka_title m ON mk.movie_id = m.id
    WHERE 
        m.production_year IS NOT NULL
    GROUP BY 
        mk.movie_id, m.production_year
),
ActorMovies AS (
    SELECT 
        c.movie_id,
        a.name AS actor_name,
        COUNT(c.id) AS total_roles
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    WHERE 
        a.name IS NOT NULL
    GROUP BY 
        c.movie_id, a.name
)
SELECT 
    mh.title,
    mh.level,
    COALESCE(rm.keyword_count, 0) AS keyword_count,
    am.actor_name,
    COALESCE(am.total_roles, 0) AS total_roles,
    CASE 
        WHEN am.total_roles IS NULL THEN 'No roles'
        ELSE CAST(am.total_roles AS VARCHAR)
    END AS role_display
FROM 
    MovieHierarchy mh
LEFT JOIN 
    RankedMovies rm ON mh.movie_id = rm.movie_id AND rm.rank <= 5
LEFT JOIN 
    ActorMovies am ON mh.movie_id = am.movie_id
WHERE 
    mh.title IS NOT NULL
ORDER BY 
    mh.level, COALESCE(rm.keyword_count, 0) DESC, am.actor_name;
