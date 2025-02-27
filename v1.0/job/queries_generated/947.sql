WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        RANK() OVER (PARTITION BY t.production_year ORDER BY t.id DESC) AS rank_per_year
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
), 
ActorRoleCounts AS (
    SELECT 
        ci.person_id,
        COUNT(DISTINCT ci.movie_id) AS movie_count,
        STRING_AGG(DISTINCT r.role ORDER BY r.role) AS roles
    FROM 
        cast_info ci
    JOIN 
        role_type r ON ci.role_id = r.id
    GROUP BY 
        ci.person_id
), 
CompanyMovieCounts AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT mc.company_id) AS company_count
    FROM 
        movie_companies mc
    GROUP BY 
        mc.movie_id
), 
TitleWithCompanyCount AS (
    SELECT 
        t.id AS title_id,
        t.title,
        COALESCE(cmc.company_count, 0) AS company_count
    FROM 
        aka_title t
    LEFT JOIN 
        CompanyMovieCounts cmc ON t.id = cmc.movie_id
)

SELECT 
    am.name AS actor_name,
    rm.title AS movie_title,
    rm.production_year,
    ar.movie_count AS actor_movie_count,
    tc.company_count,
    ar.roles,
    CASE 
        WHEN rm.rank_per_year <= 5 THEN 'Top 5'
        ELSE 'Not Top 5'
    END AS rank_status
FROM 
    RankedMovies rm
JOIN 
    ActorRoleCounts ar ON rm.movie_id IN (SELECT movie_id FROM cast_info WHERE person_id = ar.person_id)
JOIN 
    aka_name am ON am.person_id = ar.person_id
JOIN 
    TitleWithCompanyCount tc ON tc.title_id = rm.movie_id
WHERE 
    rm.production_year >= 2000 AND
    (tc.company_count IS NULL OR tc.company_count > 3)
ORDER BY 
    rm.production_year DESC, 
    ar.movie_count DESC;
