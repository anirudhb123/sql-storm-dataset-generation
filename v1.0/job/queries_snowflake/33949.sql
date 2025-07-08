
WITH RECURSIVE MovieHierarchy AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        NULL AS parent_id
    FROM 
        aka_title t
    WHERE 
        t.episode_of_id IS NULL
    UNION ALL
    SELECT 
        t.id,
        t.title,
        t.production_year,
        t.episode_of_id
    FROM 
        aka_title t
    INNER JOIN 
        MovieHierarchy mh ON t.episode_of_id = mh.movie_id
),
RankedMovies AS (
    SELECT 
        mh.movie_id,
        mh.title,
        mh.production_year,
        ROW_NUMBER() OVER (PARTITION BY mh.production_year ORDER BY mh.title) AS title_rank
    FROM 
        MovieHierarchy mh
),
ActorRoles AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS actor_count,
        LISTAGG(DISTINCT CONCAT(na.name, ' (', rt.role, ')'), ', ') WITHIN GROUP (ORDER BY na.name) AS actors_with_roles
    FROM 
        cast_info ci
    JOIN 
        aka_name na ON ci.person_id = na.person_id
    JOIN 
        role_type rt ON ci.role_id = rt.id
    GROUP BY 
        ci.movie_id
),
MovieDetails AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        COALESCE(ar.actor_count, 0) AS actor_count,
        ar.actors_with_roles,
        CASE 
            WHEN rm.production_year IS NULL OR rm.production_year < 2000 THEN 'Classic'
            ELSE 'Modern'
        END AS era_label
    FROM 
        RankedMovies rm
    LEFT JOIN 
        ActorRoles ar ON rm.movie_id = ar.movie_id
)
SELECT 
    md.title,
    md.production_year,
    md.actor_count,
    md.actors_with_roles,
    md.era_label
FROM 
    MovieDetails md
WHERE 
    (md.era_label = 'Modern' AND md.actor_count > 5) 
    OR (md.era_label = 'Classic' AND md.production_year BETWEEN 1980 AND 1999)
ORDER BY 
    md.production_year DESC, md.title;
