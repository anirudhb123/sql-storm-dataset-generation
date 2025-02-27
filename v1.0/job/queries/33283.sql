WITH RECURSIVE MovieHierarchy AS (
    SELECT
        mt.id AS movie_id,
        mt.title AS movie_title,
        mt.production_year,
        mt.episode_of_id,
        1 AS level
    FROM 
        aka_title mt
    WHERE 
        mt.production_year IS NOT NULL
    
    UNION ALL
    
    SELECT
        mt.id AS movie_id,
        mt.title AS movie_title,
        mt.production_year,
        mt.episode_of_id,
        mh.level + 1
    FROM 
        aka_title mt
        JOIN MovieHierarchy mh ON mt.episode_of_id = mh.movie_id
),
RankedMovies AS (
    SELECT
        m.id AS movie_id,
        m.title,
        m.production_year,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY m.title) AS title_rank,
        COUNT(cmp.company_id) AS company_count
    FROM 
        aka_title m
        LEFT JOIN movie_companies cmp ON m.id = cmp.movie_id
    WHERE 
        m.production_year BETWEEN 2000 AND 2020
    GROUP BY 
        m.id,
        m.title,
        m.production_year
),
ActorRoles AS (
    SELECT
        ci.movie_id,
        ak.name AS actor_name,
        rt.role AS role,
        COUNT(*) AS role_count
    FROM 
        cast_info ci
        JOIN aka_name ak ON ci.person_id = ak.person_id
        JOIN role_type rt ON ci.role_id = rt.id
    WHERE 
        ak.name IS NOT NULL
    GROUP BY 
        ci.movie_id, ak.name, rt.role
),
SelectedMovies AS (
    SELECT
        rm.movie_id,
        rm.title,
        rm.production_year,
        ar.actor_name,
        ar.role,
        ar.role_count
    FROM 
        RankedMovies rm
    LEFT JOIN ActorRoles ar ON rm.movie_id = ar.movie_id
    WHERE 
        rm.company_count > 0 AND ar.role_count IS NOT NULL
)
SELECT 
    sm.movie_id,
    sm.title,
    sm.production_year,
    COALESCE(SUM(sm.role_count), 0) AS total_roles,
    COUNT(DISTINCT sm.actor_name) AS unique_actors,
    STRING_AGG(DISTINCT sm.actor_name, ', ') AS actor_names
FROM 
    SelectedMovies sm
GROUP BY 
    sm.movie_id,
    sm.title,
    sm.production_year
HAVING 
    COUNT(DISTINCT sm.actor_name) > 0
ORDER BY 
    sm.production_year DESC;
