WITH RankedMovies AS (
    SELECT 
        m.id AS movie_id,
        m.title,
        m.production_year,
        COUNT(c.person_id) AS actor_count,
        STRING_AGG(DISTINCT a.name, ', ') AS cast_names,
        STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
    FROM 
        aka_title m
    LEFT JOIN 
        cast_info c ON m.id = c.movie_id
    LEFT JOIN 
        aka_name a ON c.person_id = a.person_id
    LEFT JOIN 
        movie_keyword mk ON m.id = mk.movie_id
    LEFT JOIN 
        keyword k ON mk.keyword_id = k.id
    GROUP BY 
        m.id
),
MoviesByYear AS (
    SELECT 
        production_year,
        AVG(actor_count) AS avg_actor_count,
        ARRAY_AGG(DISTINCT movie_id) AS movie_ids
    FROM 
        RankedMovies
    GROUP BY 
        production_year
)
SELECT 
    year.production_year,
    year.avg_actor_count,
    ARRAY_LENGTH(year.movie_ids, 1) AS number_of_movies,
    STRING_AGG(DISTINCT r.title ORDER BY r.title) AS movie_titles
FROM 
    MoviesByYear year
JOIN 
    RankedMovies r ON r.movie_id = ANY(year.movie_ids)
GROUP BY 
    year.production_year, year.avg_actor_count
ORDER BY 
    year.production_year DESC;
