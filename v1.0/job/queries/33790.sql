WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        0 AS level,
        CAST(m.title AS text) AS path
    FROM 
        aka_title m
    WHERE 
        m.episode_of_id IS NULL

    UNION ALL

    SELECT 
        e.id AS movie_id,
        e.title,
        e.production_year,
        mh.level + 1,
        CAST(mh.path || ' -> ' || e.title AS text) AS path
    FROM 
        aka_title e
    INNER JOIN 
        MovieHierarchy mh ON e.episode_of_id = mh.movie_id
),
RankedMovies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        mh.level,
        mh.path,
        RANK() OVER (PARTITION BY mh.level ORDER BY mh.production_year DESC) AS rank
    FROM 
        MovieHierarchy mh
),
ActorMovies AS (
    SELECT 
        c.movie_id,
        ak.name,
        COUNT(CASE WHEN c.nr_order IS NOT NULL THEN 1 END) AS total_roles
    FROM 
        cast_info c
    JOIN 
        aka_name ak ON ak.person_id = c.person_id
    GROUP BY 
        c.movie_id, ak.name
),
FilteredResults AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        COALESCE(am.name, 'Unknown Actor') AS actor_name,
        COALESCE(am.total_roles, 0) AS total_roles,
        rm.path
    FROM 
        RankedMovies rm
    LEFT JOIN 
        ActorMovies am ON am.movie_id = rm.movie_id
    WHERE 
        rm.rank = 1
)
SELECT 
    fr.movie_id,
    fr.title,
    fr.production_year,
    fr.actor_name,
    fr.total_roles,
    fr.path
FROM 
    FilteredResults fr
WHERE 
    fr.total_roles > 0
ORDER BY 
    fr.production_year DESC, fr.actor_name ASC;