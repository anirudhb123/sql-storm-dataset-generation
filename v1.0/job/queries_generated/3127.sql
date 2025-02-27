WITH RankedMovies AS (
    SELECT 
        at.title, 
        at.production_year,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY at.title) AS rank
    FROM 
        aka_title at
    WHERE 
        at.production_year IS NOT NULL
),
ActorDetails AS (
    SELECT 
        ak.name AS actor_name,
        mc.movie_id,
        COUNT(ci.id) AS role_count
    FROM 
        aka_name ak
    JOIN 
        cast_info ci ON ak.person_id = ci.person_id
    JOIN 
        complete_cast cc ON ci.movie_id = cc.movie_id
    JOIN 
        movie_companies mc ON cc.movie_id = mc.movie_id
    GROUP BY 
        ak.name, mc.movie_id
),
HighestRoleCount AS (
    SELECT 
        actor_name, 
        MAX(role_count) AS max_roles
    FROM 
        ActorDetails
    GROUP BY 
        actor_name
)
SELECT 
    rm.title, 
    COALESCE(ah.actor_name, 'No actors') AS actor_name, 
    rm.production_year
FROM 
    RankedMovies rm
LEFT JOIN 
    ActorDetails ad ON rm.title = ad.movie_id
LEFT JOIN 
    HighestRoleCount ah ON ad.actor_name = ah.actor_name
WHERE 
    rm.rank <= 5
    AND rm.production_year BETWEEN 2000 AND 2020
ORDER BY 
    rm.production_year DESC, 
    ah.max_roles DESC NULLS LAST;
