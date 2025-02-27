WITH RankedMovies AS (
    SELECT 
        title.title,
        title.production_year,
        COUNT(DISTINCT cast_info.person_id) AS cast_count,
        STRING_AGG(DISTINCT aka_name.name, ', ') AS actors,
        ROW_NUMBER() OVER (PARTITION BY title.production_year ORDER BY COUNT(DISTINCT cast_info.person_id) DESC) AS rank
    FROM 
        title
    JOIN 
        movie_info ON title.id = movie_info.movie_id
    JOIN 
        movie_keyword ON title.id = movie_keyword.movie_id
    JOIN 
        keyword ON movie_keyword.keyword_id = keyword.id
    JOIN 
        movie_companies ON title.id = movie_companies.movie_id
    JOIN 
        cast_info ON title.id = cast_info.movie_id
    JOIN 
        aka_name ON cast_info.person_id = aka_name.person_id
    WHERE 
        movie_info.info_type_id = (SELECT id FROM info_type WHERE info = 'duration') AND
        title.production_year BETWEEN 2000 AND 2020
    GROUP BY 
        title.id, title.title, title.production_year
),
TopActors AS (
    SELECT 
        aka_name.name,
        COUNT(DISTINCT title.id) AS movies_count
    FROM 
        aka_name
    JOIN 
        cast_info ON aka_name.person_id = cast_info.person_id
    JOIN 
        title ON cast_info.movie_id = title.id
    WHERE 
        title.production_year BETWEEN 2000 AND 2020
    GROUP BY 
        aka_name.name
    ORDER BY 
        movies_count DESC
    LIMIT 5
)
SELECT 
    RankedMovies.title,
    RankedMovies.production_year,
    RankedMovies.cast_count,
    RankedMovies.actors,
    TopActors.name AS top_actor,
    TopActors.movies_count
FROM 
    RankedMovies
JOIN 
    TopActors ON RankedMovies.actors LIKE '%' || TopActors.name || '%'
WHERE 
    RankedMovies.rank <= 5
ORDER BY 
    RankedMovies.production_year DESC, 
    RankedMovies.cast_count DESC;
