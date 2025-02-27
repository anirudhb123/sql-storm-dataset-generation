WITH RankedMovies AS (
    SELECT 
        a.title,
        at.production_year,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY a.title) AS rankByTitle,
        COUNT(DISTINCT mc.company_id) OVER (PARTITION BY at.production_year) AS productionCompanies
    FROM 
        aka_title at
    JOIN 
        title a ON at.movie_id = a.id
    LEFT JOIN 
        movie_companies mc ON a.id = mc.movie_id
    WHERE 
        at.kind_id = (SELECT id FROM kind_type WHERE kind = 'feature') -- Only feature films
),
DistinctKeywords AS (
    SELECT 
        title_id,
        STRING_AGG(keyword.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword ON mk.keyword_id = keyword.id
    GROUP BY 
        title_id
)
SELECT 
    rm.production_year,
    rm.title,
    rm.rankByTitle,
    COALESCE(dk.keywords, 'No Keywords') AS keywords,
    CASE 
        WHEN rm.productionCompanies > 0 THEN 'Produced'
        ELSE 'No Productions'
    END AS production_status
FROM 
    RankedMovies rm
LEFT JOIN 
    DistinctKeywords dk ON rm.id = dk.title_id
WHERE 
    rm.rankByTitle <= 5
ORDER BY 
    rm.production_year DESC, 
    rm.rankByTitle;
