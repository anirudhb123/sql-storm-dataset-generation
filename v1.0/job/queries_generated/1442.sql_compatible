
WITH RankedMovies AS (
    SELECT 
        title.id AS movie_id,
        title.title,
        title.production_year,
        RANK() OVER (PARTITION BY title.production_year ORDER BY COUNT(DISTINCT cast_info.person_id) DESC) AS rank_by_cast
    FROM 
        title
    JOIN 
        cast_info ON title.id = cast_info.movie_id
    GROUP BY 
        title.id, title.title, title.production_year
),
MovieKeywords AS (
    SELECT 
        movie_keyword.movie_id,
        STRING_AGG(keyword.keyword, ', ') AS keywords
    FROM 
        movie_keyword
    JOIN 
        keyword ON movie_keyword.keyword_id = keyword.id
    GROUP BY 
        movie_keyword.movie_id
),
MoviesWithRank AS (
    SELECT 
        RankedMovies.movie_id,
        RankedMovies.title,
        RankedMovies.production_year,
        RankedMovies.rank_by_cast,
        COALESCE(MovieKeywords.keywords, 'No Keywords') AS keywords
    FROM 
        RankedMovies
    LEFT JOIN 
        MovieKeywords ON RankedMovies.movie_id = MovieKeywords.movie_id
)
SELECT 
    MWR.movie_id,
    MWR.title,
    MWR.production_year,
    MWR.rank_by_cast,
    CASE 
        WHEN MWR.rank_by_cast <= 5 THEN 'Top 5'
        ELSE 'Others'
    END AS rank_category,
    CHAR_LENGTH(MWR.keywords) AS keyword_length,
    MWR.keywords
FROM 
    MoviesWithRank MWR
WHERE 
    MWR.production_year BETWEEN 2000 AND 2020
ORDER BY 
    MWR.rank_by_cast, MWR.production_year DESC;
