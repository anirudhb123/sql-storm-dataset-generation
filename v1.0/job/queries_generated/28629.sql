WITH RankedMovies AS (
    SELECT 
        title.title AS movie_title,
        aka_title.production_year,
        COUNT(DISTINCT cast_info.person_id) AS cast_count,
        STRING_AGG(DISTINCT aka_name.name, ', ') AS cast_names,
        STRING_AGG(DISTINCT keyword.keyword, ', ') AS keywords,
        ROW_NUMBER() OVER (PARTITION BY aka_title.production_year ORDER BY COUNT(DISTINCT cast_info.person_id) DESC) AS rank
    FROM 
        aka_title
    JOIN 
        title ON aka_title.id = title.id
    JOIN 
        cast_info ON aka_title.movie_id = cast_info.movie_id
    JOIN 
        aka_name ON cast_info.person_id = aka_name.person_id
    LEFT JOIN 
        movie_keyword ON aka_title.movie_id = movie_keyword.movie_id
    LEFT JOIN 
        keyword ON movie_keyword.keyword_id = keyword.id
    GROUP BY 
        title.title, aka_title.production_year
),

TopMovies AS (
    SELECT 
        movie_title,
        production_year,
        cast_count,
        cast_names,
        keywords
    FROM 
        RankedMovies
    WHERE 
        rank <= 5
)

SELECT 
    tm.movie_title,
    tm.production_year,
    tm.cast_count,
    tm.cast_names,
    tm.keywords,
    COALESCE(mi.info, 'No Additional Info') AS movie_info
FROM 
    TopMovies tm
LEFT JOIN 
    movie_info mi ON tm.movie_title = mi.info
ORDER BY 
    tm.production_year DESC, 
    tm.cast_count DESC;
