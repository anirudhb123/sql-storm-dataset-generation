
WITH RankedMovies AS (
    SELECT 
        title.id AS movie_id,
        title.title,
        title.production_year,
        COUNT(DISTINCT cast_info.person_id) AS total_cast,
        STRING_AGG(DISTINCT aka_name.name, ', ') AS cast_names
    FROM 
        title
    JOIN 
        aka_title ON title.id = aka_title.movie_id
    JOIN 
        cast_info ON aka_title.movie_id = cast_info.movie_id
    JOIN 
        aka_name ON cast_info.person_id = aka_name.person_id
    GROUP BY 
        title.id, title.title, title.production_year
    ORDER BY 
        total_cast DESC
    LIMIT 10
),
MovieKeywords AS (
    SELECT 
        movie_id,
        STRING_AGG(keyword.keyword, ', ') AS keywords
    FROM 
        movie_keyword
    JOIN 
        keyword ON movie_keyword.keyword_id = keyword.id
    GROUP BY 
        movie_id
),
MovieInfo AS (
    SELECT 
        movie_id,
        STRING_AGG(movie_info.info, '; ') AS info_details
    FROM 
        movie_info
    GROUP BY 
        movie_id
)
SELECT 
    RankedMovies.movie_id,
    RankedMovies.title,
    RankedMovies.production_year,
    RankedMovies.total_cast,
    RankedMovies.cast_names,
    COALESCE(MovieKeywords.keywords, 'No keywords') AS keywords,
    COALESCE(MovieInfo.info_details, 'No details available') AS info_details
FROM 
    RankedMovies
LEFT JOIN 
    MovieKeywords ON RankedMovies.movie_id = MovieKeywords.movie_id
LEFT JOIN 
    MovieInfo ON RankedMovies.movie_id = MovieInfo.movie_id;
