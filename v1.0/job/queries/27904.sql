WITH RankedMovies AS (
    SELECT 
        at.id AS movie_id,
        at.title,
        at.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count
    FROM 
        aka_title at
    JOIN 
        complete_cast cc ON at.id = cc.movie_id
    JOIN 
        cast_info ci ON cc.subject_id = ci.person_id
    WHERE 
        at.production_year IS NOT NULL
    GROUP BY 
        at.id, at.title, at.production_year
), 
KeywordStats AS (
    SELECT 
        mk.movie_id,
        COUNT(DISTINCT k.id) AS keyword_count
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
), 
MovieCompanyInfo AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT co.id) AS company_count,
        STRING_AGG(DISTINCT co.name, ', ') AS company_names
    FROM 
        movie_companies mc
    JOIN 
        company_name co ON mc.company_id = co.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    rm.movie_id,
    rm.title,
    rm.production_year,
    rm.cast_count,
    COALESCE(ks.keyword_count, 0) AS keyword_count,
    COALESCE(mci.company_count, 0) AS company_count,
    COALESCE(mci.company_names, 'N/A') AS company_names
FROM 
    RankedMovies rm
LEFT JOIN 
    KeywordStats ks ON rm.movie_id = ks.movie_id
LEFT JOIN 
    MovieCompanyInfo mci ON rm.movie_id = mci.movie_id
ORDER BY 
    rm.production_year DESC,
    rm.cast_count DESC,
    rm.title;
