WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        ROW_NUMBER() OVER (PARTITION BY m.production_year ORDER BY m.title) AS title_rank
    FROM 
        aka_title m
    WHERE 
        m.production_year IS NOT NULL
),
ActorCounts AS (
    SELECT 
        c.movie_id,
        COUNT(c.person_id) AS actor_count
    FROM 
        cast_info c
    GROUP BY 
        c.movie_id
),
MoviesWithMostActors AS (
    SELECT 
        ac.movie_id
    FROM 
        ActorCounts ac
    ORDER BY 
        ac.actor_count DESC
    LIMIT 5
),
CompanyMovies AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT mc.company_id) AS companies_count
    FROM 
        movie_companies mc
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
),
TopCompanies AS (
    SELECT 
        cm.movie_id,
        cm.companies_count,
        RANK() OVER (ORDER BY cm.companies_count DESC) AS company_rank
    FROM 
        CompanyMovies cm
    WHERE 
        cm.companies_count IS NOT NULL
),
FinalSelection AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        ta.actor_count,
        tc.companies_count,
        COALESCE(tc.companies_count, 0) AS companies_count_fallback
    FROM 
        RankedMovies rm
    JOIN 
        ActorCounts ta ON rm.movie_id = ta.movie_id
    LEFT JOIN 
        TopCompanies tc ON rm.movie_id = tc.movie_id
    WHERE 
        rm.title_rank = 1 AND -- select the first title alphabetically in each production year
        rm.movie_id IN (SELECT movie_id FROM MoviesWithMostActors)
)

SELECT 
    fs.movie_id,
    fs.title,
    fs.production_year,
    fs.actor_count,
    fs.companies_count,
    CASE 
        WHEN fs.companies_count_fallback > 5 THEN 'Many Companies'
        WHEN fs.companies_count_fallback IS NULL THEN 'No Companies'
        ELSE 'Few Companies'
    END AS company_status
FROM 
    FinalSelection fs
WHERE 
    fs.actor_count > 0
ORDER BY 
    fs.production_year DESC, fs.title ASC;

