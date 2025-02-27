WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorInfo AS (
    SELECT 
        a.name AS actor_name,
        ci.movie_id,
        COUNT(ci.role_id) AS role_count
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    GROUP BY 
        a.name, ci.movie_id
),
MovieCompanyInfo AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT c.name) AS company_count,
        STRING_AGG(DISTINCT c.name, ', ') AS company_names
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    GROUP BY 
        mc.movie_id
),
JoinedData AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        ai.actor_name,
        ai.role_count,
        mc.company_count,
        mc.company_names
    FROM 
        RankedMovies rm
    LEFT JOIN 
        ActorInfo ai ON rm.movie_id = ai.movie_id
    LEFT JOIN 
        MovieCompanyInfo mc ON rm.movie_id = mc.movie_id
)
SELECT 
    jd.movie_id,
    jd.title,
    jd.production_year,
    COALESCE(jd.actor_name, 'No Actor') AS actor_name,
    COALESCE(jd.role_count, 0) AS role_count,
    COALESCE(jd.company_count, 0) AS company_count,
    COALESCE(jd.company_names, 'No Companies') AS company_names
FROM 
    JoinedData jd
WHERE 
    jd.role_count > 2 OR jd.company_count > 1
ORDER BY 
    jd.production_year DESC, jd.title;
