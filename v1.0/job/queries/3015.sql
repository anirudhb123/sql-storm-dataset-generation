
WITH RankedMovies AS (
    SELECT 
        at.title,
        at.production_year,
        COUNT(ci.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY COUNT(ci.person_id) DESC) AS rn
    FROM 
        aka_title at
    LEFT JOIN 
        cast_info ci ON at.id = ci.movie_id
    GROUP BY 
        at.id, at.title, at.production_year
), 
HighestCastMovies AS (
    SELECT 
        title,
        production_year
    FROM 
        RankedMovies
    WHERE 
        rn = 1
), 
MovieCompanyInfo AS (
    SELECT 
        at.title,
        cn.name AS company_name,
        ct.kind AS company_type,
        at.production_year
    FROM 
        aka_title at
    JOIN 
        movie_companies mc ON at.id = mc.movie_id
    JOIN 
        company_name cn ON mc.company_id = cn.id
    JOIN 
        company_type ct ON mc.company_type_id = ct.id
    WHERE 
        at.production_year IS NOT NULL
),
MoviesWithKeywords AS (
    SELECT 
        at.title,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        aka_title at
    LEFT JOIN 
        movie_keyword mk ON at.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        at.id, at.title
)
SELECT 
    hcm.title,
    hcm.production_year,
    mci.company_name,
    mci.company_type,
    COALESCE(mwk.keywords, 'No keywords') AS keywords
FROM 
    HighestCastMovies hcm
LEFT JOIN 
    MovieCompanyInfo mci ON hcm.title = mci.title AND hcm.production_year = mci.production_year
LEFT JOIN 
    MoviesWithKeywords mwk ON hcm.title = mwk.title
WHERE 
    (mci.company_type IS NOT NULL OR mwk.keywords IS NOT NULL)
ORDER BY 
    hcm.production_year DESC, hcm.title;
