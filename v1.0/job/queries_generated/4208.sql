WITH RankedMovies AS (
    SELECT 
        at.title,
        at.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY at.production_year ORDER BY COUNT(ci.person_id) DESC) AS rank
    FROM 
        aka_title at
    JOIN 
        cast_info ci ON at.id = ci.movie_id
    WHERE 
        at.production_year IS NOT NULL
    GROUP BY 
        at.id, at.title, at.production_year
),
CompanyMovieCounts AS (
    SELECT 
        mc.movie_id,
        COUNT(DISTINCT cn.name) AS company_count
    FROM 
        movie_companies mc
    JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mc.movie_id
),
TitleKeywordCounts AS (
    SELECT 
        mk.movie_id,
        COUNT(DISTINCT k.keyword) AS keyword_count
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
)
SELECT 
    rm.title,
    rm.production_year,
    rm.cast_count,
    COALESCE(cmc.company_count, 0) AS company_count,
    COALESCE(tkc.keyword_count, 0) AS keyword_count
FROM 
    RankedMovies rm
LEFT JOIN 
    CompanyMovieCounts cmc ON rm.title = (SELECT title FROM aka_title WHERE id = cmc.movie_id LIMIT 1)
LEFT JOIN 
    TitleKeywordCounts tkc ON rm.title = (SELECT title FROM aka_title WHERE id = tkc.movie_id LIMIT 1)
WHERE 
    rm.rank <= 3
ORDER BY 
    rm.production_year DESC, rm.cast_count DESC;
