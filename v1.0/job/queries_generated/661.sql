WITH RankedMovies AS (
    SELECT 
        title.title AS movie_title,
        title.production_year,
        COUNT(DISTINCT cast_info.person_id) AS cast_count,
        ROW_NUMBER() OVER (PARTITION BY title.production_year ORDER BY COUNT(DISTINCT cast_info.person_id) DESC) AS rank
    FROM 
        title
    LEFT JOIN 
        cast_info ON title.id = cast_info.movie_id
    GROUP BY 
        title.id, title.title, title.production_year
),
HighCastMovies AS (
    SELECT 
        movie_title,
        production_year
    FROM 
        RankedMovies
    WHERE 
        rank <= 5
),
KeywordCount AS (
    SELECT 
        movie_id,
        COUNT(keyword_id) AS keyword_count
    FROM 
        movie_keyword
    GROUP BY 
        movie_id
),
MovieWithKeywords AS (
    SELECT 
        title.title,
        title.production_year,
        COALESCE(KeywordCount.keyword_count, 0) AS keyword_count
    FROM 
        title
    LEFT JOIN 
        KeywordCount ON title.id = KeywordCount.movie_id
    WHERE 
        title.production_year >= 2000
)
SELECT 
    HCM.movie_title,
    HCM.production_year,
    M.title AS keyword_movie,
    M.keyword_count
FROM 
    HighCastMovies HCM
FULL OUTER JOIN 
    MovieWithKeywords M ON HCM.production_year = M.production_year
WHERE 
    (HCM.movie_title IS NOT NULL OR M.title IS NOT NULL)
ORDER BY 
    HCM.production_year DESC, HCM.movie_title ASC;
