WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        ARRAY_AGG(DISTINCT ak.name) AS known_actors,
        ROW_NUMBER() OVER (ORDER BY COUNT(DISTINCT c.person_id) DESC) AS rank
    FROM 
        title m
    JOIN 
        cast_info c ON m.id = c.movie_id
    JOIN 
        aka_name ak ON c.person_id = ak.person_id
    WHERE 
        m.production_year BETWEEN 2000 AND 2023
    GROUP BY 
        m.id, m.title, m.production_year
),
MoviesWithKeywords AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.cast_count,
        rm.known_actors,
        k.keyword AS movie_keyword
    FROM 
        RankedMovies rm
    LEFT JOIN 
        movie_keyword mk ON rm.movie_id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
),
FilteredMovies AS (
    SELECT 
        *,
        COUNT(movie_keyword) OVER (PARTITION BY movie_id) AS keyword_count
    FROM 
        MoviesWithKeywords
)

SELECT 
    f.movie_id,
    f.title,
    f.production_year,
    f.cast_count,
    f.keyword_count,
    f.known_actors
FROM 
    FilteredMovies f
WHERE 
    f.keyword_count > 0
ORDER BY 
    f.production_year DESC, f.cast_count DESC
LIMIT 10;

This SQL query involves multiple Common Table Expressions (CTEs) to benchmark string processing focused on movies released between 2000 and 2023. It counts distinct actors, aggregates the names of known actors, and retrieves associated keywords, while filtering results to only include movies that have keywords. It ranks the movies based on the number of actors and sorts the final output by the production year and number of actors, thereby providing a well-structured result set for analysis.
