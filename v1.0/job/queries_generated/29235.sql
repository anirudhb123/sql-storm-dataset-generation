WITH RankedMovies AS (
    SELECT 
        title.id AS movie_id,
        title.title AS movie_title,
        title.production_year,
        count(DISTINCT movie_keyword.keyword_id) AS keyword_count,
        ROW_NUMBER() OVER (PARTITION BY title.production_year ORDER BY count(DISTINCT movie_keyword.keyword_id) DESC) AS rank
    FROM 
        title 
    LEFT JOIN 
        movie_keyword ON title.id = movie_keyword.movie_id
    GROUP BY 
        title.id, title.title, title.production_year
),
TopMovies AS (
    SELECT 
        movie_id, 
        movie_title, 
        production_year
    FROM 
        RankedMovies
    WHERE 
        rank <= 5
),
ActorsInTopMovies AS (
    SELECT 
        aka_name.name AS actor_name,
        aka_title.title,
        aka_title.production_year
    FROM 
        TopMovies 
    INNER JOIN 
        complete_cast ON TopMovies.movie_id = complete_cast.movie_id
    INNER JOIN 
        cast_info ON complete_cast.subject_id = cast_info.id
    INNER JOIN 
        aka_name ON cast_info.person_id = aka_name.person_id
    INNER JOIN 
        aka_title ON TopMovies.movie_id = aka_title.movie_id
    WHERE 
        aka_title.kind_id = (SELECT id FROM kind_type WHERE kind = 'movie')
)
SELECT 
    production_year, 
    STRING_AGG(DISTINCT actor_name, ', ') AS actors
FROM 
    ActorsInTopMovies
GROUP BY 
    production_year
ORDER BY 
    production_year DESC;
