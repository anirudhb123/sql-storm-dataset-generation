
WITH RankedMovies AS (
    SELECT 
        t.id AS title_id,
        t.title,
        t.production_year,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY t.production_year DESC) AS rank_per_year
    FROM 
        title t
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
CompanyAggregates AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT mc.company_id) AS company_count,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
)
SELECT 
    rm.title,
    rm.production_year,
    CASE 
        WHEN rm.rank_per_year <= 3 THEN 'Top 3'
        ELSE 'Other'
    END AS rank_category,
    mk.keywords,
    ca.company_count,
    ca.company_names
FROM 
    RankedMovies rm
LEFT JOIN 
    MovieKeywords mk ON rm.title_id = mk.movie_id
LEFT JOIN 
    CompanyAggregates ca ON rm.title_id = ca.movie_id
WHERE 
    (rm.production_year >= 2000 AND rm.production_year <= 2020)
    AND (mk.keywords IS NOT NULL OR ca.company_count > 0)
ORDER BY 
    rm.production_year DESC, 
    rm.rank_per_year;
