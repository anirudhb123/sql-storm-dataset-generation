
WITH RankedMovies AS (
    SELECT 
        title.id AS movie_id,
        title.title AS movie_title,
        title.production_year,
        COUNT(DISTINCT cast_info.person_id) AS total_cast,
        LISTAGG(DISTINCT aka_name.name, ', ') AS cast_names,
        LISTAGG(DISTINCT keyword.keyword, ', ') AS keywords,
        ROW_NUMBER() OVER (PARTITION BY title.production_year ORDER BY COUNT(DISTINCT cast_info.person_id) DESC) AS rank
    FROM 
        title
    JOIN 
        movie_companies ON title.id = movie_companies.movie_id
    JOIN 
        cast_info ON title.id = cast_info.movie_id
    JOIN 
        aka_name ON cast_info.person_id = aka_name.person_id
    JOIN 
        movie_keyword ON title.id = movie_keyword.movie_id
    JOIN 
        keyword ON movie_keyword.keyword_id = keyword.id
    GROUP BY 
        title.id, title.title, title.production_year
),
TopMovies AS (
    SELECT 
        movie_id,
        movie_title,
        production_year,
        total_cast,
        cast_names
    FROM 
        RankedMovies
    WHERE 
        rank <= 5
)
SELECT 
    tm.movie_title,
    tm.production_year,
    tm.total_cast,
    tm.cast_names,
    COALESCE(mvi.info, 'No additional info') AS movie_info
FROM 
    TopMovies tm
LEFT JOIN 
    movie_info mvi ON tm.movie_id = mvi.movie_id AND mvi.info_type_id = (SELECT id FROM info_type WHERE info = 'Box Office')
ORDER BY 
    tm.production_year DESC, 
    tm.total_cast DESC;
