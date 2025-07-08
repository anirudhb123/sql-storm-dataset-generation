
WITH RankedMovies AS (
    SELECT 
        title.title AS movie_title,
        aka_title.title AS aka_title,
        title.production_year,
        COUNT(DISTINCT cast_info.person_id) AS cast_count,
        LISTAGG(DISTINCT aka_name.name, ', ') WITHIN GROUP (ORDER BY aka_name.name) AS cast_names
    FROM 
        title
    JOIN 
        aka_title ON title.id = aka_title.movie_id
    JOIN 
        cast_info ON title.id = cast_info.movie_id
    JOIN 
        aka_name ON cast_info.person_id = aka_name.person_id
    GROUP BY 
        title.title, aka_title.title, title.production_year
),
TopMovies AS (
    SELECT 
        movie_title,
        aka_title,
        production_year,
        cast_count,
        cast_names,
        RANK() OVER (ORDER BY cast_count DESC) AS rank
    FROM 
        RankedMovies
)
SELECT 
    movie_title,
    aka_title,
    production_year,
    cast_count,
    cast_names
FROM 
    TopMovies
WHERE 
    rank <= 10
ORDER BY 
    production_year DESC, cast_count DESC;
