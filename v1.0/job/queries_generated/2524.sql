WITH RankedMovies AS (
    SELECT 
        at.title,
        at.production_year,
        COUNT(ci.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY COUNT(ci.person_id) DESC) AS rank
    FROM 
        aka_title at
    LEFT JOIN 
        cast_info ci ON at.movie_id = ci.movie_id
    GROUP BY 
        at.title, at.production_year
),
CompanyInfo AS (
    SELECT 
        mc.movie_id,
        cn.name AS company_name,
        ct.kind AS company_type
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
),
MovieDetails AS (
    SELECT 
        title.title,
        title.production_year,
        COALESCE(STRING_AGG(DISTINCT ki.keyword, ', '), 'No Keywords') AS keywords,
        COALESCE(SUM(mi.info IS NOT NULL)::int, 0) AS info_count
    FROM 
        title
    LEFT JOIN 
        movie_keyword mk ON title.id = mk.movie_id
    LEFT JOIN 
        keyword ki ON mk.keyword_id = ki.id
    LEFT JOIN 
        movie_info mi ON title.id = mi.movie_id
    GROUP BY 
        title.title, title.production_year
)
SELECT 
    rm.title,
    rm.production_year,
    rm.cast_count,
    ci.company_name,
    ci.company_type,
    md.keywords,
    md.info_count
FROM 
    RankedMovies rm
LEFT JOIN 
    CompanyInfo ci ON rm.title = ci.movie_id
LEFT JOIN 
    MovieDetails md ON rm.title = md.title AND rm.production_year = md.production_year
WHERE 
    rm.rank <= 5 AND 
    (ci.company_type IS NULL OR ci.company_type != 'Production Company')
ORDER BY 
    rm.production_year DESC, rm.cast_count DESC;
