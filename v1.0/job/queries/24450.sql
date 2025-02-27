WITH RecursiveMovieCTE AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COALESCE(k.keyword, 'No Keyword') AS keyword,
        ROW_NUMBER() OVER (PARTITION BY m.id ORDER BY k.keyword) AS rank_of_keyword,
        COUNT(*) OVER (PARTITION BY m.id) AS keyword_count
    FROM 
        aka_title m
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
),
CompleteCastCTE AS (
    SELECT 
        cc.movie_id,
        COUNT(cc.id) AS total_cast,
        STRING_AGG(DISTINCT ca.name, ', ') AS cast_names,
        RANK() OVER (ORDER BY COUNT(cc.id) DESC) AS cast_rank
    FROM 
        complete_cast cc
    JOIN 
        cast_info ci ON cc.movie_id = ci.movie_id
    JOIN 
        aka_name ca ON ci.person_id = ca.person_id
    GROUP BY 
        cc.movie_id
),
MovieCompanyCTE AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT mc.company_id) AS total_companies,
        STRING_AGG(DISTINCT cn.name, ', ') AS company_names
    FROM 
        movie_companies mc
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
),
FinalResults AS (
    SELECT 
        r.movie_id,
        r.title,
        r.production_year,
        COALESCE(cc.total_cast, 0) AS total_cast,
        COALESCE(cc.cast_names, 'Unknown Cast') AS cast_names,
        COALESCE(mcc.total_companies, 0) AS total_companies,
        COALESCE(mcc.company_names, 'No Companies') AS company_names,
        COALESCE(r.keyword, 'No Keywords') AS movie_keyword,
        CASE 
            WHEN r.keyword_count > 1 THEN 'Multiple Keywords' 
            ELSE 'Single Keyword'
        END AS keyword_description
    FROM 
        RecursiveMovieCTE r
    LEFT JOIN 
        CompleteCastCTE cc ON r.movie_id = cc.movie_id
    LEFT JOIN 
        MovieCompanyCTE mcc ON r.movie_id = mcc.movie_id
    WHERE 
        (r.production_year IS NOT NULL AND r.production_year > 2000)
        AND (cc.total_cast IS NULL OR cc.total_cast > 5)
)

SELECT 
    *,
    CASE 
        WHEN total_cast = 0 THEN 'No Cast Available'
        WHEN total_companies = 0 THEN 'No Production Companies'
        ELSE 'Complete Data'
    END AS data_availability
FROM 
    FinalResults
WHERE 
    (keyword_description = 'Multiple Keywords' AND total_cast > 5)
    OR (total_companies = 0 AND production_year < 2010)
ORDER BY 
    production_year DESC, total_cast DESC;
