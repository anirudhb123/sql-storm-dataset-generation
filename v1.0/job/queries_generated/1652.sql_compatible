
WITH RecursiveMovieCTE AS (
    SELECT 
        mt.id AS movie_id,
        mt.title,
        mt.production_year,
        COUNT(DISTINCT ci.person_id) AS cast_count
    FROM 
        aka_title mt
    LEFT JOIN 
        complete_cast cc ON mt.id = cc.movie_id
    LEFT JOIN 
        cast_info ci ON ci.movie_id = cc.movie_id
    GROUP BY 
        mt.id, mt.title, mt.production_year
), 
MovieKeywordCTE AS (
    SELECT 
        mk.movie_id, 
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        mk.movie_id
), 
TitleCompanyCTE AS (
    SELECT 
        mt.id AS movie_id,
        STRING_AGG(DISTINCT cn.name, ', ') AS companies
    FROM 
        aka_title mt
    LEFT JOIN 
        movie_companies mc ON mt.id = mc.movie_id
    LEFT JOIN 
        company_name cn ON mc.company_id = cn.id
    GROUP BY 
        mt.id
)
SELECT 
    r.movie_id,
    r.title,
    r.production_year,
    r.cast_count,
    COALESCE(mk.keywords, 'No Keywords') AS keywords,
    COALESCE(tc.companies, 'No Companies') AS companies
FROM 
    RecursiveMovieCTE r
LEFT JOIN 
    MovieKeywordCTE mk ON r.movie_id = mk.movie_id
LEFT JOIN 
    TitleCompanyCTE tc ON r.movie_id = tc.movie_id
WHERE 
    r.production_year > 2000 
    AND r.cast_count > 5
ORDER BY 
    r.production_year DESC, 
    r.cast_count DESC;
