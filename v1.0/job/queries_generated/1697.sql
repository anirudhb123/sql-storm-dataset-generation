WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS year_rank
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
FilteredCompanies AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT c.id) AS company_count,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names
    FROM 
        movie_companies mc
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
MovieInfo AS (
    SELECT 
        mi.movie_id,
        STRING_AGG(DISTINCT mi.info, '; ') AS info_details
    FROM 
        movie_info mi
    GROUP BY 
        mi.movie_id
)
SELECT 
    m.movie_id,
    m.title,
    m.production_year,
    COALESCE(fc.company_count, 0) AS company_count,
    COALESCE(fc.company_names, 'No Companies') AS company_names,
    COALESCE(mk.keywords, 'No Keywords') AS keywords,
    COALESCE(mi.info_details, 'No Info') AS info_details
FROM 
    RankedMovies m
LEFT JOIN 
    FilteredCompanies fc ON m.movie_id = fc.movie_id
LEFT JOIN 
    MovieKeywords mk ON m.movie_id = mk.movie_id
LEFT JOIN 
    MovieInfo mi ON m.movie_id = mi.movie_id
WHERE 
    m.year_rank <= 5
ORDER BY 
    m.production_year DESC, 
    m.title ASC;
