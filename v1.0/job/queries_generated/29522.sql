WITH RankedMovies AS (
    SELECT 
        title.id AS movie_id,
        title.title,
        title.production_year,
        COUNT(DISTINCT cast_info.person_id) AS total_cast_count,
        STRING_AGG(DISTINCT aka_name.name, ', ') AS cast_names
    FROM 
        title
    LEFT JOIN 
        movie_companies ON title.id = movie_companies.movie_id
    LEFT JOIN 
        cast_info ON movie_companies.movie_id = cast_info.movie_id
    LEFT JOIN 
        aka_name ON cast_info.person_id = aka_name.person_id
    WHERE 
        title.production_year >= 2000
    GROUP BY 
        title.id
),
TopMovies AS (
    SELECT
        movie_id,
        title,
        production_year,
        total_cast_count,
        cast_names,
        RANK() OVER (ORDER BY total_cast_count DESC) AS movie_rank
    FROM 
        RankedMovies
)
SELECT 
    TM.movie_id,
    TM.title,
    TM.production_year,
    TM.total_cast_count,
    TM.cast_names,
    COUNT(DISTINCT movie_keyword.keyword_id) AS total_keywords,
    ARRAY_AGG(DISTINCT keyword.keyword) AS keywords
FROM 
    TopMovies TM
LEFT JOIN 
    movie_keyword ON TM.movie_id = movie_keyword.movie_id
LEFT JOIN 
    keyword ON movie_keyword.keyword_id = keyword.id
WHERE 
    TM.movie_rank <= 10
GROUP BY 
    TM.movie_id, TM.title, TM.production_year, TM.total_cast_count, TM.cast_names
ORDER BY 
    TM.total_cast_count DESC;

This query looks at movies produced from the year 2000 onwards, aggregates cast information with their names, and then ranks them based on the total number of distinct cast members. Finally, it retrieves the top 10 movies ranked by their cast size and also collects the associated keywords for those movies. The resulting output includes the movie ID, title, production year, total cast count, cast names, the total number of keywords, and a list of those keywords.
