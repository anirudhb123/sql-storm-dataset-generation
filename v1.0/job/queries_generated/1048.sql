WITH RankedMovies AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        nt.name AS primary_actor,
        ROW_NUMBER() OVER (PARTITION BY mt.production_year ORDER BY mt.production_year DESC) AS rn
    FROM 
        aka_title mt
        JOIN cast_info ci ON mt.id = ci.movie_id
        JOIN aka_name nt ON ci.person_id = nt.person_id
    WHERE 
        ci.nr_order = 1
        AND nt.name IS NOT NULL
), 
CompanyMovies AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT mc.company_id) AS company_count,
        STRING_AGG(co.name, ', ') AS production_companies
    FROM 
        movie_companies mc
        JOIN company_name co ON mc.company_id = co.id
    GROUP BY 
        mc.movie_id
),
MovieInfo AS (
    SELECT 
        mi.movie_id,
        STRING_AGG(mi.info, '; ') AS additional_info
    FROM 
        movie_info mi
    WHERE 
        mi.info_type_id IN (SELECT id FROM info_type WHERE info = 'summary')
    GROUP BY 
        mi.movie_id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    rm.primary_actor,
    COALESCE(cm.company_count, 0) AS total_companies,
    COALESCE(cm.production_companies, 'N/A') AS companies,
    COALESCE(mi.additional_info, 'No summary available.') AS movie_summary
FROM 
    RankedMovies rm
LEFT JOIN 
    CompanyMovies cm ON rm.movie_id = cm.movie_id
LEFT JOIN 
    MovieInfo mi ON rm.movie_id = mi.movie_id
WHERE 
    rm.rn <= 10
ORDER BY 
    rm.production_year DESC;
