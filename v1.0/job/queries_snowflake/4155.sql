
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS rank_year
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
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
FilteredMovies AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        ac.actor_count
    FROM 
        RankedMovies rm
    LEFT JOIN 
        ActorCounts ac ON rm.movie_id = ac.movie_id
    WHERE 
        rm.rank_year <= 5
),
CompanyInfo AS (
    SELECT 
        mc.movie_id,
        LISTAGG(DISTINCT cn.name, ', ') WITHIN GROUP (ORDER BY cn.name) AS companies_involved
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
),
FinalResults AS (
    SELECT 
        fm.title,
        fm.production_year,
        fm.actor_count,
        COALESCE(ci.companies_involved, 'No Companies') AS companies_involved
    FROM 
        FilteredMovies fm
    LEFT JOIN 
        CompanyInfo ci ON fm.movie_id = ci.movie_id
)
SELECT 
    fr.title,
    fr.production_year,
    fr.actor_count,
    fr.companies_involved,
    (CASE 
        WHEN fr.actor_count IS NULL THEN 'Unknown'
        WHEN fr.actor_count > 10 THEN 'Many Actors'
        ELSE 'Few Actors'
    END) AS actor_count_description
FROM 
    FinalResults fr
ORDER BY 
    fr.production_year DESC, fr.actor_count DESC
LIMIT 10;
