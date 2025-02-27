
WITH RankedMovies AS (
    SELECT 
        title.id AS movie_id,
        title.title,
        title.production_year,
        COUNT(DISTINCT cast_info.person_id) AS cast_count,
        STRING_AGG(DISTINCT aka_name.name, ', ') AS cast_names,
        STRING_AGG(DISTINCT keyword.keyword, ', ') AS keywords
    FROM 
        title
    LEFT JOIN 
        movie_info ON title.id = movie_info.movie_id
    LEFT JOIN 
        cast_info ON title.id = cast_info.movie_id
    LEFT JOIN 
        aka_name ON cast_info.person_id = aka_name.person_id
    LEFT JOIN 
        movie_keyword ON title.id = movie_keyword.movie_id
    LEFT JOIN 
        keyword ON movie_keyword.keyword_id = keyword.id
    WHERE 
        title.production_year >= 2000 
        AND movie_info.info_type_id IN (
            SELECT id FROM info_type WHERE info = 'plot'
        )
    GROUP BY 
        title.id, title.title, title.production_year
    HAVING 
        COUNT(DISTINCT cast_info.person_id) > 5
), 
RankedMoviesWithIndex AS (
    SELECT 
        movie_id,
        title,
        production_year,
        cast_count,
        cast_names,
        keywords,
        ROW_NUMBER() OVER (ORDER BY production_year DESC, cast_count DESC) AS rank
    FROM 
        RankedMovies
)
SELECT 
    movie_id,
    title,
    production_year,
    cast_count,
    cast_names,
    keywords,
    rank
FROM 
    RankedMoviesWithIndex
WHERE 
    rank <= 10
ORDER BY 
    production_year DESC, 
    rank;
