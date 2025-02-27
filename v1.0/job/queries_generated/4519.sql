WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS rank
    FROM 
        aka_title t
    WHERE 
        t.production_year > 2000
),
CastDetails AS (
    SELECT 
        ci.movie_id,
        a.name AS actor_name,
        rt.role AS role_name,
        COUNT(ci.id) AS role_count
    FROM 
        cast_info ci
    JOIN 
        aka_name a ON ci.person_id = a.person_id
    JOIN 
        role_type rt ON ci.role_id = rt.id
    GROUP BY 
        ci.movie_id, a.name, rt.role
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        string_agg(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
MovieCompanies AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT c.name) AS company_count
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    GROUP BY 
        mc.movie_id
),
FinalResults AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        cd.actor_name,
        cd.role_name,
        cd.role_count,
        mk.keywords,
        mc.company_count
    FROM 
        RankedMovies rm
    LEFT JOIN 
        CastDetails cd ON rm.movie_id = cd.movie_id
    LEFT JOIN 
        MovieKeywords mk ON rm.movie_id = mk.movie_id
    LEFT JOIN 
        MovieCompanies mc ON rm.movie_id = mc.movie_id
)
SELECT 
    *,
    CASE 
        WHEN role_count IS NULL THEN 'No roles available'
        ELSE CONCAT('Total roles: ', role_count)
    END AS role_info
FROM 
    FinalResults
WHERE 
    (production_year IS NOT NULL AND production_year >= 2010)
ORDER BY 
    production_year DESC, title;
