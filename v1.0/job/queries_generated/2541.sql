WITH RankedMovies AS (
    SELECT 
        a.title AS movie_title,
        a.production_year,
        ROW_NUMBER() OVER (PARTITION BY a.production_year ORDER BY a.title) AS rank_title,
        STRING_AGG(DISTINCT c.name, ', ') AS cast_names
    FROM 
        aka_title a
    LEFT JOIN 
        cast_info ci ON a.id = ci.movie_id
    LEFT JOIN 
        aka_name c ON ci.person_id = c.person_id
    GROUP BY 
        a.title, a.production_year
), CompanyStats AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT m.company_id) AS total_companies,
        MAX(ct.kind) AS main_company_type
    FROM 
        movie_companies mc
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    GROUP BY 
        mc.movie_id
), MovieInfo AS (
    SELECT 
        mi.movie_id,
        COUNT(DISTINCT mi.info_type_id) AS info_count,
        MAX(mi.info) AS latest_info
    FROM 
        movie_info mi
    GROUP BY 
        mi.movie_id
)
SELECT 
    rm.movie_title,
    rm.production_year,
    rm.cast_names,
    cs.total_companies,
    cs.main_company_type,
    mi.info_count,
    mi.latest_info
FROM 
    RankedMovies rm
LEFT JOIN 
    CompanyStats cs ON rm.producing_year = cs.movie_id
LEFT JOIN 
    MovieInfo mi ON rm.production_year = mi.movie_id
WHERE 
    (cs.total_companies > 0 OR mi.info_count > 5)
ORDER BY 
    rm.production_year DESC, 
    rm.rank_title
LIMIT 10;
