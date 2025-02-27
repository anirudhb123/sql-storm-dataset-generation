WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank_within_year
    FROM 
        aka_title t
    LEFT JOIN 
        cast_info c ON t.id = c.movie_id
    GROUP BY 
        t.id, t.title, t.production_year
),
KeywordsWithTitles AS (
    SELECT 
        mk.movie_id,
        k.keyword,
        t.title
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        aka_title t ON mk.movie_id = t.id
),
MovieCompanyStats AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT mc.company_id) AS company_count,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names
    FROM 
        movie_companies mc
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    rm.title,
    rm.production_year,
    rm.cast_count,
    mcs.company_count,
    mcs.company_names,
    kwt.keyword
FROM 
    RankedMovies rm
LEFT JOIN 
    MovieCompanyStats mcs ON rm.movie_id = mcs.movie_id
LEFT JOIN 
    KeywordsWithTitles kwt ON rm.movie_id = kwt.movie_id
WHERE 
    (rm.production_year IS NOT NULL AND rm.rank_within_year <= 5)
    OR (mcs.company_count > 0)
ORDER BY 
    rm.production_year DESC, 
    rm.cast_count DESC NULLS LAST;
