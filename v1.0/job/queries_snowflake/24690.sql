WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC, t.title) AS rank_within_year
    FROM 
        aka_title t
),
ActorMovieCounts AS (
    SELECT 
        c.person_id,
        COUNT(DISTINCT c.movie_id) AS movie_count
    FROM 
        cast_info c
    GROUP BY 
        c.person_id
),
ActorsWithMultipleRoles AS (
    SELECT 
        ci.person_id,
        COUNT(DISTINCT ci.role_id) AS roles_count
    FROM 
        cast_info ci
    GROUP BY 
        ci.person_id
    HAVING 
        COUNT(DISTINCT ci.role_id) > 1
),
CompanyProductionYears AS (
    SELECT 
        mc.movie_id,
        MAX(mt.production_year) AS latest_production_year
    FROM 
        movie_companies mc
    JOIN 
        aka_title mt ON mc.movie_id = mt.id
    GROUP BY 
        mc.movie_id
),
HighProfileActors AS (
    SELECT 
        a.id AS actor_id,
        a.name
    FROM 
        aka_name a
    JOIN 
        ActorMovieCounts amc ON a.person_id = amc.person_id
    WHERE 
        amc.movie_count > (SELECT AVG(movie_count) FROM ActorMovieCounts)
),
FullMovieDetails AS (
    SELECT 
        r.movie_id,
        r.title,
        r.production_year,
        cc.name AS company_name,
        hp.name AS actor_name,
        COALESCE(app.roles_count, 0) AS actor_roles_count
    FROM 
        RankedMovies r
    LEFT JOIN 
        movie_companies mc ON r.movie_id = mc.movie_id
    LEFT JOIN 
        company_name cc ON mc.company_id = cc.id
    LEFT JOIN 
        cast_info ci ON r.movie_id = ci.movie_id
    LEFT JOIN 
        HighProfileActors hp ON ci.person_id = hp.actor_id
    LEFT JOIN 
        ActorsWithMultipleRoles app ON ci.person_id = app.person_id
)

SELECT 
    fmd.movie_id,
    fmd.title,
    fmd.production_year,
    fmd.company_name,
    fmd.actor_name,
    fmd.actor_roles_count,
    CASE 
        WHEN fmd.actor_roles_count IS NULL THEN 'No Roles'
        WHEN fmd.actor_roles_count > 1 THEN 'Multiple Roles'
        ELSE 'Single Role'
    END AS role_summary
FROM 
    FullMovieDetails fmd
WHERE 
    fmd.production_year IS NOT NULL 
    AND fmd.company_name IS NOT NULL
ORDER BY 
    fmd.production_year DESC, 
    fmd.title ASC;
