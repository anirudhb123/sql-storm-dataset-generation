WITH RankedMovies AS (
    SELECT 
        t.title, 
        t.production_year,
        COUNT(c.person_role_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(c.person_role_id) DESC) AS year_rank
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
CompanyDetails AS (
    SELECT 
        mc.movie_id,
        GROUP_CONCAT(DISTINCT cn.name) AS companies,
        COUNT(DISTINCT cn.id) AS company_count
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
),
KeywordDetails AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(mk.keyword_id::text, ', ') AS keyword_ids
    FROM 
        movie_keyword mk
    GROUP BY 
        mk.movie_id
),
MovieInfo AS (
    SELECT 
        mi.movie_id,
        STRING_AGG(DISTINCT mi.info, '; ') AS info_summary
    FROM 
        movie_info mi
    WHERE 
        mi.info IS NOT NULL
    GROUP BY 
        mi.movie_id
)
SELECT 
    rm.title,
    rm.production_year,
    COALESCE(cd.companies, 'No Companies') AS companies,
    COALESCE(cd.company_count, 0) AS company_count,
    COALESCE(kd.keyword_ids, 'No Keywords') AS keywords,
    COALESCE(mi.info_summary, 'No Info') AS info_summary,
    rm.cast_count
FROM 
    RankedMovies rm
LEFT JOIN 
    CompanyDetails cd ON rm.title = cd.movie_id
LEFT JOIN 
    KeywordDetails kd ON rm.title = kd.movie_id
LEFT JOIN 
    MovieInfo mi ON rm.title = mi.movie_id
WHERE 
    (rm.year_rank <= 5 OR rm.production_year IS NULL)
ORDER BY 
    rm.production_year DESC, rm.cast_count DESC;
