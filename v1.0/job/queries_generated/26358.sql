WITH RankedMovies AS (
    SELECT 
        title.title AS movie_title,
        title.production_year,
        COUNT(DISTINCT cast_info.person_id) AS cast_count,
        STRING_AGG(aka_name.name, ', ') AS cast_members,
        RANK() OVER (PARTITION BY title.production_year ORDER BY COUNT(DISTINCT cast_info.person_id) DESC) AS rank_in_year
    FROM 
        title
    JOIN 
        cast_info ON title.id = cast_info.movie_id
    JOIN 
        aka_name ON cast_info.person_id = aka_name.person_id
    WHERE 
        title.production_year IS NOT NULL
        AND aka_name.name IS NOT NULL
    GROUP BY 
        title.id, title.title, title.production_year
),

TopMovies AS (
    SELECT 
        movie_title,
        production_year,
        cast_count,
        cast_members
    FROM 
        RankedMovies
    WHERE 
        rank_in_year <= 5
)

SELECT 
    tm.production_year,
    STRING_AGG(tm.movie_title, ', ') AS top_movies,
    SUM(tm.cast_count) AS total_cast_members,
    COUNT(DISTINCT mk.keyword) AS unique_keywords,
    STRING_AGG(mk.keyword, ', ') AS associated_keywords
FROM 
    TopMovies tm
LEFT JOIN 
    movie_keyword mk ON tm.movie_title = (
        SELECT title FROM title WHERE title.id = (
            SELECT movie_id FROM movie_info WHERE info = tm.movie_title LIMIT 1
        )
    )
GROUP BY 
    tm.production_year
ORDER BY 
    tm.production_year DESC;
