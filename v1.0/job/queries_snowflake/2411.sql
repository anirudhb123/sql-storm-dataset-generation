
WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.id) AS rn
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
), 
TopActors AS (
    SELECT 
        ci.movie_id,
        COUNT(DISTINCT ci.person_id) AS actor_count
    FROM 
        cast_info ci
    GROUP BY 
        ci.movie_id
), 
MovieInfo AS (
    SELECT 
        mi.movie_id,
        LISTAGG(DISTINCT it.info, '; ') WITHIN GROUP (ORDER BY it.info) AS info_details
    FROM 
        movie_info mi
    INNER JOIN 
        info_type it ON mi.info_type_id = it.id
    GROUP BY 
        mi.movie_id
), 
CompanyContribution AS (
    SELECT 
        mc.movie_id,
        LISTAGG(DISTINCT cn.name, ', ') WITHIN GROUP (ORDER BY cn.name) AS companies
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    COALESCE(ac.actor_count, 0) AS actor_count,
    COALESCE(mi.info_details, 'No Info') AS info_details,
    COALESCE(cc.companies, 'No Companies') AS companies,
    CASE 
        WHEN rm.rn <= 10 THEN 'Top 10 Movies of Year'
        ELSE 'Other Movies'
    END AS movie_category
FROM 
    RankedMovies rm
LEFT JOIN 
    TopActors ac ON rm.movie_id = ac.movie_id
LEFT JOIN 
    MovieInfo mi ON rm.movie_id = mi.movie_id
LEFT JOIN 
    CompanyContribution cc ON rm.movie_id = cc.movie_id
ORDER BY 
    rm.production_year DESC, rm.title ASC;
