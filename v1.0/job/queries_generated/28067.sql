WITH RankedMovies AS (
    SELECT 
        title.id AS movie_id,
        title.title AS movie_title,
        title.production_year,
        COUNT(DISTINCT cast_info.person_id) AS total_cast,
        STRING_AGG(DISTINCT aka_name.name, ', ') AS cast_names
    FROM 
        title
    JOIN 
        cast_info ON title.id = cast_info.movie_id
    JOIN 
        aka_name ON cast_info.person_id = aka_name.person_id
    WHERE 
        title.production_year BETWEEN 2000 AND 2023
    GROUP BY 
        title.id, title.title, title.production_year
),
KeywordMovies AS (
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
FinalRanking AS (
    SELECT 
        rm.movie_id,
        rm.movie_title,
        rm.production_year,
        rm.total_cast,
        rm.cast_names,
        km.keywords
    FROM 
        RankedMovies rm
    LEFT JOIN 
        KeywordMovies km ON rm.movie_id = km.movie_id
    ORDER BY 
        rm.production_year DESC, rm.total_cast DESC
)
SELECT 
    FR.movie_title,
    FR.production_year,
    FR.total_cast,
    FR.cast_names,
    COALESCE(FR.keywords, 'No Keywords') AS keywords
FROM 
    FinalRanking FR
LIMIT 20;
