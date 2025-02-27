WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS title_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
ActorCounts AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS actor_count
    FROM 
        cast_info ci
    JOIN 
        RankedMovies rm ON ci.movie_id = rm.movie_id
    GROUP BY 
        ci.movie_id
),
MovieInfo AS (
    SELECT 
        m.movie_id,
        m.info,
        it.info AS info_type
    FROM 
        movie_info m
    JOIN 
        info_type it ON m.info_type_id = it.id
),
CompanyContribution AS (
    SELECT 
        mc.movie_id,
        c.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
),
FinalReport AS (
    SELECT 
        rm.title,
        rm.production_year,
        ac.actor_count,
        STRING_AGG(DISTINCT cc.company_name, ', ') AS companies,
        STRING_AGG(DISTINCT mi.info, '; ') AS additional_info
    FROM 
        RankedMovies rm
    LEFT JOIN 
        ActorCounts ac ON rm.movie_id = ac.movie_id
    LEFT JOIN 
        CompanyContribution cc ON rm.movie_id = cc.movie_id
    LEFT JOIN 
        MovieInfo mi ON rm.movie_id = mi.movie_id
    GROUP BY 
        rm.movie_id, rm.title, rm.production_year, ac.actor_count
)
SELECT 
    f.title,
    f.production_year,
    COALESCE(f.actor_count, 0) AS total_actors,
    COALESCE(f.companies, 'No Companies') AS contributing_companies,
    COALESCE(f.additional_info, 'No Additional Info') AS additional_information
FROM 
    FinalReport f
WHERE 
    f.production_year >= 2000
    AND (f.actor_count IS NULL OR f.actor_count >= 5)
ORDER BY 
    f.production_year DESC, f.title;
