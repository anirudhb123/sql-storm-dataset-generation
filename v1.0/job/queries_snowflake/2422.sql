WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS rank_by_year 
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorRoles AS (
    SELECT 
        c.movie_id,
        a.name AS actor_name,
        r.role AS role_name,
        COUNT(*) OVER (PARTITION BY c.movie_id, a.name) AS role_count
    FROM 
        cast_info c
    JOIN 
        aka_name a ON c.person_id = a.person_id
    JOIN 
        role_type r ON c.role_id = r.id
    WHERE 
        c.note IS NULL
),
CompanyMovieCounts AS (
    SELECT 
        mc.movie_id,
        comp.name AS company_name,
        COUNT(*) AS company_movie_count
    FROM 
        movie_companies mc
    JOIN 
        company_name comp ON mc.company_id = comp.id
    GROUP BY 
        mc.movie_id, comp.name
),
MoviesWithKeyword AS (
    SELECT 
        mk.movie_id,
        k.keyword
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    WHERE 
        k.keyword IS NOT NULL
)
SELECT 
    rm.movie_id,
    rm.title,
    COALESCE(ar.actor_name, 'No Actor') AS main_actor,
    COALESCE(ar.role_name, 'N/A') AS role,
    COALESCE(cc.company_name, 'Independent') AS production_company,
    COUNT(DISTINCT kw.keyword) AS keyword_count,
    MAX(rm.rank_by_year) AS highest_rank
FROM 
    RankedMovies rm
LEFT JOIN 
    ActorRoles ar ON rm.movie_id = ar.movie_id
LEFT JOIN 
    CompanyMovieCounts cc ON rm.movie_id = cc.movie_id
LEFT JOIN 
    MoviesWithKeyword kw ON rm.movie_id = kw.movie_id
GROUP BY 
    rm.movie_id, rm.title, ar.actor_name, ar.role_name, cc.company_name
HAVING 
    COUNT(DISTINCT kw.keyword) > 2
ORDER BY 
    highest_rank DESC, rm.title ASC
LIMIT 50;
