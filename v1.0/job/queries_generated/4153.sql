WITH RankedMovies AS (
    SELECT 
        a.title, 
        a.production_year, 
        COALESCE(AVG(c.nm_order), 0) AS avg_order,
        RANK() OVER (PARTITION BY a.production_year ORDER BY COALESCE(AVG(c.nr_order), 0) DESC) AS rank_per_year
    FROM 
        aka_title a
    LEFT JOIN 
        complete_cast cc ON a.id = cc.movie_id
    LEFT JOIN 
        cast_info c ON cc.subject_id = c.person_id
    GROUP BY 
        a.id
), MovieKeywords AS (
    SELECT 
        mk.movie_id, 
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
), MovieCompanies AS (
    SELECT 
        mc.movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
), MovieInfo AS (
    SELECT 
        mi.movie_id,
        STRING_AGG(DISTINCT mi.info, '; ') AS info_details
    FROM 
        movie_info mi
    GROUP BY 
        mi.movie_id
)
SELECT 
    rm.title, 
    rm.production_year, 
    rm.avg_order, 
    rm.rank_per_year,
    mk.keywords,
    mc.companies,
    mi.info_details
FROM 
    RankedMovies rm
LEFT JOIN 
    MovieKeywords mk ON rm.id = mk.movie_id
LEFT JOIN 
    MovieCompanies mc ON rm.id = mc.movie_id
LEFT JOIN 
    MovieInfo mi ON rm.id = mi.movie_id
WHERE 
    rm.rank_per_year <= 5
ORDER BY 
    rm.production_year DESC, 
    rm.avg_order DESC;
