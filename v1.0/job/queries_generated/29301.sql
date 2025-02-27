WITH RankedMovies AS (
    SELECT 
        t.id AS movie_id,
        t.title,
        t.production_year,
        COUNT(DISTINCT c.person_id) AS cast_count,
        STRING_AGG(DISTINCT a.name, ', ') AS actor_names,
        STRING_AGG(DISTINCT kw.keyword, ', ') AS movie_keywords
    FROM 
        aka_title t
    JOIN 
        cast_info c ON t.id = c.movie_id
    JOIN 
        aka_name a ON c.person_id = a.person_id
    LEFT JOIN 
        movie_keyword mk ON t.id = mk.movie_id
    LEFT JOIN 
        keyword kw ON mk.keyword_id = kw.id
    WHERE 
        t.production_year BETWEEN 2000 AND 2023
    GROUP BY 
        t.id
),
MovieDetails AS (
    SELECT 
        rm.movie_id,
        rm.title,
        rm.production_year,
        rm.cast_count,
        rm.actor_names,
        AVG(mi.info::numeric) AS avg_rating
    FROM 
        RankedMovies rm
    LEFT JOIN 
        movie_info mi ON rm.movie_id = mi.movie_id AND mi.info_type_id = (SELECT id FROM info_type WHERE info = 'rating')
    GROUP BY 
        rm.movie_id
)

SELECT 
    md.movie_id,
    md.title,
    md.production_year,
    md.cast_count,
    md.actor_names,
    md.avg_rating
FROM 
    MovieDetails md
WHERE 
    md.avg_rating IS NOT NULL
ORDER BY 
    md.avg_rating DESC, 
    md.cast_count DESC
LIMIT 10;

This SQL query benchmarks string processing by focusing on movies from the years 2000 to 2023. It computes the number of unique actors in each movie, collects their names into a concatenated string, and also gathers keywords associated with each movie. It further computes the average rating of these movies and sorts the results by rating and cast count. The query uses Common Table Expressions (CTEs) to organize its structure and calculations, making it more readable and efficient.
