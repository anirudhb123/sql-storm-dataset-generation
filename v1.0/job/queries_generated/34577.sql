WITH RECURSIVE ActorHierarchy AS (
    SELECT 
        c.person_id, 
        c.movie_id, 
        ca.role_id, 
        ca.note,
        1 AS level
    FROM 
        cast_info c
    JOIN 
        role_type ca ON c.role_id = ca.id
    WHERE 
        ca.role = 'Lead'

    UNION ALL

    SELECT 
        c.person_id, 
        c.movie_id, 
        ca.role_id, 
        ca.note,
        ah.level + 1 AS level
    FROM 
        cast_info c
    JOIN 
        ActorHierarchy ah ON c.movie_id = ah.movie_id
    JOIN 
        role_type ca ON c.role_id = ca.id
    WHERE 
        ca.role != 'Lead'
),
MovieDetails AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        STRING_AGG(DISTINCT ak.name, ', ') AS actor_names,
        COUNT(DISTINCT mc.company_id) AS production_companies
    FROM 
        aka_title t
    LEFT JOIN 
        complete_cast cc ON t.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.person_id
    LEFT JOIN 
        aka_name ak ON c.person_id = ak.person_id
    LEFT JOIN 
        movie_companies mc ON t.id = mc.movie_id 
    GROUP BY 
        t.id
),
RankedMovies AS (
    SELECT 
        md.*, 
        RANK() OVER (PARTITION BY md.production_year ORDER BY md.production_year DESC, md.title) AS year_rank
    FROM 
        MovieDetails md
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    rm.actor_names,
    rm.production_companies,
    ah.level AS hierarchy_level
FROM 
    RankedMovies rm
LEFT JOIN 
    ActorHierarchy ah ON rm.movie_id = ah.movie_id
WHERE 
    rm.production_year >= 2000 
    AND (rm.actor_names IS NOT NULL OR ah.level IS NOT NULL)
ORDER BY 
    rm.production_year DESC, 
    rm.title;
