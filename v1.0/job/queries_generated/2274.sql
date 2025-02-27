WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS rank_by_year
    FROM 
        aka_title t
    WHERE 
        t.production_year IS NOT NULL
),
MovieKeywords AS (
    SELECT 
        mk.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
),
MovieCompanies AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT c.id) AS company_count
    FROM 
        movie_companies mc
    JOIN 
        company_name c ON mc.company_id = c.id
    GROUP BY 
        mc.movie_id
),
CompleteCast AS (
    SELECT 
        cc.movie_id,
        COUNT(DISTINCT cc.subject_id) AS cast_count
    FROM 
        complete_cast cc
    GROUP BY 
        cc.movie_id
)

SELECT 
    r.movie_id,
    r.title,
    r.production_year,
    COALESCE(mk.keywords, 'No Keywords') AS keywords,
    COALESCE(mc.company_count, 0) AS company_count,
    COALESCE(cc.cast_count, 0) AS cast_count,
    CASE 
        WHEN r.rank_by_year < 5 THEN 'Top 5 Movies of ' || r.production_year 
        ELSE 'Other Movies of ' || r.production_year 
    END AS movie_category
FROM 
    RankedMovies r
LEFT JOIN 
    MovieKeywords mk ON r.movie_id = mk.movie_id
LEFT JOIN 
    MovieCompanies mc ON r.movie_id = mc.movie_id
LEFT JOIN 
    CompleteCast cc ON r.movie_id = cc.movie_id
WHERE 
    r.production_year IS NOT NULL
ORDER BY 
    r.production_year DESC, r.rank_by_year;
