WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        1 AS level,
        ARRAY[m.id] AS path
    FROM 
        aka_title m
    WHERE 
        m.production_year >= 2000

    UNION ALL

    SELECT 
        m.id AS movie_id,
        m.title AS movie_title,
        m.production_year,
        mh.level + 1,
        path || m.id
    FROM 
        aka_title m
    JOIN 
        movie_link ml ON ml.linked_movie_id = m.id
    JOIN 
        MovieHierarchy mh ON mh.movie_id = ml.movie_id
    WHERE 
        NOT m.id = ANY(mh.path) -- Avoid cycles
),

MovieInfo AS (
    SELECT 
        movie_id,
        STRING_AGG(DISTINCT info, ', ') AS all_info
    FROM 
        movie_info
    GROUP BY 
        movie_id
),

ActorPerformance AS (
    SELECT 
        c.movie_id,
        COUNT(DISTINCT c.person_id) AS num_actors,
        AVG(COALESCE(p.info::numeric, 0)) AS avg_participation_years
    FROM 
        cast_info c
    LEFT JOIN 
        person_info p ON p.person_id = c.person_id
    WHERE 
        c.note IS NULL
    GROUP BY 
        c.movie_id
),

RankedMovies AS (
    SELECT 
        mh.movie_id,
        mh.movie_title,
        mh.production_year,
        mp.num_actors,
        mp.avg_participation_years,
        RANK() OVER (PARTITION BY mh.level ORDER BY mp.avg_participation_years DESC) AS rank
    FROM 
        MovieHierarchy mh
    LEFT JOIN 
        ActorPerformance mp ON mh.movie_id = mp.movie_id
)

SELECT 
    rm.movie_id,
    rm.movie_title,
    rm.production_year,
    rm.num_actors,
    rm.avg_participation_years,
    rm.rank,
    COALESCE(mi.all_info, 'No information available') AS movie_info
FROM 
    RankedMovies rm
LEFT JOIN 
    MovieInfo mi ON rm.movie_id = mi.movie_id
WHERE 
    rm.rank <= 10
ORDER BY 
    rm.production_year DESC, rm.rank;
