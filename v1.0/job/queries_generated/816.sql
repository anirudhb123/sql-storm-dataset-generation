WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.title) AS ranked_title
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
CastCount AS (
    SELECT 
        c.movie_id,
        COUNT(c.person_id) AS actor_count
    FROM 
        cast_info c
    GROUP BY 
        c.movie_id
),
MovieCompanyDetails AS (
    SELECT 
        m.movie_id,
        co.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies m
    JOIN 
        company_name co ON m.company_id = co.id
    JOIN 
        company_type ct ON m.company_type_id = ct.id
),
MovieInfo AS (
    SELECT 
        mi.movie_id,
        STRING_AGG(DISTINCT mi.info, '; ') AS info_details
    FROM 
        movie_info mi
    WHERE 
        mi.note IS NULL
    GROUP BY 
        mi.movie_id
),
FinalRanking AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        cc.actor_count,
        mcd.company_name,
        mcd.company_type,
        mi.info_details
    FROM 
        RankedMovies rm
    LEFT JOIN 
        CastCount cc ON rm.movie_id = cc.movie_id
    LEFT JOIN 
        MovieCompanyDetails mcd ON rm.movie_id = mcd.movie_id
    LEFT JOIN 
        MovieInfo mi ON rm.movie_id = mi.movie_id
)
SELECT 
    fr.*,
    CASE 
        WHEN fr.actor_count IS NULL THEN 'No Actors'
        ELSE CAST(fr.actor_count AS TEXT) || ' Actors' 
    END AS actor_info,
    COALESCE(fr.company_name, 'Independent') AS final_company,
    CASE 
        WHEN fr.production_year < 2000 THEN 'Classic'
        WHEN fr.production_year BETWEEN 2000 AND 2015 THEN 'Modern'
        ELSE 'Recent'
    END AS era
FROM 
    FinalRanking fr
WHERE 
    fr.ranked_title <= 10
ORDER BY 
    fr.production_year DESC, 
    fr.title;
