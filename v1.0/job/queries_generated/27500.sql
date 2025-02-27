WITH RankedMovies AS (
    SELECT 
        title.title AS movie_title,
        title.production_year,
        COUNT(DISTINCT cast.person_id) AS cast_count,
        STRING_AGG(DISTINCT aka.name, ', ') AS actor_names
    FROM 
        title
    JOIN 
        aka_title AS aka_title ON title.id = aka_title.movie_id
    JOIN 
        cast_info AS cast ON cast.movie_id = aka_title.movie_id
    JOIN 
        aka_name AS aka ON cast.person_id = aka.person_id
    WHERE 
        title.production_year >= 2000
    GROUP BY 
        title.id
),
TopMovies AS (
    SELECT 
        movie_title,
        production_year,
        cast_count,
        actor_names,
        RANK() OVER (ORDER BY cast_count DESC) AS rank
    FROM 
        RankedMovies
)
SELECT 
    movie_title,
    production_year,
    cast_count,
    actor_names
FROM 
    TopMovies
WHERE 
    rank <= 10
ORDER BY 
    production_year DESC, cast_count DESC;

This query performs the following functions:

1. It gathers movie titles, their respective production years, and the number of distinct actors (cast members) from the `title`, `aka_title`, `cast_info`, and `aka_name` tables.
2. It filters for movies produced since the year 2000.
3. It ranks the movies based on the number of cast members, limiting the output to the top 10 movies.
4. Finally, it orders the results by production year (most recent first) and by the number of cast members (in descending order).
