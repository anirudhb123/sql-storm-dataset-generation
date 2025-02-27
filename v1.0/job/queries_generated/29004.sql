WITH RankedMovies AS (
    SELECT 
        t.title AS movie_title,
        t.production_year,
        COUNT(ca.person_id) AS cast_count,
        ARRAY_AGG(DISTINCT ak.name) AS known_actors,
        ROW_NUMBER() OVER (PARTITION BY t.production_year ORDER BY COUNT(ca.person_id) DESC) AS rank
    FROM 
        aka_title t
    JOIN 
        cast_info ca ON t.id = ca.movie_id
    JOIN 
        aka_name ak ON ca.person_id = ak.person_id
    GROUP BY 
        t.id, t.title, t.production_year
),
KeywordMovies AS (
    SELECT 
        m.movie_id,
        STRING_AGG(k.keyword, ', ') AS keywords
    FROM 
        movie_keyword mk
    JOIN 
        keyword k ON mk.keyword_id = k.id
    JOIN 
        movie_info m ON mk.movie_id = m.movie_id
    GROUP BY 
        m.movie_id
),
CompleteMovieInfo AS (
    SELECT 
        rm.movie_title,
        rm.production_year,
        rm.cast_count,
        rm.known_actors,
        km.keywords
    FROM 
        RankedMovies rm
    LEFT JOIN 
        KeywordMovies km ON rm.movie_title = km.movie_id
)
SELECT 
    movie_title,
    production_year,
    cast_count,
    known_actors,
    keywords
FROM 
    CompleteMovieInfo
WHERE 
    rank <= 5
ORDER BY 
    production_year DESC, cast_count DESC;

This SQL query achieves the following:

1. **RankedMovies** CTE: This Common Table Expression ranks movies by the number of cast members in each production year. It aggregates the names of known actors for each movie.

2. **KeywordMovies** CTE: It aggregates keywords related to each movie.

3. **CompleteMovieInfo** CTE: Combines the results of the first two CTEs to provide a complete view of movie titles, their production years, cast counts, known actors, and associated keywords.

4. The final SELECT retrieves the top 5 ranked movies (by cast count) for each production year. It orders the results by production year and cast count. 

This query demonstrates the capability of string processing, data aggregation, and ranking within a movie database schema.
