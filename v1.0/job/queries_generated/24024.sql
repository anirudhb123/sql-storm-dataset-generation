WITH RankedMovies AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY mt.title) AS rn,
        COUNT(*) OVER (PARTITION BY mt.production_year) AS total_movies
    FROM 
        aka_title mt
    WHERE 
        mt.production_year IS NOT NULL 
        AND mt.production_year > 2000
),
ActorsWithRoles AS (
    SELECT 
        ak.name AS actor_name,
        ak.person_id,
        ci.movie_id,
        rt.role
    FROM 
        aka_name ak
    JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    JOIN 
        role_type rt ON ci.role_id = rt.id
),
MoviesWithActorDetails AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        STRING_AGG(aw.actor_name, ', ') AS actors,
        MAX(rm.rn) AS max_rank,
        SUM(CASE WHEN aw.role LIKE '%Lead%' THEN 1 ELSE 0 END) AS lead_roles,
        CASE 
            WHEN MAX(rm.rn) < 3 THEN 'Low Rank'
            WHEN MAX(rm.rn) BETWEEN 3 AND 5 THEN 'Medium Rank'
            ELSE 'High Rank'
        END AS rank_category
    FROM 
        RankedMovies rm
    LEFT JOIN 
        ActorsWithRoles aw ON rm.movie_id = aw.movie_id
    GROUP BY 
        rm.movie_id, rm.title, rm.production_year
)
SELECT 
    m.title,
    m.production_year,
    m.actors,
    m.max_rank,
    m.lead_roles,
    m.rank_category,
    CASE 
        WHEN m.lead_roles > 0 THEN 'Has Lead Actor'
        ELSE 'No Lead Actor'
    END AS lead_actor_status,
    COALESCE(NULLIF(m.actors, ''), 'Unknown Actors') AS actor_list
FROM 
    MoviesWithActorDetails m
WHERE 
    m.production_year = (SELECT MAX(production_year) FROM aka_title)
    AND m.lead_roles >= 1
ORDER BY 
    m.rank_category DESC, 
    m.title ASC
LIMIT 10;

-- Additional verification details:
SELECT COUNT(*) AS total_records
FROM aka_title
WHERE production_year IS NOT NULL 
AND production_year > 2000;
