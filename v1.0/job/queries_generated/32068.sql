WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year IS NOT NULL

    UNION ALL

    SELECT 
        ml.linked_movie_id,
        at.title,
        at.production_year,
        mh.level + 1
    FROM 
        movie_link ml
    JOIN 
        aka_title at ON ml.linked_movie_id = at.id
    JOIN 
        MovieHierarchy mh ON ml.movie_id = mh.movie_id
),
RankedMovies AS (
    SELECT 
        mh.movie_id, 
        mh.title, 
        mh.production_year,
        mh.level,
        RANK() OVER (PARTITION BY mh.level ORDER BY mh.production_year DESC) as rank_within_level
    FROM 
        MovieHierarchy mh
),
CastDetails AS (
    SELECT 
        ci.movie_id, 
        ak.name AS actor_name,
        ct.kind AS role_type,
        COUNT(*) OVER (PARTITION BY ci.movie_id) AS total_actors
    FROM 
        cast_info ci
    JOIN 
        aka_name ak ON ci.person_id = ak.person_id
    JOIN 
        comp_cast_type ct ON ci.person_role_id = ct.id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    cd.actor_name,
    cd.role_type,
    cd.total_actors,
    CASE 
        WHEN rm.production_year IS NULL THEN 'Year Unknown'
        ELSE 'Year Known'
    END AS year_availability,
    STRING_AGG(cd.actor_name, ', ') AS actor_list,
    AVG(CASE WHEN cd.role_type = 'lead' THEN 1 ELSE NULL END) OVER (PARTITION BY rm.movie_id) AS lead_actor_ratio
FROM 
    RankedMovies rm
LEFT JOIN 
    CastDetails cd ON rm.movie_id = cd.movie_id
WHERE 
    rm.rank_within_level <= 3
GROUP BY 
    rm.movie_id, rm.title, rm.production_year, cd.actor_name, cd.role_type, cd.total_actors
ORDER BY 
    rm.production_year DESC, rm.movie_id;

This SQL query performs a series of intricate operations using CTEs, window functions, and joins to produce a detailed analysis of movies, including actor roles and their prominence in each film's cast while also stratifying by year of production and maintaining a hierarchy of linked movies.
